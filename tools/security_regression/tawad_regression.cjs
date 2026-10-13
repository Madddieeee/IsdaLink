const fs = require('fs');
const path = require('path');
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');
const {
  doc,
  getDoc,
  setDoc,
  writeBatch,
  serverTimestamp,
  Timestamp,
} = require('firebase/firestore');

const root = path.resolve(__dirname, '../..');
const results = [];
let env;

async function check(name, operation, allowed) {
  try {
    await (allowed ? assertSucceeds(operation()) : assertFails(operation()));
    results.push({ name, pass: true });
    console.log(`PASS ${name}`);
  } catch (error) {
    results.push({ name, pass: false, error: error.message });
    console.error(`FAIL ${name}: ${error.message}`);
  }
}

function db(uid) {
  return env.authenticatedContext(uid).firestore();
}

async function seed(pathName, data) {
  await env.withSecurityRulesDisabled((context) =>
    setDoc(doc(context.firestore(), pathName), data),
  );
}

const buyer = 'tawad-buyer';
const unlockBuyer = 'tawad-unlock-buyer';
const supplier = 'tawad-supplier';
const delivery = {
  latitude: 8.9475,
  longitude: 125.5406,
  province: 'Agusan del Norte',
  locality: 'Butuan City',
};

function stock(id, quantity = 10) {
  return {
    category: 'Fresh Fish',
    description: 'Fresh fish for sale',
    emoji: '',
    imageUrl: 'https://example.com/fish.jpg',
    productImageUrl: 'https://example.com/fish.jpg',
    supplierId: supplier,
    supplierName: 'Test Supplier',
    productName: 'Barilis',
    quantity,
    quantityUnit: 'kilo',
    referenceStockQuantity: 10,
    lowStockPercentage: 20,
    lowStockLevel: 2,
    lowStockAlertEnabled: true,
    lowStockNotificationEnabled: true,
    lastLowStockNotificationAt: null,
    lastLowStockNotificationStatus: null,
    price: 5000,
    priceUnit: 'per kilo',
    status: 'available',
    isActive: true,
    stockStatus: 'available',
    paymentMethod: 'COD',
    supplierLocation: 'Butuan City, Caraga Region',
    supplierContactNumber: '09123456789',
    region: 'Caraga Region',
    createdAt: Timestamp.fromMillis(1700000000000),
    updatedAt: Timestamp.fromMillis(1700000000000),
  };
}

function order(id, stockId, offer = 4500) {
  return {
    stockId,
    fishStockId: stockId,
    supplierId: supplier,
    supplierName: 'Test Supplier',
    productName: 'Barilis',
    vendorId: buyer,
    vendorName: 'Test Buyer',
    quantity: 2,
    quantityUnit: 'kilo',
    unitPrice: 5000,
    listedUnitPrice: 5000,
    totalAmount: 10000,
    tawadRequested: true,
    tawadStatus: 'Pending',
    tawadOfferedUnitPrice: offer,
    tawadOfferedTotalAmount: offer * 2,
    tawadRequestedAt: serverTimestamp(),
    paymentMethod: 'COD',
    paymentStatus: 'To be paid on delivery',
    orderStatus: 'Pending',
    stockDeducted: true,
    stockRestored: false,
    reservedQuantity: 2,
    remainingStockAfterOrder: 8,
    deliveryLatitude: delivery.latitude,
    deliveryLongitude: delivery.longitude,
    deliveryProvince: delivery.province,
    deliveryCityMunicipality: delivery.locality,
    deliveryReferenceType: 'map_pin',
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  };
}

async function place(id, offer = 4500) {
  const database = db(buyer);
  const batch = writeBatch(database);
  batch.update(doc(database, 'fishStocks', id), {
    quantity: 8,
    stockStatus: 'available',
    lastOrderId: id,
    updatedAt: serverTimestamp(),
  });
  batch.set(doc(database, 'orders', id), order(id, id, offer));
  await batch.commit();
}

async function createEligibility(qualifyingOrderId) {
  const database = db(buyer);
  await setDoc(
    doc(database, 'tawadEligibility', buyer, 'suppliers', supplier),
    {
      vendorId: buyer,
      supplierId: supplier,
      qualifyingOrderId,
      unlockedAt: serverTimestamp(),
    },
  );
}

async function deliverAndUnlock() {
  const database = db(supplier);
  const batch = writeBatch(database);
  batch.update(doc(database, 'orders', 'supplier-delivery'), {
    orderStatus: 'Delivered',
    paymentStatus: 'Paid',
    deliveredAt: serverTimestamp(),
    completedAt: serverTimestamp(),
    isReviewEligible: true,
    updatedAt: serverTimestamp(),
  });
  batch.set(
    doc(database, 'tawadEligibility', unlockBuyer, 'suppliers', supplier),
    {
      vendorId: unlockBuyer,
      supplierId: supplier,
      qualifyingOrderId: 'supplier-delivery',
      unlockedAt: serverTimestamp(),
    },
  );
  await batch.commit();
}

async function accept(id, unitPrice = 4500, extra = {}) {
  const database = db(supplier);
  await setDoc(
    doc(database, 'orders', id),
    {
      orderStatus: 'Accepted',
      paymentStatus: 'To be paid on delivery',
      unitPrice,
      totalAmount: unitPrice * 2,
      fulfilledQuantity: 2,
      unfulfilledQuantity: 0,
      fulfilledTotalAmount: unitPrice * 2,
      reservedQuantity: 2,
      partialFulfillment: false,
      fulfillmentStatus: 'full',
      partialStockRestored: false,
      partialRestoredQuantity: 0,
      tawadStatus: 'Accepted',
      tawadAcceptedAt: serverTimestamp(),
      acceptedAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
      ...extra,
    },
    { merge: true },
  );
}

async function decline(id, actor = supplier) {
  const database = db(actor);
  const batch = writeBatch(database);
  batch.update(doc(database, 'fishStocks', id), {
    quantity: 10,
    stockStatus: 'available',
    lastStockRestoreOrderId: id,
    updatedAt: serverTimestamp(),
  });
  batch.update(doc(database, 'orders', id), {
    orderStatus: 'Cancelled',
    paymentStatus: 'Cancelled',
    stockRestored: true,
    stockRestorePending: false,
    cancelledBy: actor === supplier ? 'supplier' : 'vendor',
    tawadStatus: actor === supplier ? 'Declined' : 'Withdrawn',
    ...(actor === supplier
      ? { tawadDeclinedAt: serverTimestamp() }
      : { tawadWithdrawnAt: serverTimestamp() }),
    cancelledAt: serverTimestamp(),
    restoredAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  });
  await batch.commit();
}

(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-isdalink-tawad',
    firestore: {
      rules: fs.readFileSync(
        process.env.RULES_PATH || path.join(root, 'firestore.rules'),
        'utf8',
      ),
      host: '127.0.0.1',
      port: 8080,
    },
  });

  await seed(`users/${buyer}`, { uid: buyer, role: 'vendor' });
  await seed(`users/${unlockBuyer}`, { uid: unlockBuyer, role: 'vendor' });
  await seed(`users/${supplier}`, {
    uid: supplier,
    role: 'supplier',
    supplierStatus: 'approved',
  });
  await seed(`supplierProfiles/${supplier}`, {
    uid: supplier,
    status: 'approved',
    supplierName: 'Test Supplier',
    location: 'Butuan City, Caraga Region',
    phone: '09123456789',
  });

  for (const id of ['locked', 'accepted', 'wrong-price', 'counter', 'declined', 'withdrawn']) {
    await seed(`fishStocks/${id}`, stock(id));
  }

  await seed('orders/qualifying-purchase', {
    vendorId: buyer,
    supplierId: supplier,
    orderStatus: 'Delivered',
    paymentStatus: 'Paid',
  });
  await seed('orders/unpaid-purchase', {
    vendorId: buyer,
    supplierId: supplier,
    orderStatus: 'Delivered',
    paymentStatus: 'To be paid on delivery',
  });
  await seed('orders/supplier-delivery', {
    vendorId: unlockBuyer,
    supplierId: supplier,
    orderStatus: 'Accepted',
    paymentStatus: 'To be paid on delivery',
  });

  await check(
    'New buyer cannot request Tawad before a completed purchase',
    () => place('locked'),
    false,
  );
  await check(
    'Delivered but unpaid order cannot unlock Tawad',
    () => createEligibility('unpaid-purchase'),
    false,
  );
  await check(
    'Buyer can unlock Tawad from a delivered and paid supplier order',
    () => createEligibility('qualifying-purchase'),
    true,
  );
  await check(
    'Supplier delivery records payment and unlocks Tawad atomically',
    () => deliverAndUnlock(),
    true,
  );
  await check(
    'Unlocked buyer can read supplier-specific Tawad access',
    async () => {
      const referencePath = `tawadEligibility/${unlockBuyer}/suppliers/${supplier}`;
      const snapshot = await getDoc(doc(db(unlockBuyer), referencePath));
      if (!snapshot.exists()) throw new Error('Eligibility was not created');
    },
    true,
  );

  await check('Tawad creates a real pending order and reserves stock', () => place('accepted'), true);
  await check('Supplier accepts the exact offered price', () => accept('accepted'), true);
  await check('Accepted order stores the offered COD total', async () => {
    const snapshot = await getDoc(doc(db(buyer), 'orders', 'accepted'));
    if (snapshot.data().totalAmount !== 9000) throw new Error('Wrong total');
  }, true);

  await place('wrong-price');
  await check('Supplier cannot accept a different price', () => accept('wrong-price', 4600), false);

  await place('counter');
  await check(
    'Supplier cannot create a counteroffer',
    () => accept('counter', 4500, { tawadCounterUnitPrice: 4700 }),
    false,
  );

  await place('declined');
  await check('Supplier decline cancels and restores stock', () => decline('declined'), true);

  await place('withdrawn');
  await check('Vendor withdrawal cancels and restores stock', () => decline('withdrawn', buyer), true);

  console.log(`RESULT ${results.filter((item) => item.pass).length}/${results.length}`);
  await env.cleanup();
  process.exitCode = results.some((item) => !item.pass) ? 1 : 0;
})().catch(async (error) => {
  console.error(error);
  if (env) await env.cleanup();
  process.exit(1);
});
