class ProductModel {
  final String id;
  final String name;
  final double price; // per kg or unit
  final String unit; // e.g. 'kg', 'box'
  final String? imageUrl;
  final String category;
  final double stock; // e.g. 500
  final bool isActive;
  final String? description;
  final double minOrderQuantity;
  final int? discountThreshold;
  final double? discountedPrice;

  ProductModel({
    required this.id,
    required this.name,
    required this.price,
    this.unit = 'kg',
    this.imageUrl,
    required this.category,
    this.stock = 0.0,
    this.isActive = true,
    this.description,
    this.minOrderQuantity = 1.0,
    this.discountThreshold,
    this.discountedPrice,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      unit: json['unit'] as String? ?? 'kg',
      imageUrl: json['imageUrl'] as String?,
      category: json['category'] as String,
      stock: (json['stock'] as num?)?.toDouble() ?? 0.0,
      isActive: json['isActive'] as bool? ?? true,
      description: json['description'] as String?,
      minOrderQuantity: (json['minOrderQuantity'] as num?)?.toDouble() ?? 1.0,
      discountThreshold: json['discountThreshold'] as int?,
      discountedPrice: (json['discountedPrice'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'unit': unit,
      'imageUrl': imageUrl,
      'category': category,
      'stock': stock,
      'isActive': isActive,
      'description': description,
      'minOrderQuantity': minOrderQuantity,
      'discountThreshold': discountThreshold,
      'discountedPrice': discountedPrice,
    };
  }
}
