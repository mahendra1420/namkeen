import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../shared/services/cloudinary_service.dart';
import '../../shared/models/product_model.dart';
import '../../shared/providers/product_provider.dart';
import '../../shared/providers/category_provider.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  final ProductModel? productToEdit;

  const AddProductScreen({super.key, this.productToEdit});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _descController = TextEditingController();
  final _moqController = TextEditingController();
  final _discountThresholdController = TextEditingController();
  final _discountedPriceController = TextEditingController();
  
  String _unit = 'kg';
  String? _category;
  bool _isLoading = false;
  File? _imageFile;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    // Compress heavily to stay under Firestore 1MB limit
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 30, maxWidth: 400);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.productToEdit != null) {
      final p = widget.productToEdit!;
      _nameController.text = p.name;
      _priceController.text = p.price.toString();
      _category = p.category;
      _stockController.text = p.stock.toString();
      _unit = p.unit;
      _descController.text = p.description ?? '';
      _moqController.text = p.minOrderQuantity.toString();
      _discountThresholdController.text = p.discountThreshold?.toString() ?? '';
      _discountedPriceController.text = p.discountedPrice?.toString() ?? '';
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_category == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final isEditing = widget.productToEdit != null;
      String? uploadedImageUrl = isEditing ? widget.productToEdit!.imageUrl : null;

      if (_imageFile != null) {
        // Upload image to Cloudinary
        uploadedImageUrl = await CloudinaryService.uploadImage(_imageFile!);
      }

      final product = ProductModel(
        id: isEditing ? widget.productToEdit!.id : '', 
        name: _nameController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        unit: _unit,
        category: _category!,
        stock: double.tryParse(_stockController.text.trim()) ?? 0.0,
        isActive: isEditing ? widget.productToEdit!.isActive : true,
        imageUrl: uploadedImageUrl,
        description: _descController.text.trim(),
        minOrderQuantity: double.tryParse(_moqController.text.trim()) ?? 1.0,
        discountThreshold: int.tryParse(_discountThresholdController.text.trim()),
        discountedPrice: double.tryParse(_discountedPriceController.text.trim()),
      );

      if (isEditing) {
        await ref.read(productServiceProvider).updateProduct(product);
      } else {
        await ref.read(productServiceProvider).addProduct(product);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product Added Successfully!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Add New Product')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Product Name (e.g. Sing, Dariya)'),
                      validator: (value) => value == null || value.isEmpty ? 'Required field' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descController,
                      decoration: const InputDecoration(labelText: 'Description (Optional)'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            decoration: const InputDecoration(labelText: 'Price'),
                            keyboardType: TextInputType.number,
                            validator: (value) => value == null || value.isEmpty ? 'Required field' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _moqController,
                            decoration: const InputDecoration(labelText: 'Min Order Qty (MOQ)'),
                            keyboardType: TextInputType.number,
                            validator: (value) => value == null || value.isEmpty ? 'Required field' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const Text('Volume Discounts (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _discountThresholdController,
                            decoration: const InputDecoration(labelText: 'Min Qty for Discount (e.g. 50)'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _discountedPriceController,
                            decoration: const InputDecoration(labelText: 'Discounted Price (e.g. 90)'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _unit,
                      decoration: const InputDecoration(labelText: 'Unit'),
                      items: ['kg', 'gram', 'box', 'packet'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _unit = newValue!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: _imageFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(_imageFile!, fit: BoxFit.cover),
                              )
                            : (widget.productToEdit?.imageUrl != null)
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: widget.productToEdit!.imageUrl!.startsWith('http') 
                                      ? Image.network(widget.productToEdit!.imageUrl!, fit: BoxFit.cover)
                                      : Image.memory(base64Decode(widget.productToEdit!.imageUrl!), fit: BoxFit.cover),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                                      SizedBox(height: 8),
                                      Text('Tap to add product image', style: TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: categoriesAsync.when(
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (e, st) => Text('Error: $e'),
                            data: (categoriesList) {
                              if (categoriesList.isEmpty) {
                                return const Text('Please add categories first from dashboard', style: TextStyle(color: Colors.red));
                              }
                              
                              // If editing, ensure the category exists in the list, otherwise null
                              if (_category != null && !categoriesList.any((c) => c.name == _category)) {
                                _category = null;
                              }

                              return DropdownButtonFormField<String>(
                                value: _category,
                                decoration: const InputDecoration(labelText: 'Category'),
                                items: categoriesList.map((c) {
                                  return DropdownMenuItem<String>(
                                    value: c.name,
                                    child: Text(c.name),
                                  );
                                }).toList(),
                                onChanged: (newValue) {
                                  setState(() {
                                    _category = newValue;
                                  });
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _stockController,
                            decoration: const InputDecoration(labelText: 'Initial Stock'),
                            keyboardType: TextInputType.number,
                            validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        child: const Text('Save Product'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
