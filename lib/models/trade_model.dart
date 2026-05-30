import 'package:cloud_firestore/cloud_firestore.dart';

enum TradeStatus { open, closed, pending }

enum TradeDirection { buy, sell }

class TradeModel {
  final String id;
  final String channel;
  final double loss;
  final double price;
  final double profit;
  final String result;
  final double stopLoss;
  final String statusLabel;
  final String symbol;
  final String ticket;
  final DateTime? timestamp;
  final double takeProfit;
  final TradeDirection direction;
  final DateTime? uploadedAt;

  const TradeModel({
    required this.id,
    required this.channel,
    required this.loss,
    required this.price,
    required this.profit,
    required this.result,
    required this.stopLoss,
    required this.statusLabel,
    required this.symbol,
    required this.ticket,
    required this.timestamp,
    required this.takeProfit,
    required this.direction,
    required this.uploadedAt,
  });

  factory TradeModel.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    return TradeModel(
      id: doc.id,
      channel: _asString(data['channel']),
      loss: _asDouble(data['loss']),
      price: _asDouble(data['price']),
      profit: _asDouble(data['profit']),
      result: _asString(data['result']),
      stopLoss: _asDouble(data['sl']),
      statusLabel: _asString(data['status']),
      symbol: _asString(data['symbol']),
      ticket: _asString(data['ticket'], fallback: doc.id),
      timestamp: _asDateTime(data['timestamp']),
      takeProfit: _asDouble(data['tp']),
      direction: _asDirection(data['type']),
      uploadedAt: _asDateTime(data['uploadedAt']),
    );
  }

  TradeStatus get status {
    final normalizedStatus = statusLabel.toLowerCase();

    if (normalizedStatus.contains('closed')) {
      return TradeStatus.closed;
    }

    if (normalizedStatus.contains('pending')) {
      return TradeStatus.pending;
    }

    return TradeStatus.open;
  }

  double get netResult => profit - loss;

  double get profitLossPercent {
    if (price == 0) {
      return 0;
    }

    return netResult / price * 100;
  }
}

String _asString(dynamic value, {String fallback = ''}) {
  if (value == null) {
    return fallback;
  }

  return value.toString();
}

double _asDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }

  if (value is String) {
    return double.tryParse(value) ?? 0;
  }

  return 0;
}

DateTime? _asDateTime(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }

  if (value is DateTime) {
    return value;
  }

  if (value is String) {
    return DateTime.tryParse(value);
  }

  return null;
}

TradeDirection _asDirection(dynamic value) {
  return _asString(value).toLowerCase() == 'sell'
      ? TradeDirection.sell
      : TradeDirection.buy;
}
