import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/providers/auth_provider.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('User not found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Account'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ledger / Balance Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E3192), Color(0xFF1BFFFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1BFFFF).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_balance_wallet, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'Outstanding Ledger Balance',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '₹${user.creditBalance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Contact admin to settle your dues.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Profile Information
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Profile Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () => context.push('/edit-profile'),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildProfileRow(Icons.person, 'Name', user.name + (user.surname != null ? ' ${user.surname}' : '')),
                    const Divider(),
                    _buildProfileRow(Icons.store, 'Shop Name', user.shopName ?? 'N/A'),
                    const Divider(),
                    _buildProfileRow(Icons.phone, 'Phone', user.phone),
                    if (user.secondPhone != null && user.secondPhone!.isNotEmpty) ...[
                      const Divider(),
                      _buildProfileRow(Icons.phone_android, 'Alt Phone', user.secondPhone!),
                    ],
                    const Divider(),
                    _buildProfileRow(Icons.receipt, 'GST Number', user.gstNumber ?? 'N/A'),
                    const Divider(),
                    _buildProfileRow(Icons.location_on, 'Address', user.address ?? 'N/A'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
