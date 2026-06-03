import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/models/user_model.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late TextEditingController _nameController;
  late TextEditingController _surnameController;
  late TextEditingController _shopNameController;
  late TextEditingController _phoneController;
  late TextEditingController _secondPhoneController;
  late TextEditingController _gstController;
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider);
    _nameController = TextEditingController(text: user?.name ?? '');
    _surnameController = TextEditingController(text: user?.surname ?? '');
    _shopNameController = TextEditingController(text: user?.shopName ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _secondPhoneController = TextEditingController(text: user?.secondPhone ?? '');
    _gstController = TextEditingController(text: user?.gstNumber ?? '');
    _addressController = TextEditingController(text: user?.address ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _shopNameController.dispose();
    _phoneController.dispose();
    _secondPhoneController.dispose();
    _gstController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    final currentUser = ref.read(authProvider);
    if (currentUser == null) return;
    
    final updatedUser = UserModel(
      id: currentUser.id,
      name: _nameController.text.trim(),
      surname: _surnameController.text.trim().isEmpty ? null : _surnameController.text.trim(),
      phone: _phoneController.text.trim(),
      secondPhone: _secondPhoneController.text.trim().isEmpty ? null : _secondPhoneController.text.trim(),
      password: currentUser.password,
      role: currentUser.role,
      shopName: _shopNameController.text.trim(),
      gstNumber: _gstController.text.trim().isEmpty ? null : _gstController.text.trim(),
      address: _addressController.text.trim(),
      isApproved: currentUser.isApproved,
      isBlocked: currentUser.isBlocked,
      creditBalance: currentUser.creditBalance,
      creditLimit: currentUser.creditLimit,
    );
    
    final success = await ref.read(authProvider.notifier).updateProfile(updatedUser);
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!')));
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update profile.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'First Name', border: OutlineInputBorder()),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _surnameController,
                    decoration: const InputDecoration(labelText: 'Last Name', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _shopNameController,
                    decoration: const InputDecoration(labelText: 'Shop Name', border: OutlineInputBorder()),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder()),
                    keyboardType: TextInputType.phone,
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _secondPhoneController,
                    decoration: const InputDecoration(labelText: 'Alt Phone (Optional)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _gstController,
                    decoration: const InputDecoration(labelText: 'GST Number', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder()),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('SAVE CHANGES', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ),
                  )
                ],
              ),
            ),
          ),
    );
  }
}
