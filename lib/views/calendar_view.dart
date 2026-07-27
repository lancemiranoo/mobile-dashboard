import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/profit_loss_calendar_controller.dart';
import '../models/profit_loss_calendar_model.dart';

class CalendarView extends ConsumerStatefulWidget {
  const CalendarView({super.key});

  @override
  ConsumerState<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends ConsumerState<CalendarView> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profitLossCalendarProvider);

    return state.when(
      loading: () => const _CalendarSkeleton(),
      error: (error, stackTrace) => _CalendarError(message: error.toString()),
      data: (calendar) => LayoutBuilder(
        builder: (context, constraints) {
          final padding = constraints.maxWidth >= 680 ? 28.0 : 16.0;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(padding, 16, padding, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: _CalendarContent(
                  month: _month,
                  calendar: calendar,
                  onPrevious: () => _changeMonth(-1),
                  onNext: () => _changeMonth(1),
                  onToday: () => setState(() {
                    _month = DateTime(
                      DateTime.now().year,
                      DateTime.now().month,
                    );
                  }),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _changeMonth(int offset) {
    setState(() {
      _month = DateTime(_month.year, _month.month + offset);
    });
  }
}

class _CalendarContent extends StatelessWidget {
  final DateTime month;
  final ProfitLossCalendarModel calendar;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;

  const _CalendarContent({
    required this.month,
    required this.calendar,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = calendar.totalForMonth(month);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profit & Loss',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Trading calendar',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(onPressed: onToday, child: const Text('Today')),
          ],
        ),
        const SizedBox(height: 16),
        _Panel(
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: onPrevious,
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Expanded(
                    child: Text(
                      _monthLabel(month),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onNext,
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _CalendarGrid(month: month, calendar: calendar),
            ],
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 680 ? 3 : 1;
            return GridView.count(
              crossAxisCount: columns,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: columns == 1 ? 5.3 : 2.5,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _SummaryCard(
                  label: 'Monthly P/L',
                  value: _formatMoney(total),
                  icon: Icons.account_balance_wallet_outlined,
                  color: _pnlColor(theme, total),
                ),
                _SummaryCard(
                  label: 'Profitable days',
                  value: '${calendar.profitableDaysForMonth(month)} days',
                  icon: Icons.trending_up_rounded,
                  color: Colors.green,
                ),
                _SummaryCard(
                  label: 'Losing days',
                  value: '${calendar.losingDaysForMonth(month)} days',
                  icon: Icons.trending_down_rounded,
                  color: Colors.red,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final DateTime month;
  final ProfitLossCalendarModel calendar;

  const _CalendarGrid({required this.month, required this.calendar});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final offset = DateTime(month.year, month.month, 1).weekday - 1;
    final days = DateTime(month.year, month.month + 1, 0).day;
    final cells = List<DateTime?>.filled(42, null);
    for (var day = 1; day <= days; day++) {
      cells[offset + day - 1] = DateTime(month.year, month.month, day);
    }

    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Column(
      children: [
        Row(
          children: labels
              .map(
                (label) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        Table(
          border: TableBorder(
            horizontalInside: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: .45),
            ),
            verticalInside: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: .35),
            ),
          ),
          children: [
            for (var row = 0; row < 6; row++)
              TableRow(
                children: [
                  for (var column = 0; column < 7; column++)
                    _DayCell(
                      date: cells[row * 7 + column],
                      value: cells[row * 7 + column] == null
                          ? 0
                          : calendar.valueFor(cells[row * 7 + column]!),
                    ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 12),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Legend(color: Colors.green, label: 'Profit'),
            SizedBox(width: 18),
            _Legend(color: Colors.red, label: 'Loss'),
          ],
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime? date;
  final double value;

  const _DayCell({required this.date, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (date == null) return const SizedBox(height: 68);
    final color = value > 0
        ? Colors.green
        : value < 0
        ? Colors.red
        : theme.colorScheme.onSurfaceVariant;
    return Container(
      height: 68,
      padding: const EdgeInsets.all(6),
      color: color.withValues(alpha: value == 0 ? 0 : .08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${date!.day}', style: theme.textTheme.labelMedium),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value == 0 ? '—' : _formatMoney(value),
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _Panel(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label),
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
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: .6)),
      ),
      child: child,
    );
  }
}

class _CalendarSkeleton extends StatelessWidget {
  const _CalendarSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(48),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _CalendarError extends StatelessWidget {
  final String message;

  const _CalendarError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Unable to load P/L calendar\n$message',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

String _monthLabel(DateTime date) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[date.month - 1]} ${date.year}';
}

Color _pnlColor(ThemeData theme, double value) {
  if (value > 0) return Colors.green;
  if (value < 0) return Colors.red;
  return theme.colorScheme.onSurfaceVariant;
}

String _formatMoney(double value) {
  final prefix = value < 0 ? '-\$' : '\$';
  return '$prefix${value.abs().toStringAsFixed(2)}';
}
