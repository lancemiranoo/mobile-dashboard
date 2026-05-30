import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controllers/auth_controller.dart';
import '../models/trade_model.dart';
import '../repositories/trade_repository.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.value;
    final tradesAsync = ref.watch(tradeCollectionProvider);

    ref.listen(authControllerProvider, (previous, next) {
      if (!next.isLoading && !next.hasError && next.value == null) {
        context.go('/login');
      }
    });

    return tradesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _DashboardError(error: error),
      data: (trades) => LayoutBuilder(
        builder: (context, constraints) {
          final analytics = TradeAnalytics.fromTrades(trades);
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
                    _DashboardHeader(
                      displayName: user?.displayName ?? 'Trader',
                      onLogout: () {
                        ref.read(authControllerProvider.notifier).logout();
                      },
                    ),
                    const SizedBox(height: 20),
                    _PerformancePanel(analytics: analytics),
                    const SizedBox(height: 20),
                    _MetricGrid(analytics: analytics, isTablet: isTablet),
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

class TradeAnalytics {
  final int totalTrades;
  final int openTrades;
  final int closedTrades;
  final double totalProfitLoss;
  final double weeklyProfitLoss;
  final double dailyProfitLoss;
  final double winRate;
  final List<double> equityCurve;

  const TradeAnalytics({
    required this.totalTrades,
    required this.openTrades,
    required this.closedTrades,
    required this.totalProfitLoss,
    required this.weeklyProfitLoss,
    required this.dailyProfitLoss,
    required this.winRate,
    required this.equityCurve,
  });

  factory TradeAnalytics.fromTrades(List<TradeModel> trades) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final closedTrades = trades
        .where((trade) => trade.status == TradeStatus.closed)
        .toList();
    final winners = closedTrades.where((trade) => trade.netResult > 0).length;
    final statusCounts = {
      for (final status in TradeStatus.values)
        status: trades.where((trade) => trade.status == status).length,
    };

    final sortedTrades = [...trades]
      ..sort(
        (a, b) => (a.timestamp ?? a.uploadedAt ?? DateTime(0)).compareTo(
          b.timestamp ?? b.uploadedAt ?? DateTime(0),
        ),
      );
    var runningProfitLoss = 0.0;
    final equityCurve = <double>[0];

    for (final trade in sortedTrades) {
      runningProfitLoss += trade.netResult;
      equityCurve.add(runningProfitLoss);
    }

    return TradeAnalytics(
      totalTrades: trades.length,
      openTrades: statusCounts[TradeStatus.open] ?? 0,
      closedTrades: closedTrades.length,
      totalProfitLoss: trades.fold(0, (sum, trade) => sum + trade.netResult),
      weeklyProfitLoss: _sumTradesSince(trades, weekStart),
      dailyProfitLoss: _sumTradesSince(trades, today),
      winRate: closedTrades.isEmpty ? 0 : winners / closedTrades.length * 100,
      equityCurve: equityCurve,
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final String displayName;
  final VoidCallback onLogout;

  const _DashboardHeader({required this.displayName, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: colorScheme.primary,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BOT DASHBOARD',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimary.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Good day, $displayName!',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleLarge?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Tooltip(
            message: 'Log out',
            child: Material(
              color: colorScheme.tertiaryContainer,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onLogout,
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    Icons.logout_rounded,
                    color: colorScheme.onTertiaryContainer,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  final Object error;

  const _DashboardError({required this.error});

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
                'Unable to load trades',
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

class _MetricGrid extends StatelessWidget {
  final TradeAnalytics analytics;
  final bool isTablet;

  const _MetricGrid({required this.analytics, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _MetricData(
        label: 'Net',
        value: _formatCurrency(analytics.totalProfitLoss),
        helper: analytics.totalProfitLoss >= 0
            ? 'Net positive'
            : 'Needs review',
        icon: Icons.trending_up_rounded,
        positive: analytics.totalProfitLoss >= 0,
      ),
      _MetricData(
        label: 'Weekly',
        value: _formatCurrency(analytics.weeklyProfitLoss),
        helper: 'This week result',
        icon: Icons.calendar_view_week_rounded,
        positive: analytics.weeklyProfitLoss >= 0,
      ),
      _MetricData(
        label: 'Win Rate',
        value: '${analytics.winRate.toStringAsFixed(0)}%',
        helper: '${analytics.closedTrades} closed trades',
        icon: Icons.emoji_events_rounded,
        positive: analytics.winRate >= 50,
      ),
      _MetricData(
        label: 'Daily',
        value: _formatCurrency(analytics.dailyProfitLoss),
        helper: 'Today result',
        icon: Icons.today_rounded,
        positive: analytics.dailyProfitLoss >= 0,
      ),
    ];

    return GridView.builder(
      itemCount: metrics.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTablet ? 4 : 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: isTablet ? 1.45 : 1.08,
      ),
      itemBuilder: (context, index) {
        return _MetricCard(data: metrics[index]);
      },
    );
  }
}

class _MetricData {
  final String label;
  final String value;
  final String helper;
  final IconData icon;
  final bool positive;

  const _MetricData({
    required this.label,
    required this.value,
    required this.helper,
    required this.icon,
    required this.positive,
  });
}

class _MetricCard extends StatelessWidget {
  final _MetricData data;

  const _MetricCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = data.positive ? Colors.teal : Colors.deepOrange;

    return _Panel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(data.icon, color: accent, size: 20),
              ),
              const Spacer(),
              Icon(
                data.positive
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                color: accent,
                size: 18,
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  data.value,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                data.helper,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PerformancePanel extends StatelessWidget {
  final TradeAnalytics analytics;

  const _PerformancePanel({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelHeader(
            title: 'Performance Curve',
            action: _StatusPill(
              label: analytics.totalProfitLoss >= 0 ? 'Profitable' : 'Drawdown',
              color: analytics.totalProfitLoss >= 0
                  ? Colors.teal
                  : Colors.deepOrange,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 190,
            width: double.infinity,
            child: CustomPaint(
              painter: _LineChartPainter(
                values: analytics.equityCurve,
                lineColor: analytics.totalProfitLoss >= 0
                    ? Colors.teal
                    : Colors.deepOrange,
                gridColor: colorScheme.outlineVariant.withValues(alpha: 0.7),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _InlineStat(
                  label: 'Trades',
                  value: analytics.totalTrades.toString(),
                ),
              ),
              Expanded(
                child: _InlineStat(
                  label: 'Open',
                  value: analytics.openTrades.toString(),
                ),
              ),
              Expanded(
                child: _InlineStat(
                  label: 'Closed',
                  value: analytics.closedTrades.toString(),
                ),
              ),
            ],
          ),
        ],
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

class _InlineStat extends StatelessWidget {
  final String label;
  final String value;

  const _InlineStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
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

class _LineChartPainter extends CustomPainter {
  final List<double> values;
  final Color lineColor;
  final Color gridColor;

  const _LineChartPainter({
    required this.values,
    required this.lineColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) {
      return;
    }

    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final range = maxValue == minValue ? 1 : maxValue - minValue;
    final chartRect = Rect.fromLTWH(0, 8, size.width, size.height - 16);
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    for (var index = 0; index < 4; index++) {
      final y = chartRect.top + chartRect.height / 3 * index;
      canvas.drawLine(
        Offset(chartRect.left, y),
        Offset(chartRect.right, y),
        gridPaint,
      );
    }

    final path = Path();

    for (var index = 0; index < values.length; index++) {
      final x =
          chartRect.left + chartRect.width * (index / (values.length - 1));
      final normalized = (values[index] - minValue) / range;
      final y = chartRect.bottom - chartRect.height * normalized;
      final point = Offset(x, y);

      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    final fillPath = Path.from(path)
      ..lineTo(chartRect.right, chartRect.bottom)
      ..lineTo(chartRect.left, chartRect.bottom)
      ..close();
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: 0.24),
          lineColor.withValues(alpha: 0.02),
        ],
      ).createShader(chartRect);

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.gridColor != gridColor;
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

double _sumTradesSince(List<TradeModel> trades, DateTime startDate) {
  return trades
      .where((trade) {
        final tradeDate = trade.timestamp ?? trade.uploadedAt;
        return tradeDate != null && !tradeDate.isBefore(startDate);
      })
      .fold(0.0, (sum, trade) => sum + trade.netResult);
}
