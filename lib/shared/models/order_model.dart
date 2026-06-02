import 'product_model.dart';

enum OrderStatus { pending, completed }

class OrderItem {
  final ProductModel product;
  final double quantity;

  OrderItem({required this.product, required this.quantity});

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      product: ProductModel.fromJson(json['product'] as Map<String, dynamic>),
      quantity: (json['quantity'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'quantity': quantity,
    };
  }

  double get total => product.price * quantity;
}

class OrderModel {
  final String id;
  final String retailerId;
  final String retailerName;
  final String shopName;
  final DateTime date;
  final List<OrderItem> items;
  final OrderStatus status;
  final String paymentMethod; // e.g. 'Cash', 'UPI', 'Credit'

  OrderModel({
    required this.id,
    required this.retailerId,
    required this.retailerName,
    required this.shopName,
    required this.date,
    required this.items,
    this.status = OrderStatus.pending,
    this.paymentMethod = 'Cash',
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      retailerId: json['retailerId'] as String,
      retailerName: json['retailerName'] as String,
      shopName: json['shopName'] as String,
      date: DateTime.parse(json['date'] as String),
      items: (json['items'] as List<dynamic>?)?.map((item) => OrderItem.fromJson(item as Map<String, dynamic>)).toList() ?? [],
      status: OrderStatus.values.firstWhere((e) => e.name == json['status'], orElse: () => OrderStatus.pending),
      paymentMethod: json['paymentMethod'] as String? ?? 'Cash',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'retailerId': retailerId,
      'retailerName': retailerName,
      'shopName': shopName,
      'date': date.toIso8601String(),
      'status': status.name,
      'paymentMethod': paymentMethod,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  double get grandTotal {
    return items.fold(0, (sum, item) => sum + item.total);
  }
}
