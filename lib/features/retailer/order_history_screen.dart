import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../shared/models/order_model.dart';
import '../../shared/providers/order_provider.dart';
import '../../shared/providers/cart_provider.dart';

class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(retailerOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),
      ),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No orders placed yet', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text('Order #${order.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getStatusColor(order.status).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _getStatusColor(order.status).withValues(alpha: 0.5)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_getStatusIcon(order.status), size: 14, color: _getStatusColor(order.status)),
                                const SizedBox(width: 4),
                                Text(
                                  order.status.name.replaceAll('_', ' ').toUpperCase(),
                                  style: TextStyle(color: _getStatusColor(order.status), fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Date: ${DateFormat('dd MMM yyyy, hh:mm a').format(order.date)}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text('${order.items.length} items', style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          Text('₹${order.grandTotal}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).primaryColor)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildTimelineStep(context, 'Placed', true),
                          Expanded(child: _buildTimelineDivider(order.status.index >= OrderStatus.partially_fulfilled.index)),
                          _buildTimelineStep(context, 'Packed', order.status.index >= OrderStatus.partially_fulfilled.index),
                          Expanded(child: _buildTimelineDivider(order.status == OrderStatus.completed)),
                          _buildTimelineStep(context, 'Delivered', order.status == OrderStatus.completed),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Theme.of(context).primaryColor,
                                side: BorderSide(color: Theme.of(context).primaryColor),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                context.push('/order-details', extra: order);
                              },
                              child: const Text('View Details'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                final cartNotifier = ref.read(cartProvider.notifier);
                                for (var item in order.items) {
                                  cartNotifier.addToCart(item.product, item.quantity);
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Items added to cart!'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                // Navigate to cart tab (index 2) or screen
                                context.push('/cart');
                              },
                              child: const Text('Reorder'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildTimelineStep(BuildContext context, String label, bool isActive) {
    return Column(
      children: [
        Icon(isActive ? Icons.check_circle : Icons.radio_button_unchecked, color: isActive ? Theme.of(context).primaryColor : Colors.grey.shade400, size: 24),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: isActive ? FontWeight.bold : FontWeight.normal, color: isActive ? Colors.black87 : Colors.grey)),
      ],
    );
  }

  Widget _buildTimelineDivider(bool isActive) {
    return Container(
      height: 2,
      margin: const EdgeInsets.only(bottom: 16),
      color: isActive ? const Color(0xFF2E3192) : Colors.grey.shade300,
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return Colors.orange;
      case OrderStatus.partially_fulfilled: return Colors.blue;
      case OrderStatus.completed: return Colors.green;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return Icons.schedule;
      case OrderStatus.partially_fulfilled: return Icons.inventory_2_outlined;
      case OrderStatus.completed: return Icons.check_circle_outline;
      default: return Icons.help_outline;
    }
  }
}
