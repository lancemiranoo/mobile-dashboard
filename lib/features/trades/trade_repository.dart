import 'package:cloud_firestore/cloud_firestore.dart';

import 'trade_signal.dart';

class TradeRepository {
  TradeRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static const collectionPath = String.fromEnvironment(
    'FIRESTORE_TRADES_COLLECTION',
    defaultValue: 'trades',
  );

  final FirebaseFirestore _firestore;

  Stream<List<TradeSignal>> watchGoldSignals({int limit = 40}) {
    return _firestore
        .collection(collectionPath)
        .where('Symbol', isEqualTo: TradeSignal.watchedSymbol)
        .orderBy('Timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(TradeSignal.fromSnapshot)
              .toList(growable: false),
        );
  }
}
