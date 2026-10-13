'use strict';

// Offline regression guard: the read-only Analytics source audit must retain
// the historical source-coverage fields used to exclude partial boundary
// weeks and months. This script never connects to Firestore.
const fs = require('fs');
const path = require('path');

const auditPath = path.join(__dirname, 'audit_analytics_sources.js');
const source = fs.readFileSync(auditPath, 'utf8');
const fieldsStart = source.indexOf('const fields = [');
const fieldsEnd = source.indexOf('];', fieldsStart);

if (fieldsStart < 0 || fieldsEnd < 0) {
  throw new Error('Could not find the Analytics audit field list.');
}

const fieldsBlock = source.slice(fieldsStart, fieldsEnd);
for (const field of [
  'sourceCoverageStartDateIso',
  'sourceCoverageEndDateIso',
]) {
  if (!fieldsBlock.includes(`'${field}'`)) {
    throw new Error(`Analytics audit is missing ${field}.`);
  }
}

console.log(
  'PASS: Analytics source audit exports both historical coverage fields; ' +
  'no Firestore access or writes.',
);
