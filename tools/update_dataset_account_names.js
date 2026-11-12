'use strict';

const fs = require('fs');
const path = require('path');
const {parse} = require('csv-parse/sync');
const {initializeApp, applicationDefault} = require('firebase-admin/app');
const {getAuth} = require('firebase-admin/auth');
const {FieldValue, getFirestore} = require('firebase-admin/firestore');

const COMMIT = process.argv.includes('--commit');
const CONFIRM = process.argv.includes('--confirm=UPDATE-DATASET-NAMES');
const PROJECT_ID = process.env.GOOGLE_CLOUD_PROJECT || process.env.GCLOUD_PROJECT;
const CSV_PATH = path.join(
  __dirname,
  'dataset',
  'IsdaLink_Stakeholder_Profile_THROUGH_20261108_FINAL_DEEP_RECHECKED_READY.csv',
);
const MAP_PATH = path.join(__dirname, 'historical_id_map.json');
const REPORT_PATH = path.join(
  __dirname,
  `update_dataset_account_names_${new Date().toISOString().replace(/[:.]/g, '-')}.json`,
);

if (!PROJECT_ID) {
  throw new Error('Set GOOGLE_CLOUD_PROJECT before running this script.');
}

initializeApp({
  credential: applicationDefault(),
  projectId: PROJECT_ID,
});

const auth = getAuth();
const db = getFirestore();

function text(value) {
  return String(value ?? '').trim();
}

function lower(value) {
  return text(value).toLowerCase();
}

function mappedUid(mapping, participantId) {
  if (participantId.startsWith('VND-')) {
    return text(mapping.vendors?.[participantId]);
  }
  if (participantId.startsWith('SUP-')) {
    return text(mapping.suppliers?.[participantId]);
  }
  return '';
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

  if (rows.length !== 8) {
    throw new Error(`Safety stop: expected 8 stakeholder rows, found ${rows.length}.`);
  }

  const seenUids = new Set();
  const changes = [];

  for (const row of rows) {
    const participantId = text(row.participant_id);
    const fullName = text(row.full_name);
    const role = lower(row.participant_role);
    const uid = mappedUid(mapping, participantId);

    if (!participantId || !fullName || !uid) {
      throw new Error(`Safety stop: incomplete mapping for ${participantId || 'unknown row'}.`);
    }
    if (lower(row.consent_obtained) !== 'true') {
      throw new Error(`Safety stop: consent is not TRUE for ${participantId}.`);
    }
    if (lower(row.validation_status) !== 'validated') {
      throw new Error(`Safety stop: ${participantId} is not Validated.`);
    }
    if (seenUids.has(uid)) {
      throw new Error(`Safety stop: Firebase UID ${uid} is mapped more than once.`);
    }
    seenUids.add(uid);

    const isSupplier = participantId.startsWith('SUP-') && role === 'fish supplier';
    const isVendor = participantId.startsWith('VND-') && role === 'fish vendor';
    if (!isSupplier && !isVendor) {
      throw new Error(`Safety stop: role mismatch for ${participantId}.`);
    }

    const [authUser, userDocument, supplierDocument] = await Promise.all([
      auth.getUser(uid),
      db.collection('users').doc(uid).get(),
      isSupplier ? db.collection('supplierProfiles').doc(uid).get() : null,
    ]);

    if (!userDocument.exists) {
      throw new Error(`Safety stop: users/${uid} does not exist for ${participantId}.`);
    }
    if (isSupplier && !supplierDocument.exists) {
      throw new Error(
        `Safety stop: supplierProfiles/${uid} does not exist for ${participantId}.`,
      );
    }

    const userData = userDocument.data() || {};
    const supplierData = supplierDocument?.data() || {};
    changes.push({
      participantId,
      uid,
      accountType: isSupplier ? 'supplier' : 'vendor',
      intendedName: fullName,
      current: {
        authDisplayName: text(authUser.displayName) || null,
        userName: text(userData.name) || null,
        userFullName: text(userData.fullName) || null,
        userDisplayName: text(userData.displayName) || null,
        supplierOwnerName: isSupplier
          ? text(supplierData.ownerName) || null
          : null,
      },
    });
  }

  const report = {
    generatedAt: new Date().toISOString(),
    projectId: PROJECT_ID,
    mode: COMMIT ? 'commit' : 'dry-run',
    sourceCsv: path.basename(CSV_PATH),
    accountCount: changes.length,
    changes,
  };
  fs.writeFileSync(REPORT_PATH, `${JSON.stringify(report, null, 2)}\n`);

  console.log('IsdaLink dataset account name alignment');
  console.log('---------------------------------------');
  console.log(`Firebase project: ${PROJECT_ID}`);
  console.log(`Validated stakeholder accounts: ${changes.length}`);
  console.log(`Audit report: ${REPORT_PATH}`);
  console.log('');
  for (const change of changes) {
    console.log(
      `${change.participantId} | ${change.accountType} | ` +
      `${change.current.authDisplayName || 'no current name'} -> ${change.intendedName}`,
    );
  }

  if (!COMMIT) {
    console.log('');
    console.log('DRY RUN ONLY. No Firebase data was changed.');
    console.log(
      'Review the list, then rerun with ' +
      '--commit --confirm=UPDATE-DATASET-NAMES.',
    );
    return;
  }

  if (!CONFIRM) {
    throw new Error(
      'Safety stop: --commit requires --confirm=UPDATE-DATASET-NAMES.',
    );
  }

  for (const change of changes) {
    await auth.updateUser(change.uid, {displayName: change.intendedName});
    await db.collection('users').doc(change.uid).set(
      {
        name: change.intendedName,
        fullName: change.intendedName,
        displayName: change.intendedName,
        stakeholderParticipantId: change.participantId,
        stakeholderNameAlignedAt: FieldValue.serverTimestamp(),
      },
      {merge: true},
    );

    if (change.accountType === 'supplier') {
      await db.collection('supplierProfiles').doc(change.uid).set(
        {
          ownerName: change.intendedName,
          stakeholderParticipantId: change.participantId,
          stakeholderNameAlignedAt: FieldValue.serverTimestamp(),
        },
        {merge: true},
      );
    }

    console.log(`UPDATED: ${change.participantId} -> ${change.intendedName}`);
  }

  console.log('');
  console.log('NAME ALIGNMENT COMPLETE. No new accounts were created.');
}

main().catch((error) => {
  console.error(error?.stack || error);
  process.exitCode = 1;
});
