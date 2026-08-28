const fs = require('fs');
const path = require('path');

const projectRoot = path.resolve(__dirname, '..');
const rulesPath = path.join(projectRoot, 'firestore.rules');
const rules = fs.readFileSync(rulesPath, 'utf8');

const requiredPatterns = [
  ['admin user transition guard', /function validAdminUserUpdate\(/],
  [
    'admin supplier application guard',
    /function validAdminSupplierApplicationReview\(/,
  ],
  [
    'admin verified profile-change guard',
    /function validAdminVerifiedProfileChange\(/,
  ],
  [
    'admin decision-notification guard',
    /function validAdminDecisionNotification\(/,
  ],
  ['stock schema guard', /function validStockCoreData\(/],
  ['stock state guard', /function validStockVisibilityState\(/],
  [
    'approved supplier role and status check',
    /get\(userPath\(uid\)\)\.data\.get\('role', ''\) == 'supplier'[\s\S]*&& get\(userPath\(uid\)\)\.data\.get\('supplierStatus', ''\) == 'approved'/,
  ],
  [
    'review order coupling',
    /afterOrder\.get\('reviewSubmitted', false\) == true/,
  ],
  [
    'review supplier aggregate coupling',
    /afterSupplier\.get\('lastReviewOrderId', ''\) == orderId/,
  ],
];

const forbiddenPatterns = [
  ['broad admin create permission', /allow\s+create:\s*if\s+isAdmin\(\)/],
  ['broad admin update permission', /allow\s+update:\s*if\s+isAdmin\(\)/],
  ['broad admin delete permission', /allow\s+delete:\s*if\s+isAdmin\(\)/],
  [
    'admin order override',
    /match\s+\/orders\/\{orderId\}[\s\S]*?allow\s+update:\s*if\s+isAdmin\(\)/,
  ],
];

const failures = [];

for (const [label, pattern] of requiredPatterns) {
  if (!pattern.test(rules)) {
    failures.push(`Missing ${label}.`);
  }
}

for (const [label, pattern] of forbiddenPatterns) {
  if (pattern.test(rules)) {
    failures.push(`Found ${label}.`);
  }
}

const opening = new Map([
  [')', '('],
  [']', '['],
  ['}', '{'],
]);
const stack = [];
let inString = false;
let escaped = false;

for (const character of rules) {
  if (inString) {
    if (escaped) {
      escaped = false;
    } else if (character === '\\') {
      escaped = true;
    } else if (character === "'") {
      inString = false;
    }
    continue;
  }

  if (character === "'") {
    inString = true;
  } else if ('([{'.includes(character)) {
    stack.push(character);
  } else if (')]}'.includes(character)) {
    if (stack.pop() !== opening.get(character)) {
      failures.push('Firestore rules have mismatched delimiters.');
      break;
    }
  }
}

if (stack.length > 0 || inString) {
  failures.push('Firestore rules have unclosed delimiters or strings.');
}

if (failures.length > 0) {
  console.error('Firestore security guard check failed:');
  for (const failure of failures) {
    console.error(`- ${failure}`);
  }
  process.exitCode = 1;
} else {
  console.log('Firestore security guard check passed.');
}
