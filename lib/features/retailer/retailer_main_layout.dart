import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'retailer_home.dart';
import 'catalog_screen.dart';
import 'cart_screen.dart';
import 'order_history_screen.dart';
import '../../shared/providers/cart_provider.dart';

class RetailerMainLayout extends ConsumerStatefulWidget {
  const RetailerMainLayout({super.key});

  @override
  ConsumerState<RetailerMainLayout> createState() => _RetailerMainLayoutState();
}

class _RetailerMainLayoutState extends ConsumerState<RetailerMainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const RetailerHomeScreen(),
    const CatalogScreen(),
    const CartScreen(),
    const OrderHistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final totalItems = cartItems.fold<double>(0, (sum, item) => sum + item.quantity).toInt();

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_outlined),
              activeIcon: Icon(Icons.grid_view),
              label: 'Catalog',
            ),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: totalItems > 0,
                label: Text(totalItems.toString()),
                child: const Icon(Icons.shopping_cart_outlined),
              ),
              activeIcon: Badge(
                isLabelVisible: totalItems > 0,
                label: Text(totalItems.toString()),
                child: const Icon(Icons.shopping_cart),
              ),
              label: 'Cart',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Orders',
            ),
          ],
        ),
      ),
    );
  }
}
