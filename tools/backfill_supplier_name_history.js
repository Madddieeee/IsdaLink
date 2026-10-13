'use strict';

const {initializeApp, applicationDefault} = require('firebase-admin/app');
const {getFirestore, FieldValue} = require('firebase-admin/firestore');

const commit = process.argv.includes('--commit');
const projectId = process.env.GCLOUD_PROJECT || process.env.GOOGLE_CLOUD_PROJECT;

initializeApp({
  credential: applicationDefault(),
  ...(projectId ? {projectId} : {}),
});

const db = getFirestore();

function text(value) {
  return String(value ?? '').trim();
}

async function main() {
  const requests = await db
      .collection('supplierChangeRequests')
      .where('status', '==', 'approved')
      .get();

  const candidates = [];

  for (const requestDocument of requests.docs) {
    const request = requestDocument.data();
    const changedFields = Array.isArray(request.changedFields) ? request.changedFields : [];
    if (!changedFields.includes('Store name')) {
      continue;
    }

    const supplierId = text(request.supplierId || requestDocument.id);
    const previousName = text(request.supplierName);
    if (!supplierId || !previousName) {
      continue;
    }

    const profileReference = db.collection('supplierProfiles').doc(supplierId);
    const profileSnapshot = await profileReference.get();
    if (!profileSnapshot.exists) {
      continue;
    }

    const profile = profileSnapshot.data() || {};
    const currentName = text(profile.supplierName || profile.storeName || profile.businessName);
    const existing = Array.isArray(profile.previousStoreNames)
      ? profile.previousStoreNames.map(text).filter(Boolean)
      : [];
    const existingHistory = Array.isArray(profile.storeNameHistory)
      ? profile.storeNameHistory.filter((entry) => entry && typeof entry === 'object')
      : [];

    if (!currentName || previousName.toLowerCase() === currentName.toLowerCase()) {
      continue;
    }

    const names = [...existing.filter(
        (name) => name.toLowerCase() !== previousName.toLowerCase(),
    ), previousName].slice(-10);
    const changeDate = request.reviewedAt || request.updatedAt || request.createdAt || null;
    const historyHasName = existingHistory.some(
        (entry) => text(entry.name).toLowerCase() === previousName.toLowerCase(),
    );
    const history = historyHasName
      ? existingHistory
      : [...existingHistory, {
        name: previousName,
        ...(changeDate ? {changedAt: changeDate} : {}),
      }].slice(-10);

    if (JSON.stringify(names) === JSON.stringify(existing) && historyHasName) {
      continue;
    }

    candidates.push({
      supplierId,
      currentName,
      previousName,
      names,
      history,
      profileReference,
    });
  }

  for (const candidate of candidates) {
    console.log(
        `${commit ? 'UPDATE' : 'DRY RUN'}: ${candidate.supplierId}: ` +
        `${candidate.previousName} -> ${candidate.currentName}`,
    );

    if (commit) {
      await candidate.profileReference.update({
        previousStoreNames: candidate.names,
        storeNameHistory: candidate.history,
        nameHistoryBackfilledAt: FieldValue.serverTimestamp(),
      });
    }
  }

  console.log(
      `${commit ? 'Updated' : 'Found'} ${candidates.length} supplier profile(s).`,
  );
  if (!commit && candidates.length > 0) {
    console.log('Run again with --commit to apply these reviewed changes.');
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
