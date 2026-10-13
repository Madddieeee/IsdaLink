'use strict';

// Exercise the importer's actual source-coverage function without credentials
// or Firestore writes.
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const source = fs.readFileSync(
  path.join(__dirname, 'import_historical_transactions.js'),
  'utf8',
);
const start = source.indexOf('function attachSourceCoverage(');
const end = source.indexOf('async function commitInChunks(', start);
if (start < 0 || end < 0) throw new Error('Importer coverage function not found');

const context = vm.createContext({
  clean: (value) => String(value ?? '').trim(),
});
vm.runInContext(source.slice(start, end), context);

const records = [
  { transactionDateIso: '2026-10-10' },
  { transactionDateIso: '2026-03-04' },
  { transactionDateIso: '2026-09-30' },
];
const coverage = context.attachSourceCoverage(records);

if (coverage.firstDate !== '2026-03-04' || coverage.lastDate !== '2026-10-10') {
  throw new Error('Wrong source coverage bounds');
}
for (const record of records) {
  if (
    record.sourceCoverageStartDateIso !== '2026-03-04' ||
    record.sourceCoverageEndDateIso !== '2026-10-10'
  ) {
    throw new Error('Coverage fields were not attached to every record');
  }
}

let rejectedEmpty = false;
try {
  context.attachSourceCoverage([]);
} catch (_) {
  rejectedEmpty = true;
}
if (!rejectedEmpty) throw new Error('Empty coverage was accepted');

console.log(
  'PASS: importer attaches explicit 2026-03-04 through 2026-10-10 ' +
  'source coverage; no Firestore access or writes.',
);
