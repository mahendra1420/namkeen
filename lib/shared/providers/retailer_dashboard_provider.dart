import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';
import 'auth_provider.dart';
import 'product_provider.dart';

final bestSellingProductsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final user = ref.watch(authProvider);
  if (user == null) return [];

  final db = FirebaseFirestore.instance;
  final ordersSnapshot = await db.collection('orders')
      .where('retailerId', isEqualTo: user.id)
      .where('status', isEqualTo: OrderStatus.completed.name)
      .get();

  Map<String, double> productSales = {};

  for (var doc in ordersSnapshot.docs) {
    final itemsList = (doc.data()['items'] as List<dynamic>?) ?? [];
    for (var itemData in itemsList) {
      final productId = itemData['product']['id'] as String;
      final qty = (itemData['quantity'] as num).toDouble();
      
      productSales[productId] = (productSales[productId] ?? 0) + qty;
    }
  }

  final sortedList = productSales.entries.toList();
  sortedList.sort((a, b) => b.value.compareTo(a.value));
  final topIds = sortedList.take(5).map((e) => e.key).toList();

  if (topIds.isEmpty) return [];

  final productsSnapshot = await db.collection('products')
      .where(FieldPath.documentId, whereIn: topIds)
      .get();

  final products = productsSnapshot.docs.map((doc) {
    final data = doc.data();
    data['id'] = doc.id;
    return ProductModel.fromJson(data);
  }).toList();

  // Sort them to match the topIds order
  products.sort((a, b) => topIds.indexOf(a.id).compareTo(topIds.indexOf(b.id)));
  return products;
});

final recentlyOrderedProvider = FutureProvider<List<ProductModel>>((ref) async {
  final user = ref.watch(authProvider);
  if (user == null) return [];

  final db = FirebaseFirestore.instance;
  final recentOrderSnapshot = await db.collection('orders')
      .where('retailerId', isEqualTo: user.id)
      .get();

  if (recentOrderSnapshot.docs.isEmpty) return [];

  final ordersList = recentOrderSnapshot.docs.toList();
  ordersList.sort((a, b) {
    final dateA = DateTime.parse(a.data()['date'] as String);
    final dateB = DateTime.parse(b.data()['date'] as String);
    return dateB.compareTo(dateA);
  });

  final recentOrderDoc = ordersList.first;
  final itemsList = (recentOrderDoc.data()['items'] as List<dynamic>?) ?? [];

  List<ProductModel> products = [];
  for (var itemData in itemsList) {
    final productData = itemData['product'] as Map<String, dynamic>;
    products.add(ProductModel.fromJson(productData));
  }

  return products;
});
