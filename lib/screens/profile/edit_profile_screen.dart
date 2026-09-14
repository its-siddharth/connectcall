import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_utils.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/common_button.dart';
import '../../widgets/user_avatar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final success = await context.read<AuthProvider>().updateProfile(
          name: _nameController.text.trim(),
        );
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (success) {
      AppUtils.showSnackBar(context, 'Profile updated successfully');
      Navigator.of(context).pop();
    } else {
      AppUtils.showSnackBar(context, 'Failed to update profile', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Center(
                child: Stack(
                  children: [
                    UserAvatar(user: user, size: 88),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              AppTextField(
                controller: _nameController,
                label: 'Full Name',
                hint: 'Enter your name',
                prefixIcon: Icons.person_outline,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Name is required';
                  if (v.trim().length < 2) return 'Name too short';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: TextEditingController(text: user?.email ?? ''),
                label: 'Email',
                hint: 'Email address',
                prefixIcon: Icons.email_outlined,
                enabled: false,
              ),
              const SizedBox(height: 28),
              CommonButton(
                label: 'Save Changes',
                onPressed: _save,
                isLoading: _isSaving,
                fullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
