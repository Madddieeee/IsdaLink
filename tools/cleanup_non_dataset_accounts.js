'use strict';

const fs = require('fs');
const path = require('path');
const {initializeApp, applicationDefault} = require('firebase-admin/app');
const {getAuth} = require('firebase-admin/auth');
const {getFirestore} = require('firebase-admin/firestore');

const COMMIT = process.argv.includes('--commit');
const CONFIRM = process.argv.includes('--confirm=DELETE-NON-DATASET-ACCOUNTS');
const PROJECT_ID = process.env.GOOGLE_CLOUD_PROJECT || process.env.GCLOUD_PROJECT;
const MAP_PATH = path.join(__dirname, 'historical_id_map.json');
const REPORT_PATH = path.join(
  __dirname,
  `cleanup_non_dataset_accounts_${new Date().toISOString().replace(/[:.]/g, '-')}.json`,
);

const IDENTITY_FIELDS = new Set([
  'uid',
  'userId',
  'vendorId',
  'supplierId',
  'buyerId',
  'ownerId',
  'customerId',
  'reviewerId',
  'createdBy',
  'recipientId',
  'senderId',
  'applicantId',
]);

const PROTECTED_COLLECTIONS = new Set([
  'historicalTransactions',
  'historicalImports',
]);

if (!PROJECT_ID) {
  throw new Error(
    'Set GOOGLE_CLOUD_PROJECT before running this script.',
  );
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

function serializable(value) {
  if (value === null || value === undefined) return value;
  if (Array.isArray(value)) return value.map(serializable);
  if (typeof value !== 'object') return value;
  if (typeof value.toDate === 'function') return value.toDate().toISOString();
  if (Buffer.isBuffer(value)) return value.toString('base64');
  return Object.fromEntries(
    Object.entries(value).map(([key, item]) => [key, serializable(item)]),
  );
}

function referencesTarget(value, targets, key = '') {
  if (value === null || value === undefined) return false;
  if (Array.isArray(value)) {
    return value.some((item) => referencesTarget(item, targets, key));
  }
  if (typeof value === 'object') {
    return Object.entries(value).some(([childKey, childValue]) =>
      referencesTarget(childValue, targets, childKey),
    );
  }
  return IDENTITY_FIELDS.has(key) && targets.has(text(value));
}

async function listAllAuthUsers() {
  const users = [];
  let pageToken;
  do {
    const page = await auth.listUsers(1000, pageToken);
    users.push(...page.users);
    pageToken = page.pageToken;
  } while (pageToken);
  return users;
}

function isAdmin(authUser, firestoreUser) {
  const role = text(firestoreUser?.role).toLowerCase();
  const claims = authUser?.customClaims || {};
  return role === 'admin' || claims.admin === true ||
    text(claims.role).toLowerCase() === 'admin';
}

async function main() {
  const idMap = JSON.parse(fs.readFileSync(MAP_PATH, 'utf8'));
  const datasetUids = new Set([
    ...Object.values(idMap.vendors || {}),
    ...Object.values(idMap.suppliers || {}),
  ].map(text).filter(Boolean));

  if (datasetUids.size !== 8) {
    throw new Error(
      `Safety stop: expected 8 dataset UIDs, found ${datasetUids.size}.`,
    );
  }

  const [authUsers, usersSnapshot] = await Promise.all([
    listAllAuthUsers(),
    db.collection('users').get(),
  ]);
  const authByUid = new Map(authUsers.map((user) => [user.uid, user]));
  const firestoreUsers = new Map(
    usersSnapshot.docs.map((doc) => [doc.id, doc.data()]),
  );
  const allUids = new Set([...authByUid.keys(), ...firestoreUsers.keys()]);
  const adminUids = new Set(
    [...allUids].filter((uid) =>
      isAdmin(authByUid.get(uid), firestoreUsers.get(uid)),
    ),
  );

  if (adminUids.size === 0) {
    throw new Error(
      'Safety stop: no admin account was positively identified. Nothing changed.',
    );
  }

  const keepUids = new Set([...datasetUids, ...adminUids]);
  const targetUids = new Set(
    [...allUids].filter((uid) => !keepUids.has(uid)),
  );

  const matchedDocuments = [];
  const collections = await db.listCollections();
  for (const collection of collections) {
    if (PROTECTED_COLLECTIONS.has(collection.id)) continue;
    const snapshot = await collection.get();
    for (const doc of snapshot.docs) {
      const data = doc.data();
      if (targetUids.has(doc.id) || referencesTarget(data, targetUids)) {
        matchedDocuments.push({
          path: doc.ref.path,
          data: serializable(data),
        });
      }
    }
  }

  const targetAccounts = [...targetUids].sort().map((uid) => {
    const authUser = authByUid.get(uid);
    const firestoreUser = firestoreUsers.get(uid) || {};
    return {
      uid,
      email: authUser?.email || text(firestoreUser.email) || null,
      displayName: authUser?.displayName || text(firestoreUser.name) || null,
      role: text(firestoreUser.role) || null,
      accountType: text(firestoreUser.accountType) || null,
      inAuthentication: Boolean(authUser),
      inFirestoreUsers: firestoreUsers.has(uid),
    };
  });

  const report = {
    generatedAt: new Date().toISOString(),
    projectId: PROJECT_ID,
    mode: COMMIT ? 'commit' : 'dry-run',
    preservedDatasetUids: [...datasetUids].sort(),
    preservedAdminUids: [...adminUids].sort(),
    targetAccounts,
    matchedDocuments,
    protectedCollections: [...PROTECTED_COLLECTIONS],
  };
  fs.writeFileSync(REPORT_PATH, `${JSON.stringify(report, null, 2)}\n`);

  console.log('IsdaLink non-dataset account cleanup');
  console.log('------------------------------------');
  console.log(`Firebase project: ${PROJECT_ID}`);
  console.log(`Dataset accounts preserved: ${datasetUids.size}`);
  console.log(`Admin accounts preserved: ${adminUids.size}`);
  console.log(`Accounts targeted: ${targetAccounts.length}`);
  console.log(`Related documents targeted: ${matchedDocuments.length}`);
  console.log(`Audit report: ${REPORT_PATH}`);
  console.log('');
  for (const account of targetAccounts) {
    console.log(
      `TARGET: ${account.uid} | ${account.email || 'no email'} | ` +
      `${account.role || account.accountType || 'unknown role'}`,
    );
  }

  if (!COMMIT) {
    console.log('');
    console.log('DRY RUN ONLY. No Firebase data was changed.');
    console.log(
      'Review the JSON report, then rerun with ' +
      '--commit --confirm=DELETE-NON-DATASET-ACCOUNTS.',
    );
    return;
  }

  if (!CONFIRM) {
    throw new Error(
      'Safety stop: --commit requires ' +
      '--confirm=DELETE-NON-DATASET-ACCOUNTS.',
    );
  }

  for (const item of matchedDocuments) {
    await db.recursiveDelete(db.doc(item.path));
    console.log(`DELETED DOCUMENT: ${item.path}`);
  }

  for (const account of targetAccounts) {
    if (account.inAuthentication) {
      await auth.deleteUser(account.uid);
      console.log(`DELETED AUTH USER: ${account.uid}`);
    }
  }

  console.log('');
  console.log('CLEANUP COMPLETE. Dataset and admin accounts were preserved.');
}

main().catch((error) => {
  console.error(error?.stack || error);
  process.exitCode = 1;
});
