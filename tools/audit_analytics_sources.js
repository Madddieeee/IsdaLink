'use strict';

// Read-only S5 evidence collection. Does not choose a de-duplication rule.
const fs = require('fs');
const path = require('path');

async function main() {
  const args = process.argv.slice(2);
  if (args.includes('--help')) {
    console.log('node audit_analytics_sources.js --project <firebase-project-id> [--output <json-file>]');
    console.log('Uses the existing Firebase Admin application-default credential setup. Reads orders and historicalTransactions; writes only a local JSON report.');
    return;
  }
  function option(name, fallback) {
    const index = args.indexOf(name);
    if (index < 0) return fallback;
    if (!args[index + 1] || args[index + 1].startsWith('--')) throw new Error(`${name} requires a value`);
    return args[index + 1];
  }
  const projectId = option('--project', null);
  if (!projectId) throw new Error('An explicit --project is required.');
  const output = path.resolve(option('--output', 'analytics_source_audit.json'));
  if (fs.existsSync(output)) throw new Error('Output exists; choose another --output filename.');
  const {initializeApp, applicationDefault, deleteApp} = require('firebase-admin/app');
  const {getFirestore} = require('firebase-admin/firestore');
  const app = initializeApp({credential: applicationDefault(), projectId});
  const db = getFirestore(app);
  const fields = [
    'transactionId', 'sourceTransactionId', 'sourceOrderId', 'orderId',
    'vendorUid', 'supplierUid', 'vendorId', 'supplierId',
    'vendorHistoricalId', 'supplierHistoricalId',
    'transactionDateIso', 'transactionDate', 'transaction_date', 'orderDate',
    'createdAt', 'importedAt', 'source', 'sourceFile', 'importBatchId',
    'sourceCoverageStartDateIso', 'sourceCoverageEndDateIso',
    'analyticsEligible', 'validationStatus', 'orderStatus', 'status',
    'productName', 'quantityUnit', 'quantityFulfilled', 'fulfilledQuantity',
    'quantity', 'fulfilledTotalAmount', 'totalAmount', 'paymentMethod', 'paymentStatus',
  ];
  function serialize(value) {
    if (value && typeof value.toDate === 'function') return value.toDate().toISOString();
    return value;
  }
  async function records(collection) {
    const snapshot = await db.collection(collection).get();
    return snapshot.docs.map((doc) => {
      const data = doc.data();
      const record = {documentId: doc.id};
      for (const field of fields) {
        if (Object.prototype.hasOwnProperty.call(data, field)) record[field] = serialize(data[field]);
      }
      if (Array.isArray(data.items) || Array.isArray(data.orderItems)) {
        const items = data.items ?? data.orderItems;
        record.analyticalItems = items.map((item) => {
          const line = {};
          if (item && typeof item === 'object') {
            for (const key of ['productName', 'quantityUnit', 'validatedFulfilledQuantity',
              'fulfilledQuantity', 'quantity', 'fulfilledTotalAmount', 'unitPrice']) {
              if (Object.prototype.hasOwnProperty.call(item, key)) line[key] = serialize(item[key]);
            }
          }
          return line;
        });
      }
      return record;
    });
  }
  const historical = await records('historicalTransactions');
  const live = await records('orders');
  const liveIds = new Set(live.map((record) => record.documentId));
  const report = {
    projectId, collectedAt: new Date().toISOString(), readOnly: true,
    historicalCount: historical.length, liveOrderCount: live.length,
    sameDocumentIdCandidates: historical.filter((record) => liveIds.has(record.documentId))
      .map((record) => record.documentId),
    interpretation: 'Counts and same-ID candidates are evidence only. Different IDs do not prove different real transactions; similar dates/products/quantities do not prove duplication. Confirm provenance and identity semantics before choosing a rule. The two reads are not an atomic Firestore snapshot.',
    historical, live,
  };
  fs.writeFileSync(output, JSON.stringify(report, null, 2), {flag: 'wx'});
  console.log(`Read ${historical.length} historical records and ${live.length} live orders. No Firestore writes. Report: ${output}`);
  await deleteApp(app);
}

main().catch((error) => {console.error(error.message); process.exitCode = 1;});
