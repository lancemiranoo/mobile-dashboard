# Mobile Dashboard

Flutter mobile application for monitoring gold trade signals from Firebase.

## Scope

- Auth: Firebase email/password login and registration.
- Data: Cloud Firestore documents using the provided fields:
  `Timestamp`, `Ticket`, `Symbol`, `Type`, `Status`, `Price`, `SL`, `TP`,
  `Profit`, `Loss`, and `Channel`.
- Dashboard: XAUUSD only. No other forex pairs are shown.
- Visualization: latest price cards, signal insights, price movement chart,
  and recent signal list.

## Firebase Runtime Configuration

The app expects Firebase configuration through Dart defines:

```powershell
flutter run `
  --dart-define=FIREBASE_API_KEY=your_api_key `
  --dart-define=FIREBASE_APP_ID=your_app_id `
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=your_sender_id `
  --dart-define=FIREBASE_PROJECT_ID=your_project_id `
  --dart-define=FIREBASE_AUTH_DOMAIN=your_project.firebaseapp.com `
  --dart-define=FIREBASE_STORAGE_BUCKET=your_project.appspot.com `
  --dart-define=FIRESTORE_TRADES_COLLECTION=trades
```

`FIRESTORE_TRADES_COLLECTION` is optional and defaults to `trades`.

## Firestore Query

The dashboard listens to:

```text
collection(FIRESTORE_TRADES_COLLECTION)
  where Symbol == XAUUSD
  order by Timestamp desc
  limit 40
```

Firestore may require a composite index for `Symbol` plus `Timestamp`.

## Local Setup

Flutter is required to run this project:

```powershell
flutter pub get
flutter test
flutter run
```

This machine did not have Flutter installed when the project was scaffolded, so
platform folders can be generated with:

```powershell
flutter create .
```

## Vendored Codex Skills

The requested Codex skills are committed under `codex-skills/` so they can sync
with the repository:

- `figma-generate-design`
- `security-best-practices`
- `security-threat-model`
