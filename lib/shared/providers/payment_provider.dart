import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_model.dart';
import 'user_provider.dart';

final paymentProvider = StreamProvider.family<List<PaymentModel>, String>((ref, retailerId) {
  return FirebaseFirestore.instance
      .collection('payments')
      .where('retailerId', isEqualTo: retailerId)
      .snapshots()
      .map((snapshot) {
    final payments = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return PaymentModel.fromJson(data);
    }).toList();
    payments.sort((a, b) => b.date.compareTo(a.date));
    return payments;
  });
});

class PaymentService {
  final _db = FirebaseFirestore.instance;
  final Ref _ref;

  PaymentService(this._ref);

  Future<void> addPayment(String retailerId, double amount, String reference) async {
    final paymentRef = _db.collection('payments').doc();
    final payment = PaymentModel(
      id: paymentRef.id,
      retailerId: retailerId,
      amount: amount,
      date: DateTime.now(),
      reference: reference,
    );

    // Run transaction to add payment and reduce outstanding balance
    await _db.runTransaction((transaction) async {
      final userRef = _db.collection('users').doc(retailerId);
      final userDoc = await transaction.get(userRef);
      
      if (!userDoc.exists) throw Exception("Retailer not found");
      
      final currentBalance = (userDoc.data()?['creditBalance'] as num?)?.toDouble() ?? 0.0;
      final newBalance = currentBalance - amount;

      transaction.set(paymentRef, payment.toJson());
      transaction.update(userRef, {'creditBalance': newBalance});
    });
  }
}

final paymentServiceProvider = Provider((ref) => PaymentService(ref));
