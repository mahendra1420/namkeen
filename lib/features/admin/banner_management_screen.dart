import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../shared/providers/banner_provider.dart';
import '../../shared/models/banner_model.dart';

class BannerManagementScreen extends ConsumerWidget {
  const BannerManagementScreen({super.key});

  void _showAddBannerDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const _AddBannerDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannersAsync = ref.watch(bannerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Banner Management')),
      body: bannersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (banners) {
          if (banners.isEmpty) {
            return const Center(child: Text('No banners active. Add some festival offers!'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: banners.length,
            itemBuilder: (context, index) {
              final banner = banners[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: banner.imageUrl.startsWith('http')
                          ? Image.network(banner.imageUrl, height: 150, fit: BoxFit.cover)
                          : Image.memory(base64Decode(banner.imageUrl), height: 150, fit: BoxFit.cover),
                    ),
                    ListTile(
                      title: Text(banner.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(banner.isActive ? 'Active' : 'Disabled', style: TextStyle(color: banner.isActive ? Colors.green : Colors.red)),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'toggle') {
                            final updated = BannerModel(
                              id: banner.id,
                              title: banner.title,
                              imageUrl: banner.imageUrl,
                              isActive: !banner.isActive,
                            );
                            await ref.read(bannerServiceProvider).updateBanner(updated);
                          } else if (value == 'delete') {
                            await ref.read(bannerServiceProvider).removeBanner(banner.id);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(value: 'toggle', child: Text(banner.isActive ? 'Disable' : 'Enable')),
                          const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBannerDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _AddBannerDialog extends ConsumerStatefulWidget {
  const _AddBannerDialog();

  @override
  ConsumerState<_AddBannerDialog> createState() => _AddBannerDialogState();
}

class _AddBannerDialogState extends ConsumerState<_AddBannerDialog> {
  final _titleController = TextEditingController();
  File? _imageFile;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    // Compress heavily for Firestore Base64 string limit
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50, maxWidth: 800);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submit() async {
    if (_titleController.text.isEmpty || _imageFile == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final bytes = await _imageFile!.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      final banner = BannerModel(
        id: '', 
        title: _titleController.text.trim(), 
        imageUrl: base64Image,
      );
      
      await ref.read(bannerServiceProvider).addBanner(banner);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Banner'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Banner Title (e.g. Diwali Offer)'),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(_imageFile!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add_a_photo, color: Colors.grey),
                          Text('Select Image', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Upload'),
        ),
      ],
    );
  }
}
