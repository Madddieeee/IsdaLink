'use strict';

// Exercise the actual importer date function without credentials or writes.
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const source = fs.readFileSync(path.join(__dirname, 'import_historical_transactions.js'), 'utf8');
const start = source.indexOf('function parseDate(');
const end = source.indexOf('function parseTime(', start);
if (start < 0 || end < 0) throw new Error('Importer function not found');
const context = vm.createContext({
  clean: (value) => String(value ?? '').trim(),
  Timestamp: {fromDate: (date) => date},
});
vm.runInContext(source.slice(start, end), context);
let count = 0;
for (const value of ['2026-09-28', '2024-02-29']) {
  const result = context.parseDate(value, 'transaction_date', 2);
  if (result.text !== value || result.timestamp.toISOString().slice(0, 10) !== value) {
    throw new Error(`Valid date failed: ${value}`);
  }
  count++;
}
for (const value of ['', '2026-02-29', '2026-02-30', '2026-13-01', '2026-00-01', 'not a date']) {
  let rejected = false;
  try { context.parseDate(value, 'transaction_date', 2); }
  catch (_) { rejected = true; }
  if (!rejected) throw new Error(`Invalid date accepted: ${value}`);
  count++;
}
if (context.parseDate('', 'completion_date', 2, false) !== null) {
  throw new Error('Optional blank date should stay absent');
}
count++;
console.log(`PASS: ${count} actual importer date checks; no Firestore access or writes.`);
