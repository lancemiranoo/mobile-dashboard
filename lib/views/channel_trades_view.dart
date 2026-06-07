import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controllers/channel_trades_controller.dart';
import '../models/trade_model.dart';

class ChannelTradesView extends ConsumerWidget {
  final String channel;

  const ChannelTradesView({super.key, required this.channel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tradesAsync = ref.watch(channelTradesProvider(channel));

    return tradesAsync.when(
      loading: () => _ChannelTradesSkeleton(channel: channel),
      error: (error, stackTrace) => _ChannelTradesError(error: error),
      data: (trades) => LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= 680;
          final horizontalPadding = isTablet ? 28.0 : 16.0;
          final closedTrades = trades
              .where((trade) => trade.status == TradeStatus.closed)
              .length;
          final wins = trades
              .where(
                (trade) =>
                    trade.status == TradeStatus.closed && trade.netResult > 0,
              )
              .length;

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
                    _BackButtonHeader(channel: channel),
                    const SizedBox(height: 16),
                    _ChannelSummary(
                      totalTrades: trades.length,
                      closedTrades: closedTrades,
                      wins: wins,
                      netResult: trades.fold<double>(
                        0,
                        (sum, trade) => sum + trade.netResult,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ChannelTradesPanel(trades: trades, isTablet: isTablet),
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

class _BackButtonHeader extends StatelessWidget {
  final String channel;

  const _BackButtonHeader({required this.channel});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.filledTonal(
          onPressed: () => context.go('/leaderboard'),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back to leaderboard',
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                channel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Trades made by this channel',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChannelSummary extends StatelessWidget {
  final int totalTrades;
  final int closedTrades;
  final int wins;
  final double netResult;

  const _ChannelSummary({
    required this.totalTrades,
    required this.closedTrades,
    required this.wins,
    required this.netResult,
  });

  @override
  Widget build(BuildContext context) {
    final winRate = closedTrades == 0 ? 0 : wins / closedTrades * 100;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _SummaryPill(label: '$totalTrades trades', color: Colors.indigo),
        _SummaryPill(
          label: '${winRate.toStringAsFixed(0)}% win rate',
          color: Colors.teal,
        ),
        _SummaryPill(
          label: '${_formatCurrency(netResult)} net',
          color: netResult >= 0 ? Colors.teal : Colors.deepOrange,
        ),
      ],
    );
  }
}

class _ChannelTradesPanel extends StatefulWidget {
  final List<TradeModel> trades;
  final bool isTablet;

  const _ChannelTradesPanel({required this.trades, required this.isTablet});

  @override
  State<_ChannelTradesPanel> createState() => _ChannelTradesPanelState();
}

class _ChannelTradesPanelState extends State<_ChannelTradesPanel> {
  static const _pageSize = 5;

  int _pageIndex = 0;

  int get _pageCount {
    if (widget.trades.isEmpty) {
      return 1;
    }

    return (widget.trades.length / _pageSize).ceil();
  }

  @override
  void didUpdateWidget(covariant _ChannelTradesPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_pageIndex >= _pageCount) {
      _pageIndex = _pageCount - 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final startIndex = widget.trades.isEmpty ? 0 : _pageIndex * _pageSize;
    final endIndex = math.min(startIndex + _pageSize, widget.trades.length);
    final visibleTrades = widget.trades.sublist(startIndex, endIndex);

    return _Panel(
      padding: EdgeInsets.zero,
      child: widget.trades.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(18),
              child: Center(child: Text('No trades found for this channel.')),
            )
          : Column(
              children: [
                if (widget.isTablet)
                  _ChannelTradesTable(trades: visibleTrades)
                else
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        for (
                          var index = 0;
                          index < visibleTrades.length;
                          index++
                        )
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: index == visibleTrades.length - 1
                                  ? 0
                                  : 10,
                            ),
                            child: _ChannelTradeCard(
                              trade: visibleTrades[index],
                            ),
                          ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: _PaginationControls(
                    pageIndex: _pageIndex,
                    pageCount: _pageCount,
                    start: startIndex + 1,
                    end: endIndex,
                    total: widget.trades.length,
                    onPrevious: _pageIndex == 0
                        ? null
                        : () {
                            setState(() {
                              _pageIndex--;
                            });
                          },
                    onNext: _pageIndex >= _pageCount - 1
                        ? null
                        : () {
                            setState(() {
                              _pageIndex++;
                            });
                          },
                  ),
                ),
              ],
            ),
    );
  }
}

class _PaginationControls extends StatelessWidget {
  final int pageIndex;
  final int pageCount;
  final int start;
  final int end;
  final int total;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const _PaginationControls({
    required this.pageIndex,
    required this.pageCount,
    required this.start,
    required this.end,
    required this.total,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            '$start-$end of $total - Page ${pageIndex + 1} of $pageCount',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        IconButton.filledTonal(
          tooltip: 'Previous page',
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          tooltip: 'Next page',
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

class _ChannelTradesTable extends StatelessWidget {
  final List<TradeModel> trades;

  const _ChannelTradesTable({required this.trades});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingTextStyle: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
        columns: const [
          DataColumn(label: Text('Ticket')),
          DataColumn(label: Text('Symbol')),
          DataColumn(label: Text('Side')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Price'), numeric: true),
          DataColumn(label: Text('TP / SL'), numeric: true),
          DataColumn(label: Text('Result'), numeric: true),
        ],
        rows: trades.map((trade) {
          return DataRow(
            cells: [
              DataCell(Text(trade.ticket)),
              DataCell(Text(trade.symbol)),
              DataCell(_DirectionPill(direction: trade.direction)),
              DataCell(
                _StatusPill(
                  label: trade.statusLabel.isEmpty
                      ? _statusLabel(trade.status)
                      : trade.statusLabel,
                  color: _statusColor(trade.status),
                ),
              ),
              DataCell(Text(_formatPrice(trade.price))),
              DataCell(
                Text(
                  '${_formatPrice(trade.takeProfit)} / ${_formatPrice(trade.stopLoss)}',
                ),
              ),
              DataCell(_ProfitLossText(trade: trade)),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _ChannelTradeCard extends StatelessWidget {
  final TradeModel trade;

  const _ChannelTradeCard({required this.trade});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final symbolPrefix = trade.symbol.substring(
      0,
      math.min(2, trade.symbol.length),
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  symbolPrefix,
                  style: TextStyle(
                    color: colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trade.symbol,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      trade.ticket,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              _ProfitLossText(trade: trade),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _DirectionPill(direction: trade.direction),
              _StatusPill(
                label: trade.statusLabel.isEmpty
                    ? _statusLabel(trade.status)
                    : trade.statusLabel,
                color: _statusColor(trade.status),
              ),
              _StatusPill(
                label: 'TP ${_formatPrice(trade.takeProfit)}',
                color: Colors.blueGrey,
              ),
              _StatusPill(
                label: 'SL ${_formatPrice(trade.stopLoss)}',
                color: Colors.indigo,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChannelTradesError extends StatelessWidget {
  final Object error;

  const _ChannelTradesError({required this.error});

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
                'Unable to load channel trades',
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

class _ChannelTradesSkeleton extends StatelessWidget {
  final String channel;

  const _ChannelTradesSkeleton({required this.channel});

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
              Row(
                children: [
                  const _SkeletonBox(width: 44, height: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        _SkeletonBox(width: 180, height: 24),
                        SizedBox(height: 8),
                        _SkeletonBox(width: 210, height: 14),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const _SkeletonBox(width: 260, height: 32),
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

class _DirectionPill extends StatelessWidget {
  final TradeDirection direction;

  const _DirectionPill({required this.direction});

  @override
  Widget build(BuildContext context) {
    final isBuy = direction == TradeDirection.buy;

    return _StatusPill(
      label: isBuy ? 'Buy' : 'Sell',
      color: isBuy ? Colors.teal : Colors.deepOrange,
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

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

class _SummaryPill extends StatelessWidget {
  final String label;
  final Color color;

  const _SummaryPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return _StatusPill(label: label, color: color);
  }
}

class _ProfitLossText extends StatelessWidget {
  final TradeModel trade;

  const _ProfitLossText({required this.trade});

  @override
  Widget build(BuildContext context) {
    final isPositive = trade.netResult >= 0;
    final color = isPositive ? Colors.teal : Colors.deepOrange;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatCurrency(trade.netResult),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          trade.result.isEmpty ? (isPositive ? 'WIN' : 'LOSS') : trade.result,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
        ),
      ],
    );
  }
}

String _statusLabel(TradeStatus status) {
  switch (status) {
    case TradeStatus.open:
      return 'Open';
    case TradeStatus.closed:
      return 'Closed';
    case TradeStatus.pending:
      return 'Pending';
  }
}

Color _statusColor(TradeStatus status) {
  switch (status) {
    case TradeStatus.open:
      return Colors.teal;
    case TradeStatus.closed:
      return Colors.blueGrey;
    case TradeStatus.pending:
      return Colors.amber.shade800;
  }
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

String _formatPrice(double value) {
  if (value == 0) {
    return '0';
  }

  return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
}
