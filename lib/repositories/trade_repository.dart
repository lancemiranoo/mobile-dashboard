import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/trade_model.dart';

final tradeRepositoryProvider = Provider<TradeRepository>((ref) {
  return TradeRepository(firestore: FirebaseFirestore.instance);
});

final tradeCollectionProvider = StreamProvider.autoDispose<List<TradeModel>>((
  ref,
) {
  return ref.watch(tradeRepositoryProvider).watchTrades();
});

final dashboardTradeCollectionProvider =
    StreamProvider.autoDispose<List<TradeModel>>((ref) {
      return ref.watch(tradeRepositoryProvider).watchAllTrades();
    });

final calendarTradeCollectionProvider =
    StreamProvider.autoDispose<List<TradeModel>>((ref) {
      return ref.watch(tradeRepositoryProvider).watchCalendarTrades();
    });

class TradeRepository {
  final FirebaseFirestore _firestore;

  TradeRepository({required FirebaseFirestore firestore})
    : _firestore = firestore;

  Stream<List<TradeModel>> watchTrades() {
    return _firestore
        .collection('live-trade')
        .orderBy('uploadedAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(TradeModel.fromFirestore).toList(),
        );
  }

  Stream<List<TradeModel>> watchCalendarTrades() {
    return _firestore
        .collection('live-trade')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(TradeModel.fromFirestore).toList(),
        );
  }

  Stream<List<TradeModel>> watchAllTrades() {
    return _firestore
        .collection('live-trade')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(TradeModel.fromFirestore).toList(),
        );
  }
}
