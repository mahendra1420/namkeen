import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../shared/models/order_model.dart';
import '../../shared/providers/order_provider.dart';
import '../../shared/utils/invoice_generator.dart';

class OrderDetailsScreen extends ConsumerWidget {
  final OrderModel order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${order.id}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getStatusColor(order.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _getStatusColor(order.status).withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Icon(_getStatusIcon(order.status), color: _getStatusColor(order.status), size: 32),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Order Status', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text(order.status.name.toUpperCase(), style: TextStyle(color: _getStatusColor(order.status), fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Order Info
            const Text('Order Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildInfoRow('Order ID', '#${order.id}'),
                    const Divider(),
                    _buildInfoRow('Date', DateFormat('dd MMM yyyy, hh:mm a').format(order.date)),
                    const Divider(),
                    _buildInfoRow('Total Items', '${order.items.length}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Order Items
            const Text('Items Ordered', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: order.items.length,
              itemBuilder: (context, index) {
                final item = order.items[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 0,
                  color: Colors.grey.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: item.product.imageUrl != null && item.product.imageUrl!.isNotEmpty
                              ? Image.network(item.product.imageUrl!, width: 48, height: 48, fit: BoxFit.cover)
                              : Container(width: 48, height: 48, color: Colors.grey.shade200, child: const Icon(Icons.image, color: Colors.grey, size: 20)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              Text('${item.quantity} x ₹${item.product.price} / ${item.product.unit}', style: TextStyle(color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                        Text('₹${item.total}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Total Summary
            Card(
              color: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('₹${order.grandTotal}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                    label: const Text('Share Invoice'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      try {
                        final bytes = await InvoiceGenerator.generateInvoice(order);
                        await Printing.sharePdf(bytes: bytes, filename: 'invoice_${order.id}.pdf');
                      } catch (e) {
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.chat),
                    label: const Text('WhatsApp Admin'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      // Hardcoding admin number for now or we could pull from a config
                      final adminPhone = '919999999999'; 
                      final text = Uri.encodeComponent('Hello Admin, I have a query regarding Order #${order.id}.');
                      final url = Uri.parse('https://wa.me/$adminPhone?text=$text');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      } else {
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch WhatsApp')));
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (order.status == OrderStatus.pending)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Mark as Completed', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  onPressed: () async {
                    try {
                      await ref.read(orderServiceProvider).updateOrderStatus(order.id, OrderStatus.completed);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Order marked as completed!'), backgroundColor: Colors.green),
                        );
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                ),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
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
      case OrderStatus.partially_fulfilled: return Icons.inventory_2;
      case OrderStatus.completed: return Icons.check_circle;
      default: return Icons.info;
    }
  }
}
