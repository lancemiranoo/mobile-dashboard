import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/trade_model.dart';
import '../repositories/trade_repository.dart';

final channelTradesProvider = Provider.autoDispose
    .family<AsyncValue<List<TradeModel>>, String>((ref, channel) {
      final trades = ref.watch(dashboardTradeCollectionProvider);
      return trades.whenData((items) {
        final normalizedChannel = _channelKey(channel);
        final channelTrades =
            items.where((trade) {
              return _channelKey(trade.channel) == normalizedChannel;
            }).toList()..sort((a, b) {
              final left = a.uploadedAt ?? a.timestamp ?? DateTime(0);
              final right = b.uploadedAt ?? b.timestamp ?? DateTime(0);
              return right.compareTo(left);
            });

        return channelTrades;
      });
    });

String _channelKey(String value) {
  final trimmedValue = value.trim();
  return (trimmedValue.isEmpty ? 'Unknown' : trimmedValue).toLowerCase();
}
