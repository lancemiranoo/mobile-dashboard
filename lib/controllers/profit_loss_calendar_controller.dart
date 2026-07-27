import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/profit_loss_calendar_model.dart';
import '../models/trade_model.dart';
import '../repositories/trade_repository.dart';

final profitLossCalendarProvider =
    Provider.autoDispose<AsyncValue<ProfitLossCalendarModel>>((ref) {
      final trades = ref.watch(calendarTradeCollectionProvider);
      return trades.whenData(_buildCalendar);
    });

ProfitLossCalendarModel _buildCalendar(List<TradeModel> trades) {
  final dailyNet = <DateTime, double>{};

  for (final trade in trades) {
    final date = (trade.timestamp ?? trade.uploadedAt)?.toLocal();
    if (date == null) continue;

    final day = DateTime(date.year, date.month, date.day);
    dailyNet[day] = (dailyNet[day] ?? 0) + trade.netResult;
  }

  return ProfitLossCalendarModel(dailyNet: dailyNet);
}
