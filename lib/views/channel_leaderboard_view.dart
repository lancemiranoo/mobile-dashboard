import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controllers/channel_leaderboard_controller.dart';
import '../models/channel_leaderboard_entry.dart';

class ChannelLeaderboardView extends ConsumerWidget {
  const ChannelLeaderboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(channelLeaderboardProvider);

    return leaderboardAsync.when(
      loading: () => const _LeaderboardSkeleton(),
      error: (error, stackTrace) => _LeaderboardError(error: error),
      data: (entries) => LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= 680;
          final horizontalPadding = isTablet ? 28.0 : 16.0;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              16,
              horizontalPadding,
              28,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Channel Leaderboard',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'All channels ranked by win rate.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _LeaderboardPanel(entries: entries, isTablet: isTablet),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LeaderboardPanel extends StatelessWidget {
  final List<ChannelLeaderboardEntry> entries;
  final bool isTablet;

  const _LeaderboardPanel({required this.entries, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: EdgeInsets.zero,
      child: entries.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(18),
              child: Center(child: Text('No channel data yet.')),
            )
          : isTablet
          ? _LeaderboardTable(entries: entries)
          : Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  for (var index = 0; index < entries.length; index++)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: index == entries.length - 1 ? 0 : 10,
                      ),
                      child: _LeaderboardCard(
                        rank: index + 1,
                        entry: entries[index],
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _LeaderboardTable extends StatelessWidget {
  final List<ChannelLeaderboardEntry> entries;

  const _LeaderboardTable({required this.entries});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingTextStyle: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
        columns: const [
          DataColumn(label: Text('Rank')),
          DataColumn(label: Text('Channel')),
          DataColumn(label: Text('Win Rate'), numeric: true),
          DataColumn(label: Text('Wins'), numeric: true),
          DataColumn(label: Text('Closed'), numeric: true),
          DataColumn(label: Text('Net'), numeric: true),
        ],
        rows: [
          for (var index = 0; index < entries.length; index++)
            DataRow(
              cells: [
                DataCell(Text('#${index + 1}')),
                DataCell(
                  _ChannelName(entry: entries[index], showHint: true),
                  onTap: () => _openChannelTrades(context, entries[index]),
                ),
                DataCell(Text(_formatPercent(entries[index].winRate))),
                DataCell(Text(entries[index].wins.toString())),
                DataCell(Text(entries[index].closedTrades.toString())),
                DataCell(_NetResultText(value: entries[index].netResult)),
              ],
            ),
        ],
      ),
    );
  }
}

class _LeaderboardCard extends StatelessWidget {
  final int rank;
  final ChannelLeaderboardEntry entry;

  const _LeaderboardCard({required this.rank, required this.entry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _openChannelTrades(context, entry),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _RankBadge(rank: rank),
                  const SizedBox(width: 12),
                  Expanded(child: _ChannelName(entry: entry, showHint: true)),
                  _NetResultText(value: entry.netResult),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StatPill(
                    label: 'Win Rate ${_formatPercent(entry.winRate)}',
                    color: Colors.teal,
                  ),
                  _StatPill(
                    label: '${entry.wins}W / ${entry.losses}L',
                    color: Colors.blueGrey,
                  ),
                  _StatPill(
                    label: '${entry.totalTrades} trades',
                    color: Colors.indigo,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChannelName extends StatelessWidget {
  final ChannelLeaderboardEntry entry;
  final bool showHint;

  const _ChannelName({required this.entry, this.showHint = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          entry.channel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        Text(
          showHint
              ? 'Tap to view ${entry.totalTrades} trades'
              : '${entry.closedTrades} closed of ${entry.totalTrades}',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;

  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '#$rank',
        style: TextStyle(
          color: colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _NetResultText extends StatelessWidget {
  final double value;

  const _NetResultText({required this.value});

  @override
  Widget build(BuildContext context) {
    final isPositive = value >= 0;
    final color = isPositive ? Colors.teal : Colors.deepOrange;

    return Text(
      _formatCurrency(value),
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: color,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _LeaderboardError extends StatelessWidget {
  final Object error;

  const _LeaderboardError({required this.error});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _Panel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded, size: 42, color: colorScheme.error),
              const SizedBox(height: 12),
              Text(
                'Unable to load leaderboard',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeaderboardSkeleton extends StatelessWidget {
  const _LeaderboardSkeleton();

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 680;
    final horizontalPadding = isTablet ? 28.0 : 16.0;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        16,
        horizontalPadding,
        28,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SkeletonBox(width: 230, height: 30),
              const SizedBox(height: 8),
              const _SkeletonBox(width: 190, height: 14),
              const SizedBox(height: 16),
              _Panel(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: List.generate(
                    isTablet ? 8 : 5,
                    (index) => const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: _SkeletonBox(height: 58),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _Panel({required this.child, this.padding = const EdgeInsets.all(18)});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: child,
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;

  const _SkeletonBox({this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String _formatPercent(double value) {
  return '${value.toStringAsFixed(0)}%';
}

String _formatCurrency(double value) {
  final prefix = value < 0 ? '-\$' : '\$';
  final absoluteValue = value.abs();

  if (absoluteValue >= 1000000) {
    return '$prefix${(absoluteValue / 1000000).toStringAsFixed(2)}M';
  }

  if (absoluteValue >= 1000) {
    return '$prefix${(absoluteValue / 1000).toStringAsFixed(1)}K';
  }

  return '$prefix${absoluteValue.toStringAsFixed(2)}';
}

void _openChannelTrades(BuildContext context, ChannelLeaderboardEntry entry) {
  context.push('/channel-trades?channel=${Uri.encodeComponent(entry.channel)}');
}
