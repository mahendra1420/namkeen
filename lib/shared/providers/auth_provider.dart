import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

final authProvider = NotifierProvider<AuthNotifier, UserModel?>(() {
  return AuthNotifier();
});

class AuthNotifier extends Notifier<UserModel?> {
  @override
  UserModel? build() => null;

  // Mock Admin user
  final _adminUser = UserModel(
    id: 'admin_1',
    name: 'Super Admin',
    phone: '1234567890',
    role: UserRole.admin,
    isApproved: true,
  );

  // Mock Retailer user
  final _retailerUser = UserModel(
    id: 'ret_1',
    name: 'Ramesh Patel',
    phone: '9876543210',
    shopName: 'Patel Store',
    role: UserRole.retailer,
    isApproved: true,
    creditBalance: 15000,
  );

  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('userRole');
    final userId = prefs.getString('userId');
    
    if (role == 'admin') {
      state = _adminUser;
    } else if (role == 'retailer' && userId != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        state = UserModel.fromJson(data);
      } else {
        state = null;
      }
    }
  }

  Future<bool> login(String phone, String password) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (phone == 'admin' || phone == '9999999999') {
      await prefs.setString('userRole', 'admin');
      state = _adminUser;
      return true;
    }
    
    final db = FirebaseFirestore.instance;
    final snapshot = await db.collection('users').where('phone', isEqualTo: phone).get();
    
    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      data['id'] = snapshot.docs.first.id;
      final user = UserModel.fromJson(data);
      
      await prefs.setString('userRole', 'retailer');
      await prefs.setString('userId', user.id);
      state = user;
      return true;
    } else {
      if (phone == '9876543210') {
         final mockRef = db.collection('users').doc('ret_1');
         final mockDoc = await mockRef.get();
         if (!mockDoc.exists) {
           await mockRef.set(_retailerUser.toJson());
         }
         await prefs.setString('userRole', 'retailer');
         await prefs.setString('userId', 'ret_1');
         state = _retailerUser;
         return true;
      }
    }
    return false;
  }

  void logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userRole');
    state = null;
  }
}
