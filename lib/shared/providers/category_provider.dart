import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_model.dart';

final categoryProvider = StreamProvider<List<CategoryModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('categories')
      .orderBy('name')
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return CategoryModel.fromJson(data);
    }).toList();
  });
});

class CategoryService {
  final _db = FirebaseFirestore.instance;

  Future<void> addCategory(String name) async {
    final ref = _db.collection('categories').doc();
    final model = CategoryModel(id: ref.id, name: name);
    await ref.set(model.toJson());
  }

  Future<void> removeCategory(String id) async {
    await _db.collection('categories').doc(id).delete();
  }
}

final categoryServiceProvider = Provider((ref) => CategoryService());
