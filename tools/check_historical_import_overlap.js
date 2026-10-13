'use strict';

// Read-only preflight for IsdaLink historical transaction re-imports.
// Run from the project root using: node tools/check_historical_import_overlap.js <csv path>
// Uses the same firebase-admin and csv-parse dependencies as the existing importer.

const fs = require('node:fs');
const path = require('node:path');
const { parse } = require('csv-parse/sync');
const { applicationDefault, initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

async function main() {
  const csvArg = process.argv[2];
  if (!csvArg || process.argv.length !== 3) {
    throw new Error('Usage: node tools/check_historical_import_overlap.js <CSV-file>');
  }
  const csvPath = path.resolve(csvArg);
  const rows = parse(fs.readFileSync(csvPath, 'utf8'), {
    columns: true,
    skip_empty_lines: true,
    bom: true,
    relax_column_count: false,
    trim: false,
  });
  const clean = (value) => String(value ?? '').trim();
  const eligible = rows.filter((r) =>
    clean(r.order_status ?? r.status).toLowerCase() === 'completed' &&
    clean(r.validation_status).toLowerCase() === 'validated'
  );
  const ids = eligible.map((r) => clean(r.transaction_id));
  const sourceIds = new Set(ids);
  if (sourceIds.size !== ids.length || ids.some((id) => !id || id.includes('/'))) {
    throw new Error('CSV has blank, duplicate, or invalid eligible transaction IDs. STOP.');
  }

  initializeApp({
    credential: applicationDefault(),
    projectId: 'isdalink-b6744',
  });
  const db = getFirestore();
  const existingSnapshot = await db.collection('historicalTransactions').select().get();
  const existingIds = new Set(existingSnapshot.docs.map((doc) => doc.id));
  const matches = [...existingIds].filter((id) => sourceIds.has(id));
  const oldNotInNew = [...existingIds].filter((id) => !sourceIds.has(id));
  const newIds = [...sourceIds].filter((id) => !existingIds.has(id));

  console.log('IsdaLink historical import overlap — READ ONLY');
  console.log('Firebase project: isdalink-b6744');
  console.log(`CSV eligible transaction IDs: ${sourceIds.size}`);
  console.log(`Existing Firestore historicalTransactions IDs: ${existingIds.size}`);
  console.log(`Matching IDs (would be overwritten): ${matches.length}`);
  console.log(`New IDs (would be created): ${newIds.length}`);
  console.log(`Existing IDs absent from new CSV (would remain): ${oldNotInNew.length}`);
  console.log('No Firestore writes were performed.');

  if (oldNotInNew.length > 0) {
    console.error('STOP: The importer does not delete old documents. Investigate before --commit.');
    process.exitCode = 2;
  } else {
    console.log('PASS: Every existing historical transaction ID is present in the new CSV.');
    console.log('NOTE: This checks ID overlap only; it does not confirm each existing field value or the absence of other-source duplicates.');
  }
}

main().catch((error) => {
  console.error('PREFLIGHT FAILED:', error?.message ?? error);
  process.exitCode = 1;
});
