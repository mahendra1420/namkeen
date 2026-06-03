import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'retailer_home.dart';
import 'catalog_screen.dart';
import 'cart_screen.dart';
import 'order_history_screen.dart';
import 'account_screen.dart';
import '../../shared/providers/cart_provider.dart';

final retailerNavIndexProvider = StateProvider<int>((ref) => 0);

class RetailerMainLayout extends ConsumerStatefulWidget {
  const RetailerMainLayout({super.key});

  @override
  ConsumerState<RetailerMainLayout> createState() => _RetailerMainLayoutState();
}

class _RetailerMainLayoutState extends ConsumerState<RetailerMainLayout> {
  final List<Widget> _screens = [
    const RetailerHomeScreen(),
    const CatalogScreen(),
    const CartScreen(),
    const OrderHistoryScreen(),
    const AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(retailerNavIndexProvider);
    final cartItems = ref.watch(cartProvider);
    final totalItems = cartItems.fold<double>(0, (sum, item) => sum + item.quantity).toInt();

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Colors.white.withValues(alpha: 0.9),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
                  _buildNavItem(1, Icons.grid_view_outlined, Icons.grid_view, 'Catalog'),
                  _buildNavItem(2, Icons.shopping_cart_outlined, Icons.shopping_cart, 'Cart', badge: totalItems),
                  _buildNavItem(3, Icons.receipt_long_outlined, Icons.receipt_long, 'Orders'),
                  _buildNavItem(4, Icons.person_outline, Icons.person, 'Account'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label, {int? badge}) {
    final currentIndex = ref.watch(retailerNavIndexProvider);
    final isActive = currentIndex == index;
    
    Widget iconWidget = Icon(isActive ? activeIcon : icon, color: isActive ? Theme.of(context).primaryColor : Colors.grey.shade500, size: 22);
    
    if (badge != null && badge > 0) {
      iconWidget = Badge(
        label: Text(badge.toString()),
        child: iconWidget,
      );
    }

    return GestureDetector(
      onTap: () => ref.read(retailerNavIndexProvider.notifier).state = index,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget,
            if (isActive) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}
