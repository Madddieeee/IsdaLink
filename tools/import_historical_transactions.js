'use strict';

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const { parse } = require('csv-parse/sync');
const {
  initializeApp,
  applicationDefault,
} = require('firebase-admin/app');
const {
  getFirestore,
  FieldValue,
  Timestamp,
} = require('firebase-admin/firestore');

const REQUIRED_CANONICAL_FIELDS = [
  'transaction_id',
  'transaction_date',
  'order_status',
  'vendor_id',
  'supplier_id',
  'fish_product',
  'quantity_fulfilled',
  'quantity_unit',
  'unit_price_php',
  'total_amount_php',
  'payment_method',
  'validation_status',
];

function usage() {
  console.log(`
IsdaLink historical transaction importer

Dry-run validation:
  node import_historical_transactions.js <csv-file> <mapping-json>

Commit import:
  node import_historical_transactions.js <csv-file> <mapping-json> --commit

Example:
  node import_historical_transactions.js ../dataset/transaction_log_FINAL_VERIFIED.csv historical_id_map.json
  node import_historical_transactions.js ../dataset/transaction_log_FINAL_VERIFIED.csv historical_id_map.json --commit

Credentials:
  Set GOOGLE_APPLICATION_CREDENTIALS to a Firebase Admin service-account JSON
  file before running the script.
`);
}

function clean(value) {
  return String(value ?? '').trim();
}

function lower(value) {
  return clean(value).toLowerCase();
}

function numberValue(value, fieldName, rowNumber) {
  const text = clean(value);

  if (text === '') {
    throw new Error(`Row ${rowNumber}: ${fieldName} is blank.`);
  }

  const parsed = Number(text);

  if (!Number.isFinite(parsed)) {
    throw new Error(
      `Row ${rowNumber}: ${fieldName} is not a valid number: "${text}".`,
    );
  }

  return parsed;
}

function optionalNumber(value) {
  const text = clean(value);

  if (text === '') {
    return null;
  }

  const parsed = Number(text);
  return Number.isFinite(parsed) ? parsed : null;
}

function normalizeUnit(value, rowNumber) {
  const raw = lower(value)
    .replace(/[_-]+/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();

  if (
    raw === 'kg' ||
    raw === 'kgs' ||
    raw === 'kilo' ||
    raw === 'kilos' ||
    raw === 'kilogram' ||
    raw === 'kilograms'
  ) {
    return 'kilogram';
  }

  if (raw === 'tab' || raw === 'tabs') {
    return 'tab';
  }

  if (
    raw === 'icebox' ||
    raw === 'iceboxes' ||
    raw === 'ice box' ||
    raw === 'ice boxes'
  ) {
    return 'icebox';
  }

  throw new Error(
    `Row ${rowNumber}: unsupported quantity_unit "${value}". ` +
    'Expected kilogram, tab, or icebox.',
  );
}

function normalizePriceUnit(value, quantityUnit) {
  const raw = lower(value).replace(/\s+/g, ' ').trim();

  if (raw === '') {
    return `per ${quantityUnit}`;
  }

  const expected = `per ${quantityUnit}`;

  const aliases = quantityUnit === 'kilogram'
    ? new Set(['per kilogram', 'per kilo', 'per kg'])
    : new Set([expected]);

  if (!aliases.has(raw)) {
    throw new Error(
      `price_unit "${value}" does not match quantity_unit "${quantityUnit}".`,
    );
  }

  return expected;
}

function parseDate(value, fieldName, rowNumber, required = true) {
  const text = clean(value);

  if (text === '') {
    if (required) {
      throw new Error(`Row ${rowNumber}: ${fieldName} is blank.`);
    }
    return null;
  }

  if (!/^\d{4}-\d{2}-\d{2}$/.test(text)) {
    throw new Error(
      `Row ${rowNumber}: ${fieldName} must use YYYY-MM-DD, got "${text}".`,
    );
  }

  const date = new Date(`${text}T00:00:00.000Z`);

  if (Number.isNaN(date.getTime())) {
    throw new Error(
      `Row ${rowNumber}: ${fieldName} is not a valid date: "${text}".`,
    );
  }

  return {
    text,
    timestamp: Timestamp.fromDate(date),
  };
}

function parseTime(value, fieldName, rowNumber, required = false) {
  const text = clean(value);

  if (text === '') {
    if (required) {
      throw new Error(`Row ${rowNumber}: ${fieldName} is blank.`);
    }
    return '';
  }

  if (!/^(?:[01]\d|2[0-3]):[0-5]\d$/.test(text)) {
    throw new Error(
      `Row ${rowNumber}: ${fieldName} must use 24-hour HH:MM, got "${text}".`,
    );
  }

  return text;
}

function boolValue(value) {
  const raw = lower(value);

  if (raw === 'true' || raw === 'yes' || raw === '1') {
    return true;
  }

  if (raw === 'false' || raw === 'no' || raw === '0' || raw === '') {
    return false;
  }

  throw new Error(`Invalid boolean value "${value}".`);
}

function field(row, ...names) {
  for (const name of names) {
    if (Object.prototype.hasOwnProperty.call(row, name)) {
      const value = row[name];

      if (clean(value) !== '') {
        return value;
      }
    }
  }

  return '';
}

function hasField(headers, ...names) {
  return names.some((name) => headers.includes(name));
}

function sanitizeTransactionId(value, rowNumber) {
  const id = clean(value);

  if (id === '') {
    throw new Error(`Row ${rowNumber}: transaction_id is blank.`);
  }

  if (id.includes('/')) {
    throw new Error(
      `Row ${rowNumber}: transaction_id cannot contain "/": "${id}".`,
    );
  }

  return id;
}

function eligibleRow(row) {
  return (
    lower(field(row, 'order_status', 'status')) === 'completed' &&
    lower(field(row, 'validation_status')) === 'validated'
  );
}

function paymentIsCod(value) {
  const raw = lower(value);

  return (
    raw === 'cod' ||
    raw === 'cash on delivery' ||
    raw === 'cash on delivery (cod)'
  );
}

function loadJson(filePath) {
  return JSON.parse(fs.readFileSync(filePath, 'utf8'));
}

function validateMappingShape(mapping) {
  if (!mapping || typeof mapping !== 'object') {
    throw new Error('Mapping JSON is invalid.');
  }

  if (!mapping.vendors || typeof mapping.vendors !== 'object') {
    throw new Error('Mapping JSON must contain a "vendors" object.');
  }

  if (!mapping.suppliers || typeof mapping.suppliers !== 'object') {
    throw new Error('Mapping JSON must contain a "suppliers" object.');
  }
}

function mappedUid(mappingSection, historicalId) {
  const uid = clean(mappingSection[historicalId]);

  if (
    uid === '' ||
    uid === 'PASTE_FIREBASE_UID_HERE' ||
    uid.startsWith('PASTE_')
  ) {
    return '';
  }

  return uid;
}

function validateOneToOneMappings(mapping) {
  for (const [sectionName, entries] of Object.entries({
    vendors: mapping.vendors,
    suppliers: mapping.suppliers,
  })) {
    const uidToHistoricalId = new Map();

    for (const [historicalId, rawUid] of Object.entries(entries)) {
      const uid = mappedUid(entries, historicalId);

      if (!uid) {
        continue;
      }

      if (uidToHistoricalId.has(uid)) {
        throw new Error(
          `${sectionName}: Firebase UID "${uid}" is mapped to both ` +
          `"${uidToHistoricalId.get(uid)}" and "${historicalId}". ` +
          'Each account may have only one historical ID for the same role.',
        );
      }

      uidToHistoricalId.set(uid, historicalId);
    }
  }
}

function canonicalRecord(row, rowNumber, mapping, sourceFile) {
  const transactionId = sanitizeTransactionId(
    field(row, 'transaction_id'),
    rowNumber,
  );

  const transactionDate = parseDate(
    field(row, 'transaction_date', 'order_date'),
    'transaction_date',
    rowNumber,
    true,
  );

  const transactionTime = parseTime(
    field(row, 'transaction_time', 'order_time'),
    'transaction_time',
    rowNumber,
    false,
  );

  const completionDate = parseDate(
    field(row, 'completion_date'),
    'completion_date',
    rowNumber,
    false,
  );

  const completionTime = parseTime(
    field(row, 'completion_time'),
    'completion_time',
    rowNumber,
    false,
  );

  const vendorHistoricalId = clean(field(row, 'vendor_id'));
  const supplierHistoricalId = clean(field(row, 'supplier_id'));

  if (!vendorHistoricalId) {
    throw new Error(`Row ${rowNumber}: vendor_id is blank.`);
  }

  if (!supplierHistoricalId) {
    throw new Error(`Row ${rowNumber}: supplier_id is blank.`);
  }

  const vendorUid = mappedUid(
    mapping.vendors,
    vendorHistoricalId,
  );
  const supplierUid = mappedUid(
    mapping.suppliers,
    supplierHistoricalId,
  );

  if (!vendorUid) {
    throw new Error(
      `Row ${rowNumber}: ${vendorHistoricalId} has no Firebase UID mapping.`,
    );
  }

  if (!supplierUid) {
    throw new Error(
      `Row ${rowNumber}: ${supplierHistoricalId} has no Firebase UID mapping.`,
    );
  }

  if (vendorUid === supplierUid) {
    throw new Error(
      `Row ${rowNumber}: vendor and supplier resolve to the same Firebase UID. ` +
      'Historical self-transactions are not allowed.',
    );
  }

  const productName = clean(field(row, 'fish_product'));

  if (!productName) {
    throw new Error(`Row ${rowNumber}: fish_product is blank.`);
  }

  const quantityOrdered = numberValue(
    field(row, 'quantity_ordered'),
    'quantity_ordered',
    rowNumber,
  );

  const quantityFulfilled = numberValue(
    field(row, 'quantity_fulfilled'),
    'quantity_fulfilled',
    rowNumber,
  );

  if (quantityOrdered < 0) {
    throw new Error(`Row ${rowNumber}: quantity_ordered cannot be negative.`);
  }

  if (quantityFulfilled <= 0) {
    throw new Error(
      `Row ${rowNumber}: quantity_fulfilled must be greater than zero.`,
    );
  }

  if (quantityFulfilled > quantityOrdered) {
    throw new Error(
      `Row ${rowNumber}: quantity_fulfilled cannot exceed quantity_ordered.`,
    );
  }

  const quantityUnit = normalizeUnit(
    field(row, 'quantity_unit'),
    rowNumber,
  );

  let priceUnit;

  try {
    priceUnit = normalizePriceUnit(
      field(row, 'price_unit'),
      quantityUnit,
    );
  } catch (error) {
    throw new Error(`Row ${rowNumber}: ${error.message}`);
  }

  const unitPrice = numberValue(
    field(row, 'unit_price_php'),
    'unit_price_php',
    rowNumber,
  );

  const totalAmount = numberValue(
    field(row, 'total_amount_php'),
    'total_amount_php',
    rowNumber,
  );

  if (unitPrice < 0 || totalAmount < 0) {
    throw new Error(
      `Row ${rowNumber}: price and total amount cannot be negative.`,
    );
  }

  const expectedTotal = quantityFulfilled * unitPrice;

  if (Math.abs(expectedTotal - totalAmount) > 0.01) {
    throw new Error(
      `Row ${rowNumber}: total_amount_php (${totalAmount}) does not equal ` +
      `quantity_fulfilled × unit_price_php (${expectedTotal}).`,
    );
  }

  const paymentMethodRaw = clean(field(row, 'payment_method'));

  if (!paymentIsCod(paymentMethodRaw)) {
    throw new Error(
      `Row ${rowNumber}: unsupported payment method "${paymentMethodRaw}". ` +
      'IsdaLink historical analytics accepts Cash on Delivery only.',
    );
  }

  const orderStatus = clean(field(row, 'order_status', 'status'));
  const validationStatus = clean(field(row, 'validation_status'));

  return {
    transactionId,
    sourceIndex: optionalNumber(field(row, 'index')),
    transactionDate: transactionDate.timestamp,
    transactionDateIso: transactionDate.text,
    transactionTime,

    completionDate: completionDate?.timestamp ?? null,
    completionDateIso: completionDate?.text ?? '',
    completionTime,

    vendorHistoricalId,
    vendorUid,
    supplierHistoricalId,
    supplierUid,

    productName,
    fishCategory: clean(field(row, 'fish_category')),
    quantityOrdered,
    quantityFulfilled,
    quantityUnit,
    unitPrice,
    priceUnit,
    totalAmount,

    orderStatus: orderStatus || 'Completed',
    paymentMethod: 'COD',
    codPaymentStatus: clean(field(row, 'cod_payment_status')),

    fulfillmentDeliveryDetails: clean(
      field(
        row,
        'fulfillment_delivery_details',
        'delivery_reference_area',
      ),
    ),
    fishConditionOnArrival: clean(
      field(row, 'fish_condition_on_arrival'),
    ),
    disputeFlag: boolValue(field(row, 'dispute_flag')),
    disputeNotes: clean(field(row, 'dispute_notes')),

    recordedBy: clean(field(row, 'recorded_by')),
    verifiedBy: clean(field(row, 'verified_by')),
    dateEncoded: clean(field(row, 'date_encoded')),
    validationStatus,
    exclusionReason: clean(field(row, 'exclusion_reason')),
    remarks: clean(field(row, 'remarks')),

    analyticsEligible: true,
    source: 'historical_dataset',
    sourceFile,
  };
}

async function validateMappedUsers(db, mapping) {
  const unique = new Map();

  for (const [historicalId, rawUid] of Object.entries(mapping.vendors)) {
    const uid = mappedUid(mapping.vendors, historicalId);

    if (uid) {
      unique.set(`vendor:${historicalId}`, { historicalId, uid, type: 'vendor' });
    }
  }

  for (const [historicalId, rawUid] of Object.entries(mapping.suppliers)) {
    const uid = mappedUid(mapping.suppliers, historicalId);

    if (uid) {
      unique.set(
        `supplier:${historicalId}`,
        { historicalId, uid, type: 'supplier' },
      );
    }
  }

  const byUid = new Map();

  for (const entry of unique.values()) {
    if (!byUid.has(entry.uid)) {
      byUid.set(entry.uid, []);
    }
    byUid.get(entry.uid).push(entry);
  }

  for (const [uid, entries] of byUid.entries()) {
    const userSnapshot = await db.collection('users').doc(uid).get();

    if (!userSnapshot.exists) {
      throw new Error(
        `Mapped Firebase UID "${uid}" has no users/${uid} document.`,
      );
    }

    const userData = userSnapshot.data() || {};

    for (const entry of entries) {
      if (entry.type === 'supplier') {
        const role = lower(userData.role);
        const supplierStatus = lower(userData.supplierStatus);

        if (role !== 'supplier' && supplierStatus !== 'approved') {
          throw new Error(
            `${entry.historicalId} maps to ${uid}, but that account is not ` +
            'an approved supplier-enabled account.',
          );
        }
      }

      const fieldName =
        entry.type === 'vendor'
          ? 'historicalVendorId'
          : 'historicalSupplierId';

      const existing = clean(userData[fieldName]);

      if (existing && existing !== entry.historicalId) {
        throw new Error(
          `users/${uid}.${fieldName} is already "${existing}", but the mapping ` +
          `requests "${entry.historicalId}".`,
        );
      }
    }
  }

  return byUid;
}

function makeBatchId(records, sourceFile) {
  const dates = records
    .map((record) => record.transactionDateIso)
    .sort();

  const raw =
    `${path.basename(sourceFile)}|${records.length}|` +
    `${dates[0] ?? ''}|${dates[dates.length - 1] ?? ''}`;

  const shortHash = crypto
    .createHash('sha256')
    .update(raw)
    .digest('hex')
    .slice(0, 12);

  return `transaction-log-${dates[0]}_${dates[dates.length - 1]}-${shortHash}`;
}

async function commitInChunks(db, operations, chunkSize = 400) {
  for (let start = 0; start < operations.length; start += chunkSize) {
    const batch = db.batch();
    const chunk = operations.slice(start, start + chunkSize);

    for (const operation of chunk) {
      operation(batch);
    }

    await batch.commit();
    console.log(
      `Committed ${Math.min(start + chunk.length, operations.length)}` +
      ` / ${operations.length} writes`,
    );
  }
}

async function main() {
  const args = process.argv.slice(2);
  const commit = args.includes('--commit');
  const positional = args.filter((arg) => arg !== '--commit');

  if (positional.length !== 2) {
    usage();
    process.exitCode = 1;
    return;
  }

  const csvPath = path.resolve(positional[0]);
  const mappingPath = path.resolve(positional[1]);

  if (!fs.existsSync(csvPath)) {
    throw new Error(`CSV file not found: ${csvPath}`);
  }

  if (!fs.existsSync(mappingPath)) {
    throw new Error(`Mapping JSON not found: ${mappingPath}`);
  }

  const mapping = loadJson(mappingPath);
  validateMappingShape(mapping);
  validateOneToOneMappings(mapping);

  const csvText = fs.readFileSync(csvPath, 'utf8');

  const rows = parse(csvText, {
    columns: true,
    skip_empty_lines: true,
    bom: true,
    relax_column_count: false,
    trim: false,
  });

  if (!rows.length) {
    throw new Error('CSV contains no data rows.');
  }

  const headers = Object.keys(rows[0]);

  const headerRequirements = [
    ['transaction_id'],
    ['transaction_date', 'order_date'],
    ['order_status', 'status'],
    ['vendor_id'],
    ['supplier_id'],
    ['fish_product'],
    ['quantity_ordered'],
    ['quantity_fulfilled'],
    ['quantity_unit'],
    ['unit_price_php'],
    ['total_amount_php'],
    ['payment_method'],
    ['validation_status'],
  ];

  for (const alternatives of headerRequirements) {
    if (!hasField(headers, ...alternatives)) {
      throw new Error(
        `CSV is missing required header: ${alternatives.join(' or ')}`,
      );
    }
  }

  const eligibleRows = rows.filter(eligibleRow);
  const skippedRows = rows.length - eligibleRows.length;

  const records = [];
  const seenIds = new Set();

  for (let index = 0; index < eligibleRows.length; index += 1) {
    const rowNumber = rows.indexOf(eligibleRows[index]) + 2;
    const record = canonicalRecord(
      eligibleRows[index],
      rowNumber,
      mapping,
      path.basename(csvPath),
    );

    if (seenIds.has(record.transactionId)) {
      throw new Error(
        `Duplicate transaction_id found: ${record.transactionId}`,
      );
    }

    seenIds.add(record.transactionId);
    records.push(record);
  }

  if (!records.length) {
    throw new Error(
      'No Completed + Validated rows are eligible for historical analytics.',
    );
  }

  const requiredVendorIds = new Set(
    records.map((record) => record.vendorHistoricalId),
  );
  const requiredSupplierIds = new Set(
    records.map((record) => record.supplierHistoricalId),
  );

  const missingVendorIds = [...requiredVendorIds].filter(
    (id) => !mappedUid(mapping.vendors, id),
  );
  const missingSupplierIds = [...requiredSupplierIds].filter(
    (id) => !mappedUid(mapping.suppliers, id),
  );

  if (missingVendorIds.length || missingSupplierIds.length) {
    throw new Error(
      `Missing mappings. Vendors: ${missingVendorIds.join(', ') || 'none'}; ` +
      `Suppliers: ${missingSupplierIds.join(', ') || 'none'}.`,
    );
  }

  const firstDate = records
    .map((record) => record.transactionDateIso)
    .sort()[0];
  const lastDate = records
    .map((record) => record.transactionDateIso)
    .sort()
    .at(-1);

  console.log('');
  console.log('IsdaLink historical import validation');
  console.log('------------------------------------');
  console.log(`Source file: ${path.basename(csvPath)}`);
  console.log(`CSV rows: ${rows.length}`);
  console.log(`Eligible Completed + Validated: ${records.length}`);
  console.log(`Skipped non-eligible rows: ${skippedRows}`);
  console.log(`Date range: ${firstDate} to ${lastDate}`);
  console.log(`Vendor IDs: ${[...requiredVendorIds].sort().join(', ')}`);
  console.log(`Supplier IDs: ${[...requiredSupplierIds].sort().join(', ')}`);
  console.log('');

  initializeApp({
    credential: applicationDefault(),
  });

  const db = getFirestore();

  const linkedUsers = await validateMappedUsers(db, mapping);

  console.log(`Validated ${linkedUsers.size} mapped Firebase account(s).`);

  if (!commit) {
    console.log('');
    console.log('DRY RUN PASSED.');
    console.log(
      'Nothing was written. Run the same command with --commit to import.',
    );
    return;
  }

  const batchId = makeBatchId(records, csvPath);
  const operations = [];

  for (const record of records) {
    const documentReference = db
      .collection('historicalTransactions')
      .doc(record.transactionId);

    operations.push((batch) => {
      batch.set(
        documentReference,
        {
          ...record,
          importBatchId: batchId,
          importedAt: FieldValue.serverTimestamp(),
        },
        { merge: false },
      );
    });
  }

  for (const [historicalId, rawUid] of Object.entries(mapping.vendors)) {
    const uid = mappedUid(mapping.vendors, historicalId);

    if (!uid || !requiredVendorIds.has(historicalId)) {
      continue;
    }

    operations.push((batch) => {
      batch.set(
        db.collection('users').doc(uid),
        {
          historicalVendorId: historicalId,
          historicalDataLinkedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    });
  }

  for (const [historicalId, rawUid] of Object.entries(mapping.suppliers)) {
    const uid = mappedUid(mapping.suppliers, historicalId);

    if (!uid || !requiredSupplierIds.has(historicalId)) {
      continue;
    }

    operations.push((batch) => {
      batch.set(
        db.collection('users').doc(uid),
        {
          historicalSupplierId: historicalId,
          historicalDataLinkedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    });
  }

  operations.push((batch) => {
    batch.set(
      db.collection('historicalImports').doc(batchId),
      {
        batchId,
        sourceFile: path.basename(csvPath),
        sourceRowCount: rows.length,
        importedEligibleCount: records.length,
        skippedCount: skippedRows,
        firstTransactionDate: firstDate,
        lastTransactionDate: lastDate,
        vendorHistoricalIds: [...requiredVendorIds].sort(),
        supplierHistoricalIds: [...requiredSupplierIds].sort(),
        importedAt: FieldValue.serverTimestamp(),
      },
      { merge: false },
    );
  });

  await commitInChunks(db, operations);

  console.log('');
  console.log('IMPORT COMPLETE.');
  console.log(`Batch ID: ${batchId}`);
  console.log(
    `historicalTransactions now contains/upserts ${records.length} ` +
    'source transaction IDs from this file.',
  );
  console.log(
    'Re-running this importer with the same source transaction IDs updates ' +
    'the same documents instead of creating duplicates.',
  );
}

main().catch((error) => {
  console.error('');
  console.error('IMPORT FAILED');
  console.error(error?.stack || error?.message || error);
  process.exitCode = 1;
});
