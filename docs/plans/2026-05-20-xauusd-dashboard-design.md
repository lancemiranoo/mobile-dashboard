# XAUUSD Dashboard Design

## Product Scope

The first version is a focused gold-trading dashboard. It has a single watched
instrument, `XAUUSD`, and intentionally avoids broader forex watchlists until the
Firebase data flow is proven. Authenticated users can log in or register with
Firebase Auth, then view live Firestore trade signals filtered to gold.

## Data And Insights

The app reads the existing Firestore document shape shown by the provided image:
`Timestamp`, `Ticket`, `Symbol`, `Type`, `Status`, `Price`, `SL`, `TP`, `Profit`,
`Loss`, and `Channel`. The dashboard uses those fields to show the latest price,
current signal status, net result, active signal count, price movement, and a
risk/reward read when `SL` and `TP` are available.

## Visualization

The primary visualization is a line chart of recent XAUUSD prices ordered by
`Timestamp`. Supporting cards show latest price, status/channel, and aggregate
profit/loss. A recent-signals list preserves the operational context traders
need: ticket, type, status, price, and net result.

## Firebase Setup

Firebase config is supplied through `--dart-define` values so project-specific
keys are not committed. The trade collection path defaults to `trades` and can
be overridden with `FIRESTORE_TRADES_COLLECTION`.
