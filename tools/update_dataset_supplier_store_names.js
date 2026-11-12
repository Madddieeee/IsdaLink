'use strict';

const fs = require('fs');
const path = require('path');
const {parse} = require('csv-parse/sync');
const {initializeApp, applicationDefault} = require('firebase-admin/app');
const {FieldValue, getFirestore} = require('firebase-admin/firestore');

const COMMIT = process.argv.includes('--commit');
const CONFIRM = process.argv.includes('--confirm=UPDATE-DATASET-STORES');
const PROJECT_ID = process.env.GOOGLE_CLOUD_PROJECT || process.env.GCLOUD_PROJECT;
const CSV_PATH = path.join(
  __dirname,
  'dataset',
  'IsdaLink_Stakeholder_Profile_THROUGH_20261108_FINAL_DEEP_RECHECKED_READY.csv',
);
const MAP_PATH = path.join(__dirname, 'historical_id_map.json');
const REPORT_PATH = path.join(
  __dirname,
  `update_dataset_supplier_stores_${new Date().toISOString().replace(/[:.]/g, '-')}.json`,
);

const SNAPSHOT_COLLECTIONS = [
  'fishStocks',
  'orders',
  'reviews',
  'favoriteSuppliers',
];
const STORE_NAME_FIELDS = ['supplierName', 'storeName', 'businessName'];

if (!PROJECT_ID) {
  throw new Error('Set GOOGLE_CLOUD_PROJECT before running this script.');
}

initializeApp({
  credential: applicationDefault(),
  projectId: PROJECT_ID,
});

const db = getFirestore();

function text(value) {
  return String(value ?? '').trim();
}

function lower(value) {
  return text(value).toLowerCase();
}

function currentStoreName(data) {
  for (const field of STORE_NAME_FIELDS) {
    const value = text(data[field]);
    if (value) return value;
  }
  return '';
}

function snapshotNameUpdate(data, intendedName) {
  const update = {};
  for (const field of STORE_NAME_FIELDS) {
    if (Object.prototype.hasOwnProperty.call(data, field)) {
      update[field] = intendedName;
    }
  }
  return update;
}

async function main() {
  const mapping = JSON.parse(fs.readFileSync(MAP_PATH, 'utf8'));
  const rows = parse(fs.readFileSync(CSV_PATH, 'utf8'), {
    columns: true,
    bom: true,
    skip_empty_lines: true,
    trim: true,
    record_delimiter: ['\r\n', '\n'],
  });
  const supplierRows = rows.filter((row) =>
    text(row.participant_id).startsWith('SUP-'),
  );

  if (supplierRows.length !== 3) {
    throw new Error(
      `Safety stop: expected 3 supplier rows, found ${supplierRows.length}.`,
    );
  }

  const changes = [];
  for (const row of supplierRows) {
    const participantId = text(row.participant_id);
    const uid = text(mapping.suppliers?.[participantId]);
    const intendedName = text(row.business_operation_name);

    if (!uid || !intendedName) {
      throw new Error(`Safety stop: incomplete store mapping for ${participantId}.`);
    }
    if (lower(row.participant_role) !== 'fish supplier') {
      throw new Error(`Safety stop: role mismatch for ${participantId}.`);
    }
    if (lower(row.consent_obtained) !== 'true') {
      throw new Error(`Safety stop: consent is not TRUE for ${participantId}.`);
    }
    if (lower(row.validation_status) !== 'validated') {
      throw new Error(`Safety stop: ${participantId} is not Validated.`);
    }

    const profileReference = db.collection('supplierProfiles').doc(uid);
    const profileSnapshot = await profileReference.get();
    if (!profileSnapshot.exists) {
      throw new Error(`Safety stop: supplierProfiles/${uid} does not exist.`);
    }

    const relatedDocuments = [];
    for (const collectionName of SNAPSHOT_COLLECTIONS) {
      const snapshot = await db
        .collection(collectionName)
        .where('supplierId', '==', uid)
        .get();
      for (const document of snapshot.docs) {
        const data = document.data();
        const update = snapshotNameUpdate(data, intendedName);
        if (Object.keys(update).length > 0) {
          relatedDocuments.push({path: document.ref.path, update});
        }
      }
    }

    changes.push({
      participantId,
      uid,
      currentStoreName: currentStoreName(profileSnapshot.data() || {}) || null,
      intendedStoreName: intendedName,
      relatedDocuments,
    });
  }

  const report = {
    generatedAt: new Date().toISOString(),
    projectId: PROJECT_ID,
    mode: COMMIT ? 'commit' : 'dry-run',
    sourceCsv: path.basename(CSV_PATH),
    supplierCount: changes.length,
    changes,
  };
  fs.writeFileSync(REPORT_PATH, `${JSON.stringify(report, null, 2)}\n`);

  console.log('IsdaLink dataset supplier store-name alignment');
  console.log('----------------------------------------------');
  console.log(`Firebase project: ${PROJECT_ID}`);
  console.log(`Validated supplier stores: ${changes.length}`);
  console.log(
    `Related current documents: ${changes.reduce(
      (total, change) => total + change.relatedDocuments.length,
      0,
    )}`,
  );
  console.log(`Audit report: ${REPORT_PATH}`);
  console.log('');
  for (const change of changes) {
    console.log(
      `${change.participantId} | ${change.currentStoreName || 'no current store'} ` +
      `-> ${change.intendedStoreName} | related: ${change.relatedDocuments.length}`,
    );
  }

  if (!COMMIT) {
    console.log('');
    console.log('DRY RUN ONLY. No Firebase data was changed.');
    console.log(
      'Review the list, then rerun with ' +
      '--commit --confirm=UPDATE-DATASET-STORES.',
    );
    return;
  }

  if (!CONFIRM) {
    throw new Error(
      'Safety stop: --commit requires --confirm=UPDATE-DATASET-STORES.',
    );
  }

  for (const change of changes) {
    const batch = db.batch();
    batch.set(
      db.collection('supplierProfiles').doc(change.uid),
      {
        supplierName: change.intendedStoreName,
        storeName: change.intendedStoreName,
        businessName: change.intendedStoreName,
        stakeholderStoreNameAlignedAt: FieldValue.serverTimestamp(),
      },
      {merge: true},
    );

    batch.set(
      db.collection('users').doc(change.uid),
      {
        supplierName: change.intendedStoreName,
        storeName: change.intendedStoreName,
        businessName: change.intendedStoreName,
        stakeholderStoreNameAlignedAt: FieldValue.serverTimestamp(),
      },
      {merge: true},
    );

    for (const related of change.relatedDocuments) {
      batch.update(db.doc(related.path), related.update);
    }
    await batch.commit();
    console.log(`UPDATED: ${change.participantId} -> ${change.intendedStoreName}`);
  }

  console.log('');
  console.log('STORE-NAME ALIGNMENT COMPLETE. Owner names were preserved.');
}

main().catch((error) => {
  console.error(error?.stack || error);
  process.exitCode = 1;
});
