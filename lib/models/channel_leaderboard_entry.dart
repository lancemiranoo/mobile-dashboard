class ChannelLeaderboardEntry {
  final String channel;
  final int totalTrades;
  final int closedTrades;
  final int wins;
  final double netResult;

  const ChannelLeaderboardEntry({
    required this.channel,
    required this.totalTrades,
    required this.closedTrades,
    required this.wins,
    required this.netResult,
  });

  int get losses => closedTrades - wins;

  double get winRate => closedTrades == 0 ? 0 : wins / closedTrades * 100;
}
