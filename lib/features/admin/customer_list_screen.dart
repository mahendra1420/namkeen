import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../shared/providers/user_provider.dart';
import '../../shared/models/user_model.dart';

class CustomerListScreen extends ConsumerWidget {
  const CustomerListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(customerProvider);
    final currencyFormatter = NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');

    return Scaffold(
      appBar: AppBar(title: const Text('Customer Management')),
      body: customersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (customers) {
          if (customers.isEmpty) {
            return const Center(child: Text('No retailers registered yet.'));
          }
          return ListView.builder(
            itemCount: customers.length,
            itemBuilder: (context, index) {
              final customer = customers[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              customer.shopName ?? 'Unnamed Shop',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ),
                          _StatusBadge(customer: customer),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Owner: ${customer.name} ${customer.surname ?? ''}'),
                      Text('Mobile: ${customer.phone}'),
                      if (customer.address != null) Text('Address: ${customer.address}'),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total Orders', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              const Text('0', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), // Placeholder until order stats are added
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Outstanding Balance', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              Text(currencyFormatter.format(customer.creditBalance), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (!customer.isApproved && !customer.isBlocked)
                            TextButton.icon(
                              onPressed: () async {
                                await ref.read(userServiceProvider).updateCustomerStatus(customer.id, isApproved: true);
                              },
                              icon: const Icon(Icons.check_circle, color: Colors.green),
                              label: const Text('Approve', style: TextStyle(color: Colors.green)),
                            ),
                          if (customer.isApproved && !customer.isBlocked)
                            TextButton.icon(
                              onPressed: () async {
                                await ref.read(userServiceProvider).updateCustomerStatus(customer.id, isBlocked: true);
                              },
                              icon: const Icon(Icons.block, color: Colors.red),
                              label: const Text('Block', style: TextStyle(color: Colors.red)),
                            ),
                          if (customer.isBlocked)
                            TextButton.icon(
                              onPressed: () async {
                                await ref.read(userServiceProvider).updateCustomerStatus(customer.id, isBlocked: false, isApproved: true);
                              },
                              icon: const Icon(Icons.lock_open, color: Colors.orange),
                              label: const Text('Unblock', style: TextStyle(color: Colors.orange)),
                            ),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edit coming soon')));
                              } else if (value == 'ledger') {
                                context.push('/ledger', extra: customer);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'edit', child: Text('Edit Details')),
                              const PopupMenuItem(value: 'ledger', child: Text('View Ledger & History')),
                            ],
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
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final UserModel customer;

  const _StatusBadge({required this.customer});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;

    if (customer.isBlocked) {
      color = Colors.red;
      text = 'BLOCKED';
    } else if (!customer.isApproved) {
      color = Colors.orange;
      text = 'PENDING';
    } else {
      color = Colors.green;
      text = 'ACTIVE';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
