import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/models/order_model.dart';
import '../../shared/providers/order_provider.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Sales Report', icon: Icon(Icons.bar_chart)),
            Tab(text: 'Product Report', icon: Icon(Icons.inventory)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSalesReport(),
          _buildProductReport(),
        ],
      ),
    );
  }

  Widget _buildSalesReport() {
    final ordersAsync = ref.watch(orderProvider);
    final currencyFormatter = NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');

    return ordersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
      data: (orders) {
        // Filter out rejected or pending if we only want actual sales. 
        // For wholesale, delivered or accepted usually count as sales.
        final validOrders = orders.where((o) => o.status == OrderStatus.completed).toList();

        final now = DateTime.now();
        final startOfDay = DateTime(now.year, now.month, now.day);
        
        // Calculate start of week (assuming Monday start)
        final daysFromMonday = now.weekday - 1;
        final startOfWeek = startOfDay.subtract(Duration(days: daysFromMonday));
        final startOfMonth = DateTime(now.year, now.month, 1);
        final startOfYear = DateTime(now.year, 1, 1);

        double dailySales = 0;
        double weeklySales = 0;
        double monthlySales = 0;
        double yearlySales = 0;

        for (var order in validOrders) {
          if (!order.date.isBefore(startOfDay)) dailySales += order.grandTotal;
          if (!order.date.isBefore(startOfWeek)) weeklySales += order.grandTotal;
          if (!order.date.isBefore(startOfMonth)) monthlySales += order.grandTotal;
          if (!order.date.isBefore(startOfYear)) yearlySales += order.grandTotal;
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SalesTile(title: 'Daily Sales (Today)', amount: currencyFormatter.format(dailySales), icon: Icons.today, color: Colors.blue),
            _SalesTile(title: 'Weekly Sales (This Week)', amount: currencyFormatter.format(weeklySales), icon: Icons.date_range, color: Colors.green),
            _SalesTile(title: 'Monthly Sales (This Month)', amount: currencyFormatter.format(monthlySales), icon: Icons.calendar_month, color: Colors.orange),
            _SalesTile(title: 'Yearly Sales (This Year)', amount: currencyFormatter.format(yearlySales), icon: Icons.auto_graph, color: Colors.purple),
          ],
        );
      },
    );
  }

  Widget _buildProductReport() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchTopProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final topProducts = snapshot.data ?? [];
        if (topProducts.isEmpty) {
          return const Center(child: Text('No sales data available.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: topProducts.length,
          itemBuilder: (context, index) {
            final product = topProducts[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                title: Text(product['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                trailing: Text('${product['quantity']} kg', style: const TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold)),
                subtitle: const Text('Total Sold'),
              ),
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchTopProducts() async {
    final db = FirebaseFirestore.instance;
    final ordersSnapshot = await db.collection('orders')
        .where('status', isEqualTo: OrderStatus.completed.name)
        .get();

    Map<String, double> productSales = {};

    // 2. Fetch items for each order
    for (var doc in ordersSnapshot.docs) {
      final itemsList = (doc.data()['items'] as List<dynamic>?) ?? [];
      
      for (var itemData in itemsList) {
        final productName = itemData['product']['name'] as String;
        final qty = (itemData['quantity'] as num).toDouble();
        
        productSales[productName] = (productSales[productName] ?? 0) + qty;
      }
    }

    // 3. Sort by quantity descending
    final sortedList = productSales.entries.map((e) => {
      'name': e.key,
      'quantity': e.value,
    }).toList();

    sortedList.sort((a, b) => (b['quantity'] as double).compareTo(a['quantity'] as double));

    return sortedList;
  }
}

class _SalesTile extends StatelessWidget {
  final String title;
  final String amount;
  final IconData icon;
  final Color color;

  const _SalesTile({required this.title, required this.amount, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        subtitle: Text(amount, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
