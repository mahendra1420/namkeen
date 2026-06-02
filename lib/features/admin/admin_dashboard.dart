import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/order_provider.dart';
import '../../shared/providers/product_provider.dart';
import '../../shared/providers/user_provider.dart';
import '../../shared/models/order_model.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We can extract user if needed: final user = ref.watch(authProvider);
    
    final ordersAsync = ref.watch(orderProvider);
    final productsAsync = ref.watch(productProvider);
    final customersAsync = ref.watch(customerProvider);
    final currencyFormatter = NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2E3192), Color(0xFF1BFFFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () {
              context.go('/login');
            },
          )
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2E3192), Color(0xFF1BFFFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Icon(Icons.admin_panel_settings, size: 120, color: Colors.white.withOpacity(0.2)),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: const [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, size: 40, color: Color(0xFF2E3192)),
                      ),
                      SizedBox(height: 12),
                      Text('Admin Panel', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                    ],
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () => Navigator.pop(context),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.add_box),
              title: const Text('Add Product'),
              onTap: () {
                Navigator.pop(context);
                context.push('/add-product');
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text('Manage Products'),
              onTap: () {
                Navigator.pop(context);
                context.push('/products');
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Manage Orders'),
              onTap: () {
                Navigator.pop(context);
                context.push('/orders');
              },
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Manage Categories'),
              onTap: () {
                Navigator.pop(context);
                context.push('/categories');
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Manage Customers'),
              onTap: () {
                Navigator.pop(context);
                context.push('/customers');
              },
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Manage Banners'),
              onTap: () {
                Navigator.pop(context);
                context.push('/banners');
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart, color: Color(0xFF2E3192)),
              title: const Text('Reports', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                context.push('/reports');
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: Color(0xFFE8EAF6),
                    child: Icon(Icons.waving_hand, color: Color(0xFF2E3192)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome Back, Admin!', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Here is your business summary today.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text('Business Overview', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            const SizedBox(height: 20),
            
            // Stats Grid
            ordersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Text('Error loading orders: $e'),
              data: (orders) {
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                final firstDayOfMonth = DateTime(now.year, now.month, 1);

                final todaysOrders = orders.where((o) => o.date.year == now.year && o.date.month == now.month && o.date.day == now.day).toList();
                final pendingOrders = orders.where((o) => o.status == OrderStatus.pending).toList();
                final completedOrders = orders.where((o) => o.status == OrderStatus.completed).toList();
                
                final todaysRevenue = todaysOrders.fold<double>(0, (sum, o) => sum + o.grandTotal);
                final monthlyOrders = orders.where((o) => o.date.isAfter(firstDayOfMonth) || o.date.isAtSameMomentAs(firstDayOfMonth)).toList();
                final monthlyRevenue = monthlyOrders.fold<double>(0, (sum, o) => sum + o.grandTotal);

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _StatCard(title: "Today's Revenue", value: currencyFormatter.format(todaysRevenue), icon: Icons.monetization_on, colors: const [Color(0xFF00b09b), Color(0xFF96c93d)])),
                        const SizedBox(width: 16),
                        Expanded(child: _StatCard(title: 'Monthly Revenue', value: currencyFormatter.format(monthlyRevenue), icon: Icons.account_balance_wallet, colors: const [Color(0xFF2E3192), Color(0xFF1BFFFF)])),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _StatCard(title: "Today's Orders", value: '${todaysOrders.length}', icon: Icons.shopping_bag, colors: const [Color(0xFFff9966), Color(0xFFff5e62)])),
                        const SizedBox(width: 16),
                        Expanded(child: _StatCard(title: 'Pending Orders', value: '${pendingOrders.length}', icon: Icons.pending_actions, colors: const [Color(0xFFED213A), Color(0xFF93291E)])),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _StatCard(title: 'Completed', value: '${completedOrders.length}', icon: Icons.check_circle, colors: const [Color(0xFF11998e), Color(0xFF38ef7d)])),
                        const SizedBox(width: 16),
                        Expanded(child: _StatCard(title: 'Total Products', value: productsAsync.maybeWhen(data: (p) => '${p.length}', orElse: () => '...'), icon: Icons.inventory_2, colors: const [Color(0xFF8E2DE2), Color(0xFF4A00E0)])),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _StatCard(title: 'Customers', value: customersAsync.maybeWhen(data: (c) => '${c.length}', orElse: () => '...'), icon: Icons.people, colors: const [Color(0xFF4b6cb7), Color(0xFF182848)])),
                        const SizedBox(width: 16),
                        const Spacer(),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final List<Color> colors;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.last.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(icon, color: Colors.white.withOpacity(0.2), size: 80),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title, 
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.2), 
                        maxLines: 2, 
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
