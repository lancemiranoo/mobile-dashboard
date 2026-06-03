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

    if (user == null) {
      return const SizedBox.shrink();
    }

    final displayName = user.displayName.trim().isEmpty
        ? user.email
        : user.displayName.trim();

    return tradesAsync.when(
      loading: () => const _DashboardSkeleton(),
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
                      displayName: displayName,
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
  final List<ChannelWinRate> channelWinRates;

  const TradeAnalytics({
    required this.totalTrades,
    required this.openTrades,
    required this.closedTrades,
    required this.totalProfitLoss,
    required this.weeklyProfitLoss,
    required this.dailyProfitLoss,
    required this.winRate,
    required this.channelWinRates,
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

    return TradeAnalytics(
      totalTrades: trades.length,
      openTrades: statusCounts[TradeStatus.open] ?? 0,
      closedTrades: closedTrades.length,
      totalProfitLoss: trades.fold(0, (sum, trade) => sum + trade.netResult),
      weeklyProfitLoss: _sumTradesSince(trades, weekStart),
      dailyProfitLoss: _sumTradesSince(trades, today),
      winRate: closedTrades.isEmpty ? 0 : winners / closedTrades.length * 100,
      channelWinRates: _buildChannelWinRates(closedTrades),
    );
  }
}

class ChannelWinRate {
  final String channel;
  final int wins;
  final int total;

  const ChannelWinRate({
    required this.channel,
    required this.wins,
    required this.total,
  });

  double get rate => total == 0 ? 0 : wins / total * 100;
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

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

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
              const _SkeletonBox(height: 74),
              const SizedBox(height: 20),
              _Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _SkeletonBox(width: 170, height: 18),
                    SizedBox(height: 22),
                    _SkeletonBox(height: 220),
                    SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(child: _SkeletonBox(height: 42)),
                        SizedBox(width: 12),
                        Expanded(child: _SkeletonBox(height: 42)),
                        SizedBox(width: 12),
                        Expanded(child: _SkeletonBox(height: 42)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GridView.builder(
                itemCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isTablet ? 4 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: isTablet ? 1.45 : 1.08,
                ),
                itemBuilder: (context, index) {
                  return const _Panel(
                    padding: EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _SkeletonBox(width: 36, height: 36),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SkeletonBox(width: 84, height: 12),
                            SizedBox(height: 8),
                            _SkeletonBox(width: 110, height: 22),
                            SizedBox(height: 8),
                            _SkeletonBox(width: 96, height: 10),
                          ],
                        ),
                      ],
                    ),
                  );
                },
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
            title: 'Top 5 Channel Win Rate',
            action: _StatusPill(
              label: '${analytics.closedTrades} closed',
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            width: double.infinity,
            child: CustomPaint(
              painter: _ColumnChartPainter(
                values: analytics.channelWinRates,
                barColor: colorScheme.primary,
                gridColor: colorScheme.outlineVariant.withValues(alpha: 0.7),
                labelColor: colorScheme.onSurfaceVariant,
                valueColor: colorScheme.onSurface,
              ),
            ),
          ),
          // const SizedBox(height: 18),
          // Row(
          //   children: [
          // Expanded(
          //   child: _InlineStat(
          //     label: 'Trades',
          //     value: analytics.totalTrades.toString(),
          //   ),
          // ),
          // Expanded(
          //   child: _InlineStat(
          //     label: 'Open',
          //     value: analytics.openTrades.toString(),
          //   ),
          // ),
          // Expanded(
          //   child: _InlineStat(
          //     label: 'Closed',
          //     value: analytics.closedTrades.toString(),
          //   ),
          // ),
          //   ],
          // ),
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

// class _InlineStat extends StatelessWidget {
//   final String label;
//   final String value;

//   const _InlineStat({required this.label, required this.value});

//   @override
//   Widget build(BuildContext context) {
//     final colorScheme = Theme.of(context).colorScheme;

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: Theme.of(
//             context,
//           ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           value,
//           style: Theme.of(
//             context,
//           ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
//         ),
//       ],
//     );
//   }
// }

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

class _ColumnChartPainter extends CustomPainter {
  final List<ChannelWinRate> values;
  final Color barColor;
  final Color gridColor;
  final Color labelColor;
  final Color valueColor;

  const _ColumnChartPainter({
    required this.values,
    required this.barColor,
    required this.gridColor,
    required this.labelColor,
    required this.valueColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final chartRect = Rect.fromLTWH(0, 20, size.width, size.height - 58);
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

    if (values.isEmpty) {
      _drawCenteredText(
        canvas,
        chartRect.center,
        'No closed trades yet',
        labelColor,
        13,
        FontWeight.w700,
      );
      return;
    }

    final visibleValues = values.take(5).toList();
    final slotWidth = chartRect.width / visibleValues.length;
    final barPaint = Paint()..color = barColor;
    final barBackgroundPaint = Paint()
      ..color = barColor.withValues(alpha: 0.08);

    for (var index = 0; index < visibleValues.length; index++) {
      final item = visibleValues[index];
      final barWidth = math.min(42.0, slotWidth * 0.46);
      final centerX = chartRect.left + slotWidth * index + slotWidth / 2;
      final barLeft = centerX - barWidth / 2;
      final barHeight = chartRect.height * (item.rate / 100).clamp(0, 1);
      final fullBarRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(barLeft, chartRect.top, barWidth, chartRect.height),
        const Radius.circular(8),
      );
      final valueBarRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          barLeft,
          chartRect.bottom - barHeight,
          barWidth,
          barHeight,
        ),
        const Radius.circular(8),
      );

      canvas.drawRRect(fullBarRect, barBackgroundPaint);
      canvas.drawRRect(valueBarRect, barPaint);
      _drawCenteredText(
        canvas,
        Offset(centerX, chartRect.top - 10),
        '${item.rate.toStringAsFixed(0)}%',
        valueColor,
        12,
        FontWeight.w800,
      );
      _drawCenteredText(
        canvas,
        Offset(centerX, chartRect.bottom + 16),
        _compactChannelLabel(item.channel),
        labelColor,
        11,
        FontWeight.w700,
      );
      _drawCenteredText(
        canvas,
        Offset(centerX, chartRect.bottom + 32),
        '${item.wins}/${item.total}',
        labelColor,
        10,
        FontWeight.w600,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ColumnChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.barColor != barColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.labelColor != labelColor ||
        oldDelegate.valueColor != valueColor;
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

List<ChannelWinRate> _buildChannelWinRates(List<TradeModel> closedTrades) {
  final totalsByChannel = <String, int>{};
  final winsByChannel = <String, int>{};

  for (final trade in closedTrades) {
    final channel = trade.channel.trim().isEmpty ? 'Unknown' : trade.channel;
    final isWin =
        trade.result.toLowerCase().contains('win') || trade.netResult > 0;

    totalsByChannel.update(channel, (value) => value + 1, ifAbsent: () => 1);
    if (isWin) {
      winsByChannel.update(channel, (value) => value + 1, ifAbsent: () => 1);
    }
  }

  final winRates =
      totalsByChannel.entries.map((entry) {
        return ChannelWinRate(
          channel: entry.key,
          wins: winsByChannel[entry.key] ?? 0,
          total: entry.value,
        );
      }).toList()..sort((a, b) {
        final rateComparison = b.rate.compareTo(a.rate);
        if (rateComparison != 0) {
          return rateComparison;
        }

        return b.total.compareTo(a.total);
      });

  return winRates;
}

String _compactChannelLabel(String label) {
  final normalized = label.trim();
  if (normalized.length <= 10) {
    return normalized;
  }

  return '${normalized.substring(0, 9)}…';
}

void _drawCenteredText(
  Canvas canvas,
  Offset center,
  String text,
  Color color,
  double fontSize,
  FontWeight fontWeight,
) {
  final textPainter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
      ),
    ),
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
  )..layout();

  textPainter.paint(
    canvas,
    Offset(
      center.dx - textPainter.width / 2,
      center.dy - textPainter.height / 2,
    ),
  );
}
