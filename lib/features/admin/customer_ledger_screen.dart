import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../shared/models/user_model.dart';
import '../../shared/providers/payment_provider.dart';
import '../../shared/providers/order_provider.dart';

class CustomerLedgerScreen extends ConsumerWidget {
  final UserModel customer;

  const CustomerLedgerScreen({super.key, required this.customer});

  void _showAddPaymentDialog(BuildContext context, WidgetRef ref) {
    final amountController = TextEditingController();
    final referenceController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add Payment'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(labelText: 'Amount (₹)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: referenceController,
                  decoration: const InputDecoration(labelText: 'Reference (e.g. Cash, UTR)'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: isLoading ? null : () async {
                  final amount = double.tryParse(amountController.text.trim()) ?? 0.0;
                  if (amount > 0) {
                    setState(() => isLoading = true);
                    try {
                      await ref.read(paymentServiceProvider).addPayment(
                        customer.id, 
                        amount, 
                        referenceController.text.trim().isEmpty ? 'Cash' : referenceController.text.trim()
                      );
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      setState(() => isLoading = false);
                    }
                  }
                },
                child: isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Add Payment'),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormatter = NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');
    final paymentsAsync = ref.watch(paymentProvider(customer.id));
    final ordersAsync = ref.watch(orderProvider);

    return Scaffold(
      appBar: AppBar(title: Text('${customer.shopName} Ledger')),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(24),
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Column(
                children: [
                  const Text('Outstanding Balance', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(currencyFormatter.format(customer.creditBalance), style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _showAddPaymentDialog(context, ref),
                        icon: const Icon(Icons.payment),
                        label: const Text('Record Payment'),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF Export coming soon!')));
                        },
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Export'),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text('Recent Payments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          paymentsAsync.when(
            loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
            error: (e, st) => SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
            data: (payments) {
              if (payments.isEmpty) return const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(16), child: Text('No payments recorded.')));
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final p = payments[index];
                    return ListTile(
                      leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.arrow_downward, color: Colors.white)),
                      title: Text(currencyFormatter.format(p.amount), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      subtitle: Text('${DateFormat('dd MMM yyyy, hh:mm a').format(p.date)} • ${p.reference}'),
                    );
                  },
                  childCount: payments.length,
                ),
              );
            },
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text('Recent Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          ordersAsync.when(
            loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
            error: (e, st) => SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
            data: (orders) {
              final customerOrders = orders.where((o) => o.retailerId == customer.id).toList();
              if (customerOrders.isEmpty) return const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(16), child: Text('No orders found.')));
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final o = customerOrders[index];
                    return ListTile(
                      leading: const CircleAvatar(backgroundColor: Colors.redAccent, child: Icon(Icons.arrow_upward, color: Colors.white)),
                      title: Text(currencyFormatter.format(o.grandTotal), style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${DateFormat('dd MMM yyyy').format(o.date)} • Status: ${o.status.name}'),
                    );
                  },
                  childCount: customerOrders.length,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
