import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../shared/providers/order_provider.dart';
import '../../shared/models/order_model.dart';

class OrderManagementScreen extends ConsumerWidget {
  const OrderManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(orderProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Orders'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2E3192), Color(0xFF1BFFFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(child: Text('No orders found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    context.push('/order-details', extra: order);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Order #${order.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text(order.shopName.isNotEmpty ? order.shopName : order.retailerName, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                              ],
                            ),
                          ),
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
                      if (order.status == OrderStatus.pending || order.status == OrderStatus.partially_fulfilled)
                        Row(
                          children: [
                            if (order.status == OrderStatus.pending)
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  icon: const Icon(Icons.inventory_2, size: 18),
                                  label: const Text('Partial Fill'),
                                  onPressed: () async {
                                    try {
                                      await ref.read(orderServiceProvider).updateOrderStatus(order.id, OrderStatus.partially_fulfilled);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order marked as partially fulfilled!'), backgroundColor: Colors.blue));
                                      }
                                    } catch (e) {
                                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                    }
                                  },
                                ),
                              ),
                            if (order.status == OrderStatus.pending) const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.check_circle, size: 18),
                                label: const Text('Complete'),
                                onPressed: () async {
                                  try {
                                    await ref.read(orderServiceProvider).updateOrderStatus(order.id, OrderStatus.completed);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order marked as completed!'), backgroundColor: Colors.green));
                                    }
                                  } catch (e) {
                                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ));
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
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
