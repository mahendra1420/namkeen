import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

final productProvider = StreamProvider<List<ProductModel>>((ref) {
  return FirebaseFirestore.instance.collection('products').snapshots().map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id; // ensure ID is set from document
      return ProductModel.fromJson(data);
    }).toList();
  });
});

class ProductService {
  final _db = FirebaseFirestore.instance;

  Future<void> addProduct(ProductModel product) async {
    await _db.collection('products').add(product.toJson());
  }

  Future<void> updateProduct(ProductModel product) async {
    await _db.collection('products').doc(product.id).update(product.toJson());
  }

  Future<void> removeProduct(String id) async {
    await _db.collection('products').doc(id).delete();
  }
}

final productServiceProvider = Provider((ref) => ProductService());
