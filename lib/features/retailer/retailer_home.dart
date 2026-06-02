import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/models/product_model.dart';
import '../../shared/providers/cart_provider.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/product_provider.dart';
import '../../shared/providers/banner_provider.dart';
import '../../shared/providers/retailer_dashboard_provider.dart';

import '../../shared/widgets/product_card.dart';

class RetailerHomeScreen extends ConsumerWidget {
  const RetailerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productProvider);
    final user = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(user?.shopName ?? 'Retailer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
          )
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildBannerCarousel(ref),
          ),
          
          // Buy Again Section
          SliverToBoxAdapter(
            child: ref.watch(recentlyOrderedProvider).when(
              data: (recentProducts) {
                if (recentProducts.isEmpty) return const SizedBox.shrink();
                return _buildHorizontalSection('Buy Again', recentProducts, ref);
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),

          // Best Sellers Section
          SliverToBoxAdapter(
            child: ref.watch(bestSellingProductsProvider).when(
              data: (bestSellers) {
                if (bestSellers.isEmpty) return const SizedBox.shrink();
                return _buildHorizontalSection('Best Sellers', bestSellers, ref);
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),

          // New Arrivals Section (using active products reversed)
          products.when(
            data: (productList) {
              if (productList.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
              final newArrivals = productList.reversed.take(5).toList();
              return SliverToBoxAdapter(
                child: _buildHorizontalSection('New Arrivals', newArrivals, ref),
              );
            },
            loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),

          // All Products Header
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text('All Products', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),

          // All Products Grid/List
          products.when(
            data: (productList) {
              if (productList.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: Text('No products available.')),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.70,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final product = productList[index];
                      return ProductCard(product: product);
                    },
                    childCount: productList.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (error, stack) => SliverFillRemaining(child: Center(child: Text('Error: $error'))),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)), // Bottom padding
        ],
      ),
    );
  }

  Widget _buildHorizontalSection(String title, List<ProductModel> productsList, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: 260,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: productsList.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: SizedBox(
                  width: 160,
                  child: ProductCard(product: productsList[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBannerCarousel(WidgetRef ref) {
    final bannersAsync = ref.watch(bannerProvider);
    
    return bannersAsync.when(
      data: (banners) {
        final activeBanners = banners.where((b) => b.isActive).toList();
        if (activeBanners.isEmpty) return const SizedBox.shrink();
        
        return Container(
          height: 180,
          margin: const EdgeInsets.only(top: 16),
          child: PageView.builder(
            itemCount: activeBanners.length,
            itemBuilder: (context, index) {
              final banner = activeBanners[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: banner.imageUrl.startsWith('http')
                      ? Image.network(banner.imageUrl, fit: BoxFit.cover)
                      : Image.memory(
                          base64Decode(banner.imageUrl), 
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                          ),
                        ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(height: 180, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _ProductCard extends ConsumerStatefulWidget {
  final ProductModel product;

  const _ProductCard({required this.product});

  @override
  ConsumerState<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<_ProductCard> {
  double _quantity = 1.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 4,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: widget.product.imageUrl != null
                  ? (widget.product.imageUrl!.startsWith('http')
                      ? Image.network(widget.product.imageUrl!, fit: BoxFit.cover)
                      : Image.memory(base64Decode(widget.product.imageUrl!), fit: BoxFit.cover, errorBuilder: (context, e, st) => Container(color: Colors.grey.shade100, child: const Icon(Icons.image, color: Colors.grey))))
                  : Container(
                      color: Colors.grey.shade100,
                      child: const Icon(Icons.image, size: 40, color: Colors.grey),
                    ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.name, 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.2), 
                          maxLines: 1, 
                          overflow: TextOverflow.ellipsis
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '₹${widget.product.price}/${widget.product.unit}', 
                          style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.w800, fontSize: 13)
                        ),
                      ],
                    ),
                  ),
                  if (widget.product.stock > 0)
                    Row(
                      children: [
                        Container(
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: _quantity > 1 ? () => setState(() => _quantity--) : null,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  child: Icon(Icons.remove, size: 16, color: _quantity > 1 ? Colors.black87 : Colors.grey),
                                ),
                              ),
                              Text('${_quantity.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              InkWell(
                                onTap: () => setState(() => _quantity++),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 6),
                                  child: Icon(Icons.add, size: 16, color: Colors.black87),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SizedBox(
                            height: 30,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                ref.read(cartProvider.notifier).addToCart(widget.product, _quantity);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${_quantity.toInt()}x ${widget.product.name} added to cart!'), 
                                    duration: const Duration(seconds: 1),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                );
                                // Reset after adding
                                setState(() { _quantity = 1.0; });
                              },
                              child: const Text('ADD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 30,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: Colors.grey.shade400,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: null,
                        child: const Text('OUT OF STOCK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

