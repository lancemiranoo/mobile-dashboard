import 'package:cloud_firestore/cloud_firestore.dart';

class TradeSignal {
  const TradeSignal({
    required this.id,
    required this.timestamp,
    required this.ticket,
    required this.symbol,
    required this.type,
    required this.status,
    required this.price,
    required this.stopLoss,
    required this.takeProfit,
    required this.profit,
    required this.loss,
    required this.channel,
  });

  static const watchedSymbol = 'XAUUSD';

  final String id;
  final DateTime timestamp;
  final String ticket;
  final String symbol;
  final String type;
  final String status;
  final double price;
  final double? stopLoss;
  final double? takeProfit;
  final double? profit;
  final double? loss;
  final String channel;

  double get netResult => (profit ?? 0) - (loss ?? 0).abs();

  bool get isBuy => type.toLowerCase().contains('buy');

  bool get isSell => type.toLowerCase().contains('sell');

  bool get isOpen {
    final normalized = status.toLowerCase();
    return normalized.contains('open') ||
        normalized.contains('active') ||
        normalized.contains('running');
  }

  double? get riskRewardRatio {
    if (stopLoss == null || takeProfit == null || price <= 0) {
      return null;
    }

    final stopDistance = isSell ? stopLoss! - price : price - stopLoss!;
    final targetDistance = isSell ? price - takeProfit! : takeProfit! - price;

    if (stopDistance <= 0 || targetDistance <= 0) {
      return null;
    }

    return targetDistance / stopDistance;
  }

  factory TradeSignal.fromSnapshot(
    QueryDocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return TradeSignal.fromMap(snapshot.id, snapshot.data());
  }

  factory TradeSignal.fromMap(String id, Map<String, dynamic> data) {
    return TradeSignal(
      id: id,
      timestamp:
          _date(data, 'Timestamp') ?? DateTime.fromMillisecondsSinceEpoch(0),
      ticket: _string(data, 'Ticket'),
      symbol: _string(data, 'Symbol'),
      type: _string(data, 'Type'),
      status: _string(data, 'Status'),
      price: _double(data, 'Price') ?? 0,
      stopLoss: _double(data, 'SL'),
      takeProfit: _double(data, 'TP'),
      profit: _double(data, 'Profit'),
      loss: _double(data, 'Loss'),
      channel: _string(data, 'Channel'),
    );
  }

  static String _string(Map<String, dynamic> data, String key) {
    final value = data[key] ?? data[key.toLowerCase()];
    return value?.toString().trim() ?? '';
  }

  static double? _double(Map<String, dynamic> data, String key) {
    final value = data[key] ?? data[key.toLowerCase()];
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }

    final cleaned = value
        .toString()
        .replaceAll(',', '')
        .replaceAll('\$', '')
        .trim();
    if (cleaned.isEmpty || cleaned == '-') {
      return null;
    }

    return double.tryParse(cleaned);
  }

  static DateTime? _date(Map<String, dynamic> data, String key) {
    final value = data[key] ?? data[key.toLowerCase()];
    if (value == null) {
      return null;
    }
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    return DateTime.tryParse(value.toString());
  }
}
