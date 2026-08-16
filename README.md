# IsdaLink

IsdaLink is a mobile-based fish supply management system for vendor-supplier
coordination in the Caraga Region.

## Core scope

- Vendor registration and profile management
- Admin-reviewed Supplier activation
- Supplier verification evidence
- Fish stock posting and management
- Cash on Delivery ordering only
- Full and partial supplier fulfillment
- Stock restoration for unfulfilled/cancelled quantities
- Vendor My Orders and Supplier COD Orders
- Supplier reviews after completed orders
- Low-stock and out-of-stock in-app notifications
- Vendor Analytics and Supplier Analytics
- Weekly/monthly Simple Moving Average
- Weekly/monthly Seasonal Moving Average
- MAPE and MAE forecast evaluation
- Optional historical transaction import into `historicalTransactions`

## Run locally

```powershell
flutter pub get
flutter analyze
flutter run
```

## Firestore Security Rules

The local master rules file is:

```text
firestore.rules
```

`firebase.json` points Firestore Rules deployment to this file.

Keep the Firebase Console Rules tab synchronized with the local
`firestore.rules` version before final deployment.

## Product history

Supplier listings are archived instead of hard-deleted so historical order
references remain intact. Archived listings are hidden from vendors and can
be restored later.

## Historical analytics import

Historical CSV import is optional. Import tooling is under:

```text
tools/
```

Historical rows must go into `historicalTransactions`, never the operational
`orders` collection.

The following local files are intentionally ignored by Git:

```text
tools/historical_id_map.json
dataset/*.csv
Firebase Admin service-account JSON files
node_modules/
```

Never commit Firebase Admin private keys to source control.
