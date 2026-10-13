'use strict';

// Verifies historical dataset coverage in a read-only audit report. Live
// orders are intentionally ignored because they are not part of the validated
// historical dataset regression.
const fs = require('fs');
const path = require('path');

const args = process.argv.slice(2);
if (args.length !== 1) {
  console.error(
    'Usage: node tools/verify_analytics_audit_coverage_report.js <audit-report.json>',
  );
  process.exitCode = 1;
} else {
  const reportPath = path.resolve(args[0]);
  const report = JSON.parse(fs.readFileSync(reportPath, 'utf8'));
  const historical = Array.isArray(report.historical) ? report.historical : [];

  if (historical.length !== 1090) {
    throw new Error(
      `Expected 1090 historical dataset records, found ${historical.length}.`,
    );
  }

  const invalid = historical.filter(
    (record) =>
      record.sourceCoverageStartDateIso !== '2026-03-04' ||
      record.sourceCoverageEndDateIso !== '2026-10-10',
  );

  if (invalid.length > 0) {
    throw new Error(
      `${invalid.length} historical record(s) have missing or incorrect ` +
      'source coverage fields.',
    );
  }

  console.log(
    'PASS: all 1090 historical dataset records report source coverage ' +
    '2026-03-04 through 2026-10-10. Live test orders were ignored. ' +
    'No Firestore access or writes.',
  );
}
