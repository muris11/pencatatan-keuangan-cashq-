import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import '../models/category.dart';
import '../models/transaction_item.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> _catCol(String uid) =>
      _userDoc(uid).collection('categories');

  CollectionReference<Map<String, dynamic>> _txCol(String uid) =>
      _userDoc(uid).collection('transactions');

  // Users
  Future<void> upsertUser(UserProfile p) =>
      _userDoc(p.uid).set(p.toMap(), SetOptions(merge: true));

  Stream<UserProfile> watchUser(String uid) => _userDoc(
    uid,
  ).snapshots().map((s) => UserProfile.fromMap(uid, s.data() ?? {}));

  Future<UserProfile?> getUser(String uid) async {
    final s = await _userDoc(uid).get();
    if (!s.exists) return null;
    return UserProfile.fromMap(uid, s.data()!);
  }

  // Categories
  Stream<List<CategoryItem>> watchCategories(String uid) => _catCol(uid)
      .orderBy('name')
      .snapshots()
      .map(
        (q) => q.docs.map((d) => CategoryItem.fromMap(d.id, d.data())).toList(),
      );

  Future<void> addCategory(String uid, CategoryItem c) =>
      _catCol(uid).add(c.toMap());

  Future<void> updateCategory(String uid, CategoryItem c) =>
      _catCol(uid).doc(c.id).update(c.toMap());

  Future<void> deleteCategory(String uid, String id) =>
      _catCol(uid).doc(id).delete();

  // Transactions
  Stream<List<TransactionItem>> watchTransactions(
    String uid, {
    DateTime? from,
    DateTime? to,
  }) {
    Query<Map<String, dynamic>> q = _txCol(
      uid,
    ).orderBy('date', descending: true);
    if (from != null) {
      q = q.where('date', isGreaterThanOrEqualTo: from.toIso8601String());
    }
    if (to != null) {
      q = q.where('date', isLessThanOrEqualTo: to.toIso8601String());
    }
    return q.snapshots().map(
      (x) =>
          x.docs.map((d) => TransactionItem.fromMap(d.id, d.data())).toList(),
    );
  }

  Future<void> addTransaction(String uid, TransactionItem t) =>
      _txCol(uid).add(t.toMap());

  Future<void> updateTransaction(String uid, TransactionItem t) =>
      _txCol(uid).doc(t.id).update(t.toMap());

  Future<void> deleteTransaction(String uid, String id) =>
      _txCol(uid).doc(id).delete();

  // Delete all transactions of a type (income or expense)
  Future<void> deleteAllTransactionsOfType(String userId, TxType type) async {
    final snapshot =
        await _txCol(userId)
            .where(
              'type',
              isEqualTo: type.name,
            ) // pastikan 'type' sesuai dengan Firestore
            .get();

    final batch = _db.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
