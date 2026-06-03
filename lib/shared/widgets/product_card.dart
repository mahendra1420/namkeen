import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/product_model.dart';
import '../providers/cart_provider.dart';

class ProductCard extends ConsumerStatefulWidget {
  final ProductModel product;
  final String heroTagPrefix;

  const ProductCard({super.key, required this.product, this.heroTagPrefix = ''});

  @override
  ConsumerState<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<ProductCard> {
  double _quantity = 1.0;

  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.95),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        context.push('/product-details', extra: {'product': widget.product, 'heroTagPrefix': widget.heroTagPrefix});
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Container(
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
            child: Hero(
              tag: '${widget.heroTagPrefix}product_image_${widget.product.id}',
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
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name, 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: -0.3), 
                        maxLines: 1, 
                        overflow: TextOverflow.ellipsis
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '₹${widget.product.price} / ${widget.product.unit}', 
                          style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.w900, fontSize: 12)
                        ),
                      ),
                    ],
                  ),
                  if (widget.product.stock > 0)
                    Builder(
                      builder: (context) {
                        final cartItems = ref.watch(cartProvider);
                        final cartItemIndex = cartItems.indexWhere((item) => item.product.id == widget.product.id);
                        final bool isInCart = cartItemIndex >= 0;
                        final double cartQuantity = isInCart ? cartItems[cartItemIndex].quantity : 0;

                        if (isInCart) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              InkWell(
                                onTap: () {
                                  if (cartQuantity > 1) {
                                    ref.read(cartProvider.notifier).updateQuantity(widget.product.id, cartQuantity - 1);
                                  } else {
                                    ref.read(cartProvider.notifier).removeFromCart(widget.product.id);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                                  child: const Icon(Icons.remove, size: 16, color: Colors.black),
                                ),
                              ),
                              Text('${cartQuantity.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              InkWell(
                                onTap: () => ref.read(cartProvider.notifier).updateQuantity(widget.product.id, cartQuantity + 1),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(color: Theme.of(context).primaryColor, shape: BoxShape.circle),
                                  child: const Icon(Icons.add, size: 16, color: Colors.white),
                                ),
                              ),
                            ],
                          );
                        }

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: _quantity > 1 ? () => setState(() => _quantity--) : null,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Icon(Icons.remove, size: 14, color: _quantity > 1 ? Colors.black87 : Colors.grey),
                                    ),
                                  ),
                                  Text('${_quantity.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  InkWell(
                                    onTap: () => setState(() => _quantity++),
                                    child: const Padding(
                                      padding: EdgeInsets.all(8),
                                      child: Icon(Icons.add, size: 14, color: Colors.black87),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                ref.read(cartProvider.notifier).addToCart(widget.product, _quantity);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${_quantity.toInt()}x ${widget.product.name} added!'), 
                                    duration: const Duration(seconds: 1),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                );
                                setState(() { _quantity = 1.0; });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: Theme.of(context).primaryColor, shape: BoxShape.circle),
                                child: const Icon(Icons.shopping_bag_outlined, size: 16, color: Colors.white),
                              ),
                            ),
                          ],
                        );
                      }
                    )
                  else
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 8.0),
                        child: Text('OUT OF STOCK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red)),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
      ),
      ),
    );
  }
}
