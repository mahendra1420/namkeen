import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

final customerProvider = StreamProvider<List<UserModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('users')
      .where('role', isEqualTo: UserRole.retailer.name)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return UserModel.fromJson(data);
    }).toList();
  });
});

class UserService {
  final _db = FirebaseFirestore.instance;

  Future<void> updateCustomerStatus(String id, {bool? isApproved, bool? isBlocked}) async {
    final Map<String, dynamic> updates = {};
    if (isApproved != null) updates['isApproved'] = isApproved;
    if (isBlocked != null) updates['isBlocked'] = isBlocked;
    
    if (updates.isNotEmpty) {
      await _db.collection('users').doc(id).update(updates);
    }
  }
}

final userServiceProvider = Provider((ref) => UserService());
