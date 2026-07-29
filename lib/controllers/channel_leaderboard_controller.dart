import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/channel_leaderboard_entry.dart';
import '../models/trade_model.dart';
import '../repositories/trade_repository.dart';

final channelLeaderboardProvider =
    Provider.autoDispose<AsyncValue<List<ChannelLeaderboardEntry>>>((ref) {
      final trades = ref.watch(dashboardTradeCollectionProvider);
      return trades.whenData(_buildLeaderboard);
    });

List<ChannelLeaderboardEntry> _buildLeaderboard(List<TradeModel> trades) {
  final totalsByChannel = <String, int>{};
  final closedByChannel = <String, int>{};
  final winsByChannel = <String, int>{};
  final netByChannel = <String, double>{};
  final labelsByChannel = <String, String>{};

  for (final trade in trades) {
    final channel = _channelKey(trade.channel);
    labelsByChannel.putIfAbsent(channel, () => _channelLabel(trade.channel));
    final isClosed = trade.status == TradeStatus.closed;
    final isWin =
        trade.result.toLowerCase().contains('win') || trade.netResult > 0;

    totalsByChannel.update(channel, (value) => value + 1, ifAbsent: () => 1);
    netByChannel.update(
      channel,
      (value) => value + trade.netResult,
      ifAbsent: () => trade.netResult,
    );

    if (isClosed) {
      closedByChannel.update(channel, (value) => value + 1, ifAbsent: () => 1);

      if (isWin) {
        winsByChannel.update(channel, (value) => value + 1, ifAbsent: () => 1);
      }
    }
  }

  final leaderboard =
      totalsByChannel.entries.map((entry) {
        return ChannelLeaderboardEntry(
          channel: labelsByChannel[entry.key] ?? entry.key,
          totalTrades: entry.value,
          closedTrades: closedByChannel[entry.key] ?? 0,
          wins: winsByChannel[entry.key] ?? 0,
          netResult: netByChannel[entry.key] ?? 0,
        );
      }).toList()..sort((a, b) {
        final rateComparison = b.winRate.compareTo(a.winRate);
        if (rateComparison != 0) {
          return rateComparison;
        }

        final totalComparison = b.closedTrades.compareTo(a.closedTrades);
        if (totalComparison != 0) {
          return totalComparison;
        }

        return b.netResult.compareTo(a.netResult);
      });

  return leaderboard;
}

String _channelLabel(String value) {
  final trimmedValue = value.trim();
  return trimmedValue.isEmpty ? 'Unknown' : trimmedValue;
}

String _channelKey(String value) {
  return _channelLabel(value).toLowerCase();
}
