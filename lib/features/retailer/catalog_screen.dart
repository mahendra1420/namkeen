import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/providers/category_provider.dart';
import '../../shared/providers/product_provider.dart';
import '../../shared/widgets/product_card.dart';

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  String? _selectedCategoryName;
  String _searchQuery = '';
  bool _hideOutOfStock = false;
  String _sortOption = 'none'; // 'none', 'low_to_high', 'high_to_low'

  void _openFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Filters & Sorting', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  SwitchListTile(
                    title: const Text('Hide Out of Stock'),
                    value: _hideOutOfStock,
                    onChanged: (val) {
                      setModalState(() => _hideOutOfStock = val);
                      setState(() => _hideOutOfStock = val);
                    },
                  ),
                  const Divider(),
                  const SizedBox(height: 12),
                  const Text('Sort by Price', style: TextStyle(fontWeight: FontWeight.bold)),
                  RadioListTile<String>(
                    title: const Text('Default'),
                    value: 'none',
                    groupValue: _sortOption,
                    onChanged: (val) {
                      if (val == null) return;
                      setModalState(() => _sortOption = val);
                      setState(() => _sortOption = val);
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Price: Low to High'),
                    value: 'low_to_high',
                    groupValue: _sortOption,
                    onChanged: (val) {
                      if (val == null) return;
                      setModalState(() => _sortOption = val);
                      setState(() => _sortOption = val);
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Price: High to Low'),
                    value: 'high_to_low',
                    groupValue: _sortOption,
                    onChanged: (val) {
                      if (val == null) return;
                      setModalState(() => _sortOption = val);
                      setState(() => _sortOption = val);
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryProvider);
    final productsAsync = ref.watch(productProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Catalog'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _openFilterBottomSheet,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search products (e.g. Sing, Dariya)',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          // Horizontal Category Filter
          SizedBox(
            height: 60,
            child: categoriesAsync.when(
              data: (categories) {
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: categories.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      final isSelected = _selectedCategoryName == null;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: const Text('All Products'),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedCategoryName = null);
                          },
                        ),
                      );
                    }
                    final category = categories[index - 1];
                    final isSelected = _selectedCategoryName == category.name;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(category.name),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedCategoryName = category.name);
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => const Center(child: Text('Error loading categories')),
            ),
          ),
          
          const Divider(height: 1),

          // Product Grid
          Expanded(
            child: productsAsync.when(
              data: (products) {
                var filteredProducts = products.where((p) {
                  final matchesCategory = _selectedCategoryName == null || p.category == _selectedCategoryName;
                  final matchesSearch = _searchQuery.isEmpty || p.name.toLowerCase().contains(_searchQuery.toLowerCase());
                  final matchesStock = !_hideOutOfStock || p.stock > 0;
                  return matchesCategory && matchesSearch && matchesStock;
                }).toList();

                if (_sortOption == 'low_to_high') {
                  filteredProducts.sort((a, b) => a.price.compareTo(b.price));
                } else if (_sortOption == 'high_to_low') {
                  filteredProducts.sort((a, b) => b.price.compareTo(a.price));
                }

                if (filteredProducts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text('No products found in this category.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.70,
                  ),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    return ProductCard(product: filteredProducts[index]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
