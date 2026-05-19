import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../trades/trade_repository.dart';
import '../trades/trade_signal.dart';

class GoldDashboardPage extends StatelessWidget {
  const GoldDashboardPage({super.key, TradeRepository? repository})
      : _repository = repository;

  final TradeRepository? _repository;

  @override
  Widget build(BuildContext context) {
    final repository = _repository ?? TradeRepository();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5EF),
      appBar: AppBar(
        title: const Text('XAUUSD Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: StreamBuilder<List<TradeSignal>>(
        stream: repository.watchGoldSignals(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _DashboardMessage(
              icon: Icons.error_outline,
              title: 'Firestore query failed',
              message:
                  '${snapshot.error}\n\nCheck the collection path, rules, and '
                  'the composite index for Symbol and Timestamp.',
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final signals = snapshot.data!;
          if (signals.isEmpty) {
            return const _DashboardMessage(
              icon: Icons.monitor_heart_outlined,
              title: 'No XAUUSD signals yet',
              message:
                  'The dashboard is connected, but Firestore has no documents '
                  'where Symbol equals XAUUSD.',
            );
          }

          return _GoldDashboard(signals: signals);
        },
      ),
    );
  }
}

class _GoldDashboard extends StatelessWidget {
  const _GoldDashboard({required this.signals});

  final List<TradeSignal> signals;

  @override
  Widget build(BuildContext context) {
    final latest = signals.first;
    final previous = signals.length > 1 ? signals[1] : null;
    final priceDelta = previous == null ? 0 : latest.price - previous.price;
    final net = signals.fold<double>(
      0,
      (total, signal) => total + signal.netResult,
    );
    final openCount = signals.where((signal) => signal.isOpen).length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _HeroPanel(
          latest: latest,
          priceDelta: priceDelta,
          openCount: openCount,
          totalSignals: signals.length,
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 720;
            final cards = [
              _MetricCard(
                label: 'Latest price',
                value: _price(latest.price),
                detail:
                    latest.type.isEmpty ? 'Signal type unavailable' : latest.type,
                icon: Icons.show_chart,
                tone: const Color(0xFF725A20),
              ),
              _MetricCard(
                label: 'Status',
                value: latest.status.isEmpty ? 'Unknown' : latest.status,
                detail: latest.channel.isEmpty ? 'No channel' : latest.channel,
                icon: Icons.radio_button_checked,
                tone: const Color(0xFF315E4A),
              ),
              _MetricCard(
                label: 'Net result',
                value: _money(net),
                detail: '$openCount active of ${signals.length} visible signals',
                icon: net >= 0 ? Icons.trending_up : Icons.trending_down,
                tone: net >= 0
                    ? const Color(0xFF1D6B4F)
                    : const Color(0xFF9F3A35),
              ),
            ];

            if (compact) {
              return Column(
                children: cards
                    .map(
                      (card) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: card,
                      ),
                    )
                    .toList(),
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: cards
                  .map(
                    (card) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: card,
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 16),
        _InsightPanel(latest: latest, previous: previous),
        const SizedBox(height: 16),
        _ChartPanel(signals: signals),
        const SizedBox(height: 16),
        _RecentSignals(signals: signals.take(12).toList(growable: false)),
      ],
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.latest,
    required this.priceDelta,
    required this.openCount,
    required this.totalSignals,
  });

  final TradeSignal latest;
  final double priceDelta;
  final int openCount;
  final int totalSignals;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = DateFormat('MMM d, HH:mm');
    final deltaColor =
        priceDelta >= 0 ? const Color(0xFF1D6B4F) : const Color(0xFF9F3A35);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFE7C36A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.workspace_premium,
                  color: Color(0xFF181818),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      TradeSignal.watchedSymbol,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Updated ${formatter.format(latest.timestamp)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFFD5D0C5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            _price(latest.price),
            style: theme.textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _Pill(
                label:
                    '${priceDelta >= 0 ? '+' : ''}${priceDelta.toStringAsFixed(2)}',
                color: deltaColor,
              ),
              _Pill(label: '$openCount open', color: const Color(0xFF315E4A)),
              _Pill(
                label: '$totalSignals signals',
                color: const Color(0xFF725A20),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InsightPanel extends StatelessWidget {
  const _InsightPanel({required this.latest, required this.previous});

  final TradeSignal latest;
  final TradeSignal? previous;

  @override
  Widget build(BuildContext context) {
    final delta = previous == null ? null : latest.price - previous!.price;
    final direction = delta == null
        ? 'Waiting for a second XAUUSD data point.'
        : delta > 0
            ? 'Momentum is up from the previous signal.'
            : delta < 0
                ? 'Momentum is down from the previous signal.'
                : 'Price is unchanged from the previous signal.';
    final riskReward = latest.riskRewardRatio;

    return _Panel(
      title: 'Insights',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InsightRow(
            icon: Icons.auto_graph,
            title: 'Price read',
            body: direction,
          ),
          const Divider(height: 24),
          _InsightRow(
            icon: Icons.shield_outlined,
            title: 'Risk structure',
            body: riskReward == null
                ? 'SL and TP are not positioned for a valid risk/reward read.'
                : 'Current setup shows about '
                    '${riskReward.toStringAsFixed(2)}R potential.',
          ),
          const Divider(height: 24),
          _InsightRow(
            icon: Icons.fact_check_outlined,
            title: 'Execution context',
            body:
                'Ticket ${latest.ticket.isEmpty ? 'not provided' : latest.ticket}; '
                '${latest.type.isEmpty ? 'type unavailable' : latest.type}; '
                '${latest.status.isEmpty ? 'status unknown' : latest.status}.',
          ),
        ],
      ),
    );
  }
}

class _ChartPanel extends StatelessWidget {
  const _ChartPanel({required this.signals});

  final List<TradeSignal> signals;

  @override
  Widget build(BuildContext context) {
    final ordered = signals.reversed.toList(growable: false);
    final spots = <FlSpot>[
      for (var i = 0; i < ordered.length; i++)
        FlSpot(i.toDouble(), ordered[i].price),
    ];
    final prices = ordered.map((signal) => signal.price).where((price) {
      return price > 0;
    }).toList(growable: false);
    final minPrice =
        prices.isEmpty ? 0.0 : prices.reduce((a, b) => a < b ? a : b);
    final maxPrice =
        prices.isEmpty ? 1.0 : prices.reduce((a, b) => a > b ? a : b);
    final padding = ((maxPrice - minPrice) * 0.12).clamp(1.0, 20.0);

    return _Panel(
      title: 'Price Movement',
      child: SizedBox(
        height: 260,
        child: LineChart(
          LineChartData(
            minY: minPrice - padding,
            maxY: maxPrice + padding,
            gridData: FlGridData(
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => const FlLine(
                color: Color(0xFFE0DBCF),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  interval: ordered.length > 8
                      ? (ordered.length / 4).ceilToDouble()
                      : 1.0,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= ordered.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        DateFormat('HH:mm').format(ordered[index].timestamp),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6C665D),
                        ),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 54,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toStringAsFixed(0),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6C665D),
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (items) => items
                    .map(
                      (item) => LineTooltipItem(
                        _price(item.y),
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                barWidth: 3,
                color: const Color(0xFFC79B24),
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: const Color(0xFFC79B24).withOpacity(0.12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentSignals extends StatelessWidget {
  const _RecentSignals({required this.signals});

  final List<TradeSignal> signals;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Recent Signals',
      child: Column(
        children: signals
            .map(
              (signal) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: signal.isBuy
                            ? const Color(0xFFE4F1EA)
                            : const Color(0xFFF5E8E6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        signal.isBuy ? Icons.north_east : Icons.south_east,
                        color: signal.isBuy
                            ? const Color(0xFF1D6B4F)
                            : const Color(0xFF9F3A35),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            signal.ticket.isEmpty
                                ? 'Ticket unavailable'
                                : signal.ticket,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${signal.type} / ${signal.status}',
                            style: const TextStyle(color: Color(0xFF6C665D)),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _price(signal.price),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _money(signal.netResult),
                          style: TextStyle(
                            color: signal.netResult >= 0
                                ? const Color(0xFF1D6B4F)
                                : const Color(0xFF9F3A35),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    required this.tone,
  });

  final String label;
  final String value;
  final String detail;
  final IconData icon;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5DED1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: tone),
          const SizedBox(height: 16),
          Text(label, style: const TextStyle(color: Color(0xFF6C665D))),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF181818),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            detail,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF6C665D)),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5DED1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF181818),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFFC79B24)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(body, style: const TextStyle(color: Color(0xFF6C665D))),
            ],
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.42)),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _DashboardMessage extends StatelessWidget {
  const _DashboardMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: const Color(0xFFC79B24)),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF6C665D),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _price(double value) => NumberFormat('#,##0.00').format(value);

String _money(double value) {
  final formatted = NumberFormat('#,##0.00').format(value.abs());
  return value < 0 ? '-$formatted' : '+$formatted';
}
