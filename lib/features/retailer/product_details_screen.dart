import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/product_model.dart';
import '../../shared/providers/cart_provider.dart';

class ProductDetailsScreen extends ConsumerStatefulWidget {
  final ProductModel product;
  final String heroTagPrefix;

  const ProductDetailsScreen({super.key, required this.product, this.heroTagPrefix = ''});

  @override
  ConsumerState<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  late double _quantity;

  @override
  void initState() {
    super.initState();
    _quantity = widget.product.minOrderQuantity;
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final isOutOfStock = product.stock <= 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Image
            Hero(
              tag: '${widget.heroTagPrefix}product_image_${product.id}',
              child: Container(
                height: 350,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                ),
                child: product.imageUrl != null
                    ? (product.imageUrl!.startsWith('http')
                        ? Image.network(product.imageUrl!, fit: BoxFit.cover)
                        : Image.memory(base64Decode(product.imageUrl!), fit: BoxFit.cover, errorBuilder: (context, e, st) => const Icon(Icons.image, size: 100, color: Colors.grey)))
                    : const Icon(Icons.image, size: 100, color: Colors.grey),
              ),
            ),
            
            // Details Section
            Container(
              transform: Matrix4.translationValues(0, -20, 0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                product.category.toUpperCase(),
                                style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(product.name, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Text('₹${product.price}/${product.unit}', style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 24, fontWeight: FontWeight.w900)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Description
                  const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    product.description != null && product.description!.isNotEmpty 
                        ? product.description! 
                        : 'No description available for this product.',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 16, height: 1.5),
                  ),
                  
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // Meta details
                  Row(
                    children: [
                      _buildMetaBox(Icons.inventory, 'Available Stock', '${product.stock} ${product.unit}', isOutOfStock ? Colors.red : Colors.green),
                      const SizedBox(width: 16),
                      _buildMetaBox(Icons.shopping_bag, 'Min Order Qty', '${product.minOrderQuantity} ${product.unit}', Colors.blue),
                    ],
                  ),
                  const SizedBox(height: 100), // padding for bottom bar
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          child: isOutOfStock 
            ? SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade400,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: null,
                  child: const Text('OUT OF STOCK', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              )
            : Row(
                children: [
                  // Quantity Selector
                  Container(
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.remove, color: _quantity > product.minOrderQuantity ? Colors.black87 : Colors.grey),
                          onPressed: _quantity > product.minOrderQuantity ? () => setState(() => _quantity--) : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text('${_quantity.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, color: Colors.black87),
                          onPressed: () => setState(() => _quantity++),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Add to Cart Button
                  Expanded(
                    child: Container(
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Theme.of(context).primaryColor, Colors.deepOrangeAccent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            ref.read(cartProvider.notifier).addToCart(product, _quantity);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${_quantity.toInt()}x ${product.name} added to cart!'), 
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          },
                          child: Center(
                            child: Text('ADD TO CART (₹${(product.price * _quantity).toStringAsFixed(0)})', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
        ),
      ),
    );
  }

  Widget _buildMetaBox(IconData icon, String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
