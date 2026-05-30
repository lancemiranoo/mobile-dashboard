import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/trade_model.dart';
import '../repositories/trade_repository.dart';

class TradeHistoryView extends ConsumerWidget {
  const TradeHistoryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tradesAsync = ref.watch(tradeCollectionProvider);

    return tradesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _HistoryError(error: error),
      data: (trades) => LayoutBuilder(
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
                      'Trade History',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 16),
                    _TradeCollectionPanel(trades: trades, isTablet: isTablet),
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

class _HistoryError extends StatelessWidget {
  final Object error;

  const _HistoryError({required this.error});

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
                'Unable to load history',
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

class _TradeCollectionPanel extends StatefulWidget {
  final List<TradeModel> trades;
  final bool isTablet;

  const _TradeCollectionPanel({required this.trades, required this.isTablet});

  @override
  State<_TradeCollectionPanel> createState() => _TradeCollectionPanelState();
}

class _TradeCollectionPanelState extends State<_TradeCollectionPanel> {
  int _pageIndex = 0;

  int get _pageSize => widget.isTablet ? 8 : 5;

  int get _pageCount {
    if (widget.trades.isEmpty) {
      return 1;
    }

    return (widget.trades.length / _pageSize).ceil();
  }

  @override
  void didUpdateWidget(covariant _TradeCollectionPanel oldWidget) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
            child: _PanelHeader(
              title: 'Trade Collection',
              action: _PaginationSummary(
                start: startIndex + (widget.trades.isEmpty ? 0 : 1),
                end: endIndex,
                total: widget.trades.length,
              ),
            ),
          ),
          if (widget.isTablet)
            _TradeTable(trades: visibleTrades)
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Column(
                children: visibleTrades.map((trade) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _TradeListTile(trade: trade),
                  );
                }).toList(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: _PaginationControls(
              pageIndex: _pageIndex,
              pageCount: _pageCount,
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

class _TradeTable extends StatelessWidget {
  final List<TradeModel> trades;

  const _TradeTable({required this.trades});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingTextStyle: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
        columns: const [
          DataColumn(label: Text('Trade')),
          DataColumn(label: Text('Side')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Price'), numeric: true),
          DataColumn(label: Text('TP / SL'), numeric: true),
          DataColumn(label: Text('Result'), numeric: true),
        ],
        rows: trades.map((trade) {
          return DataRow(
            cells: [
              DataCell(_TradeIdentity(trade: trade)),
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

class _PaginationSummary extends StatelessWidget {
  final int start;
  final int end;
  final int total;

  const _PaginationSummary({
    required this.start,
    required this.end,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Text(
      '$start-$end of $total',
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _PaginationControls extends StatelessWidget {
  final int pageIndex;
  final int pageCount;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const _PaginationControls({
    required this.pageIndex,
    required this.pageCount,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Text(
          'Page ${pageIndex + 1} of $pageCount',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const Spacer(),
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

class _TradeListTile extends StatelessWidget {
  final TradeModel trade;

  const _TradeListTile({required this.trade});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
              Expanded(child: _TradeIdentity(trade: trade)),
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

class _TradeIdentity extends StatelessWidget {
  final TradeModel trade;

  const _TradeIdentity({required this.trade});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
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
            trade.symbol.substring(0, math.min(2, trade.symbol.length)),
            style: TextStyle(
              color: colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              trade.channel,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              '${trade.ticket} - ${trade.symbol}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
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

class _PanelHeader extends StatelessWidget {
  final String title;
  final Widget? action;

  const _PanelHeader({required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        if (action != null) action!,
      ],
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
