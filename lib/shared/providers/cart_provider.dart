import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';

final cartProvider = NotifierProvider<CartNotifier, List<OrderItem>>(() {
  return CartNotifier();
});

class CartNotifier extends Notifier<List<OrderItem>> {
  @override
  List<OrderItem> build() => [];

  void addToCart(ProductModel product, double quantity) {
    final existingIndex = state.indexWhere((item) => item.product.id == product.id);
    if (existingIndex >= 0) {
      final updatedItems = [...state];
      updatedItems[existingIndex] = OrderItem(
        product: product,
        quantity: updatedItems[existingIndex].quantity + quantity,
      );
      state = updatedItems;
    } else {
      state = [...state, OrderItem(product: product, quantity: quantity)];
    }
  }

  void updateQuantity(String productId, double quantity) {
    state = [
      for (final item in state)
        if (item.product.id == productId)
          OrderItem(product: item.product, quantity: quantity)
        else
          item
    ];
  }

  void removeFromCart(String productId) {
    state = state.where((item) => item.product.id != productId).toList();
  }

  void clearCart() {
    state = [];
  }

  double get totalAmount {
    return state.fold(0, (sum, item) => sum + item.total);
  }
}
