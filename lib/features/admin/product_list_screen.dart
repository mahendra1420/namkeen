import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/models/product_model.dart';
import '../../shared/providers/product_provider.dart';

class ProductListScreen extends ConsumerWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Product Management')),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (products) {
          if (products.isEmpty) {
            return const Center(child: Text('No products available.'));
          }
          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: product.imageUrl != null 
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: product.imageUrl!.startsWith('http')
                                ? Image.network(product.imageUrl!, fit: BoxFit.cover)
                                : Image.memory(base64Decode(product.imageUrl!), fit: BoxFit.cover),
                          )
                        : const Icon(Icons.image, color: Colors.grey),
                  ),
                  title: Text(
                    product.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: product.isActive ? null : TextDecoration.lineThrough,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('₹${product.price} / ${product.unit}', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('${product.stock} ${product.unit} Available', style: const TextStyle(color: Colors.green)),
                      if (!product.isActive)
                        const Text('Disabled', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        context.push('/add-product', extra: product);
                      } else if (value == 'toggle') {
                        final updatedProduct = ProductModel(
                          id: product.id,
                          name: product.name,
                          price: product.price,
                          unit: product.unit,
                          imageUrl: product.imageUrl,
                          category: product.category,
                          stock: product.stock,
                          isActive: !product.isActive,
                        );
                        await ref.read(productServiceProvider).updateProduct(updatedProduct);
                      } else if (value == 'delete') {
                        await ref.read(productServiceProvider).removeProduct(product.id);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit Product')),
                      PopupMenuItem(value: 'toggle', child: Text(product.isActive ? 'Disable Product' : 'Enable Product')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete Product', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-product'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
