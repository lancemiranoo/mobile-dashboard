import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_dashboard/features/trades/trade_signal.dart';

void main() {
  test('parses Firestore trade fields from screenshot schema', () {
    final signal = TradeSignal.fromMap('abc123', {
      'Timestamp': '2026-05-20T01:00:00Z',
      'Ticket': '991',
      'Symbol': 'XAUUSD',
      'Type': 'BUY',
      'Status': 'OPEN',
      'Price': '2385.50',
      'SL': '2375.50',
      'TP': '2405.50',
      'Profit': '12.25',
      'Loss': '0',
      'Channel': 'Gold Signals',
    });

    expect(signal.id, 'abc123');
    expect(signal.symbol, TradeSignal.watchedSymbol);
    expect(signal.price, 2385.50);
    expect(signal.stopLoss, 2375.50);
    expect(signal.takeProfit, 2405.50);
    expect(signal.netResult, 12.25);
    expect(signal.riskRewardRatio, 2);
  });
}
