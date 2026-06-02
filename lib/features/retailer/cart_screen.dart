import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/providers/cart_provider.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/order_provider.dart';
import '../../shared/models/order_model.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  bool _isCheckingOut = false;

  Future<void> _handleCheckout() async {
    final cartItems = ref.read(cartProvider);
    final totalAmount = ref.read(cartProvider.notifier).totalAmount;
    final user = ref.read(authProvider);

    if (cartItems.isEmpty) return;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in to checkout')));
      return;
    }

    setState(() => _isCheckingOut = true);

    try {
      final orderId = 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
      
      final newOrder = OrderModel(
        id: orderId,
        retailerId: user.id,
        retailerName: user.name,
        shopName: user.shopName ?? user.name,
        items: cartItems,
        status: OrderStatus.pending,
        date: DateTime.now(),
      );

      await ref.read(orderServiceProvider).placeOrder(newOrder);
      
      ref.read(cartProvider.notifier).clearCart();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order #$orderId placed successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Switch to the Orders tab (index 3)
        context.go('/retailer');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isCheckingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
      ),
      body: cartItems.isEmpty
          ? const Center(child: Text('Your cart is empty.'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 4),
                                    Text('₹${item.product.price} / ${item.product.unit}', style: TextStyle(color: Colors.grey.shade600)),
                                    const SizedBox(height: 12),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        border: Border.all(color: Colors.grey.shade300),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          InkWell(
                                            onTap: item.quantity > item.product.minOrderQuantity ? () => cartNotifier.updateQuantity(item.product.id, item.quantity - 1) : null,
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              child: Icon(Icons.remove, size: 18, color: item.quantity > item.product.minOrderQuantity ? Colors.black87 : Colors.grey),
                                            ),
                                          ),
                                          Text('${item.quantity.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                          InkWell(
                                            onTap: () => cartNotifier.updateQuantity(item.product.id, item.quantity + 1),
                                            child: const Padding(
                                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              child: Icon(Icons.add, size: 18, color: Colors.black87),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('₹${item.total}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).primaryColor)),
                                  const SizedBox(height: 16),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => cartNotifier.removeFromCart(item.product.id),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Amount:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text('₹${cartNotifier.totalAmount}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _isCheckingOut ? null : _handleCheckout,
                            child: _isCheckingOut
                                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Proceed to Checkout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
