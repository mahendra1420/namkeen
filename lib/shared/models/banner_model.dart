class BannerModel {
  final String id;
  final String title;
  final String imageUrl; // Base64 string
  final bool isActive;

  BannerModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.isActive = true,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] as String,
      title: json['title'] as String,
      imageUrl: json['imageUrl'] as String,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'imageUrl': imageUrl,
      'isActive': isActive,
    };
  }
}
