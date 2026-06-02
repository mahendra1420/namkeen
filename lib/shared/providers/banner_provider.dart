import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/banner_model.dart';

final bannerProvider = StreamProvider<List<BannerModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('banners')
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return BannerModel.fromJson(data);
    }).toList();
  });
});

class BannerService {
  final _db = FirebaseFirestore.instance;

  Future<void> addBanner(BannerModel banner) async {
    final ref = _db.collection('banners').doc();
    final model = BannerModel(
      id: ref.id,
      title: banner.title,
      imageUrl: banner.imageUrl,
      isActive: banner.isActive,
    );
    await ref.set(model.toJson());
  }

  Future<void> updateBanner(BannerModel banner) async {
    await _db.collection('banners').doc(banner.id).update(banner.toJson());
  }

  Future<void> removeBanner(String id) async {
    await _db.collection('banners').doc(id).delete();
  }
}

final bannerServiceProvider = Provider((ref) => BannerService());
