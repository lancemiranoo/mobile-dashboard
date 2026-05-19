# Firestore Schema

The dashboard reads an existing trade collection that matches the spreadsheet-style
fields from the provided screenshot.

Default collection path:

```text
trades
```

Override it at runtime:

```powershell
flutter run --dart-define=FIRESTORE_TRADES_COLLECTION=your_collection_name
```

Required document fields:

| Field | Type | Notes |
| --- | --- | --- |
| `Timestamp` | Firestore timestamp, ISO string, or milliseconds | Used for chart ordering. |
| `Ticket` | string or number | Displayed in recent signals. |
| `Symbol` | string | Must equal `XAUUSD` to appear in the dashboard. |
| `Type` | string | Expected values like `BUY` or `SELL`. |
| `Status` | string | Expected values like `OPEN`, `ACTIVE`, or `CLOSED`. |
| `Price` | number or numeric string | Used for the latest price and chart. |
| `SL` | number or numeric string | Used for risk/reward insight. |
| `TP` | number or numeric string | Used for risk/reward insight. |
| `Profit` | number or numeric string | Used for net result. |
| `Loss` | number or numeric string | Used for net result. |
| `Channel` | string | Displayed as signal source context. |

The app queries:

```text
where Symbol == XAUUSD
order by Timestamp desc
limit 40
```

Firestore may ask for a composite index on `Symbol` and `Timestamp` the first
time this query runs.
