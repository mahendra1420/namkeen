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

class RetailerHomeScreen extends ConsumerStatefulWidget {
  const RetailerHomeScreen({super.key});

  @override
  ConsumerState<RetailerHomeScreen> createState() => _RetailerHomeScreenState();
}

class _RetailerHomeScreenState extends ConsumerState<RetailerHomeScreen> {
  int _currentBannerIndex = 0;

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productProvider);
    final user = ref.watch(authProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Custom Header
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 60, 16, 24),
              decoration: const BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6200EA), Color(0xFF9C27B0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        child: const Icon(Icons.person, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Good Morning,', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                          Text(user?.name ?? 'Retailer', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                      onPressed: () {},
                    ),
                  )
                ],
              ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: _buildBannerCarousel(ref),
          ),
          
          // Buy Again Section
          SliverToBoxAdapter(
            child: ref.watch(recentlyOrderedProvider).when(
              data: (recentProducts) {
                if (recentProducts.isEmpty) return const SizedBox.shrink();
                return _buildHorizontalSection('Buy Again', recentProducts, ref, 'buy_again_');
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
                return _buildHorizontalSection('Best Sellers', bestSellers, ref, 'best_sellers_');
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
                child: _buildHorizontalSection('New Arrivals', newArrivals, ref, 'new_arrivals_'),
              );
            },
            loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),

          // All Products Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: const Color(0xFF2E3192).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.grid_view, color: Color(0xFF2E3192), size: 18),
                  ),
                  const SizedBox(width: 8),
                  const Text('All Products', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
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
                      return ProductCard(product: product, heroTagPrefix: 'featured_');
                    },
                    childCount: productList.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (error, stack) => SliverFillRemaining(child: Center(child: Text('Error: $error'))),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)), // Bottom padding for floating nav bar
        ],
      ),
    );
  }

  Widget _buildHorizontalSection(String title, List<ProductModel> productsList, WidgetRef ref, String prefix) {
    IconData sectionIcon = Icons.star;
    if (title.contains('Buy Again')) sectionIcon = Icons.history;
    if (title.contains('New')) sectionIcon = Icons.new_releases;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: const Color(0xFF2E3192).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Icon(sectionIcon, color: const Color(0xFF2E3192), size: 18),
                  ),
                  const SizedBox(width: 8),
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              Text('See All', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
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
                  child: ProductCard(product: productsList[index], heroTagPrefix: prefix),
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
        
        return Column(
          children: [
            Container(
              height: 180,
              margin: const EdgeInsets.only(top: 16),
              child: PageView.builder(
                itemCount: activeBanners.length,
                onPageChanged: (index) {
                  setState(() => _currentBannerIndex = index);
                },
                itemBuilder: (context, index) {
                  final banner = activeBanners[index];
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: _currentBannerIndex == index ? 0 : 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        if (_currentBannerIndex == index)
                          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
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
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(activeBanners.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentBannerIndex == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentBannerIndex == index ? const Color(0xFF2E3192) : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ],
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

