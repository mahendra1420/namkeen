import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import 'auth_provider.dart';

final orderProvider = StreamProvider<List<OrderModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('orders')
      .orderBy('date', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return OrderModel.fromJson(data);
    }).toList();
  });
});

final retailerOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final user = ref.watch(authProvider);
  if (user == null || user.role != UserRole.retailer) return Stream.value([]);
  
  return FirebaseFirestore.instance
      .collection('orders')
      .where('retailerId', isEqualTo: user.id)
      .snapshots()
      .map((snapshot) {
    final orders = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return OrderModel.fromJson(data);
    }).toList();
    orders.sort((a, b) => b.date.compareTo(a.date));
    return orders;
  });
});

class OrderService {
  final _db = FirebaseFirestore.instance;

  Future<void> placeOrder(OrderModel order) async {
    final orderRef = _db.collection('orders').doc();
    final orderData = order.toJson();
    orderData['id'] = orderRef.id;
    
    // Save the main order document
    await orderRef.set(orderData);
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    final orderRef = _db.collection('orders').doc(orderId);
    
    await _db.runTransaction((transaction) async {
      final orderDoc = await transaction.get(orderRef);
      if (!orderDoc.exists) return;

      final currentStatusStr = orderDoc.data()?['status'] as String?;
      
      // If status changes TO completed, deduct stock and update ledger
      if (newStatus == OrderStatus.completed && currentStatusStr != OrderStatus.completed.name) {
        final retailerId = orderDoc.data()?['retailerId'] as String?;
        
        // 1. Fetch all items in this order to deduct stock
        final itemsList = (orderDoc.data()?['items'] as List<dynamic>?) ?? [];
        
        // READ PHASE
        Map<String, DocumentSnapshot> productDocs = {};
        for (var itemData in itemsList) {
          final productId = itemData['product']['id'];
          final productRef = _db.collection('products').doc(productId);
          productDocs[productId] = await transaction.get(productRef);
        }
        
        DocumentSnapshot? userDoc;
        DocumentReference? userRef;
        if (retailerId != null) {
          userRef = _db.collection('users').doc(retailerId);
          userDoc = await transaction.get(userRef);
        }

        // WRITE PHASE
        double totalOrderValue = 0.0;
        for (var itemData in itemsList) {
          final productId = itemData['product']['id'];
          final quantity = (itemData['quantity'] as num).toDouble();
          final price = (itemData['product']['price'] as num).toDouble();
          
          totalOrderValue += (price * quantity);
          
          final pDoc = productDocs[productId];
          if (pDoc != null && pDoc.exists) {
            final data = pDoc.data() as Map<String, dynamic>?;
            final currentStock = (data?['stock'] as num?)?.toDouble() ?? 0.0;
            final newStock = currentStock - quantity;
            transaction.update(pDoc.reference, {'stock': newStock < 0 ? 0.0 : newStock});
          }
        }

        // 2. Update Retailer Credit Balance
        if (userDoc != null && userDoc.exists && userRef != null) {
          final data = userDoc.data() as Map<String, dynamic>?;
          final currentBalance = (data?['creditBalance'] as num?)?.toDouble() ?? 0.0;
          transaction.update(userRef, {'creditBalance': currentBalance + totalOrderValue});
        }
      }

      // Update status last
      transaction.update(orderRef, {'status': newStatus.name});
    });
  }
}

final orderServiceProvider = Provider((ref) => OrderService());
