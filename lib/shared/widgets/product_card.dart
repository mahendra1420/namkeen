import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/product_model.dart';
import '../providers/cart_provider.dart';

class ProductCard extends ConsumerStatefulWidget {
  final ProductModel product;

  const ProductCard({super.key, required this.product});

  @override
  ConsumerState<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<ProductCard> {
  double _quantity = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push('/product-details', extra: widget.product);
      },
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
      ),
    );
  }
}
