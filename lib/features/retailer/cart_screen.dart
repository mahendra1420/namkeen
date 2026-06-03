import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import '../../shared/providers/cart_provider.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/order_provider.dart';
import '../../shared/models/order_model.dart';
import 'retailer_main_layout.dart';

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

    if (user.creditBalance + totalAmount > user.creditLimit) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Credit Limit Exceeded'),
          content: Text('Your current outstanding balance (₹${user.creditBalance}) plus this order (₹$totalAmount) exceeds your assigned credit limit of ₹${user.creditLimit}.\n\nPlease contact the administrator to settle your dues.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );
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
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.network(
                    'https://assets10.lottiefiles.com/packages/lf20_3VDN1k.json',
                    width: 200,
                    height: 200,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.shopping_cart_outlined, size: 100, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  const Text('Your cart is empty.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(retailerNavIndexProvider.notifier).state = 1;
                    },
                    child: const Text('Start Shopping'),
                  )
                ],
              ),
            )
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: item.product.imageUrl != null && item.product.imageUrl!.isNotEmpty
                                    ? Image.network(item.product.imageUrl!, width: 60, height: 60, fit: BoxFit.cover)
                                    : Container(width: 60, height: 60, color: Colors.grey.shade200, child: const Icon(Icons.image, color: Colors.grey)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text('₹${item.product.price} / ${item.product.unit}', style: TextStyle(color: Colors.grey.shade600, decoration: (item.product.discountThreshold != null && item.quantity >= item.product.discountThreshold!) ? TextDecoration.lineThrough : null)),
                                        if (item.product.discountThreshold != null && item.quantity >= item.product.discountThreshold!) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(4)),
                                            child: Text('₹${item.product.discountedPrice} applied!', style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ],
                                    ),
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
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    bottom: false,
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
