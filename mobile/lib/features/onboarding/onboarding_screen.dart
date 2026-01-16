
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../core/api_client.dart';
import '../auth/providers/auth_provider.dart';
import 'package:mobile/core/theme/app_colors.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _yearController = TextEditingController();
  final _sectionController = TextEditingController();
  String? _selectedDept;

  Future<void> _submit() async {
    if (_nameController.text.isEmpty || _selectedDept == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all required fields'), behavior: SnackBarBehavior.floating));
      return;
    }

    try {
      final apiClient = ref.read(apiClientProvider);
      
      await apiClient.patch('/user/profile', data: {
        'name': _nameController.text.trim(),
        'department': _selectedDept,
        'bio': _bioController.text.trim(),
        'studentId': _studentIdController.text.trim(),
        'year': _yearController.text.trim(),
        'section': _sectionController.text.trim(),
      });

      ref.invalidate(currentUserProvider);
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e'), backgroundColor: AppColors.primary, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Student Details', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 18)),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
        child: Column(
          children: [
            // User Persona Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.cardPink.withOpacity(0.5),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Column(
                children: [
                   Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 45,
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: const Icon(Icons.person_rounded, size: 45, color: AppColors.primary),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt_outlined, size: 16, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Build Your Identity',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.primary),
                  ),
                  Text(
                    'Tell us more about your student life',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),

            // Form Fields
            _buildTextField(
              controller: _nameController,
              label: 'Full Name *',
              hint: 'e.g. John Doe',
              icon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 20),
            
            _buildTextField(
              controller: _studentIdController,
              label: 'Student ID',
              hint: 'e.g. 123456',
              icon: Icons.badge_outlined,
            ),
            const SizedBox(height: 20),

            _buildDropdownField(),
            
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _yearController,
                    label: 'Year',
                    hint: '1.2',
                    icon: Icons.school_outlined,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _sectionController,
                    label: 'Section',
                    hint: 'A',
                    icon: Icons.groups_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _bioController,
              label: 'Bio (Optional)',
              hint: 'Something about yourself...',
              icon: Icons.edit_note_rounded,
              maxLines: 3,
            ),
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text(
                  'CONTINUE TO VERIFICATION', 
                  style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 0.5),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.5)),
            prefixIcon: Icon(icon, color: AppColors.primary.withOpacity(0.5), size: 20),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.primary.withOpacity(0.05)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
            ),
            filled: true,
            fillColor: AppColors.primary.withOpacity(0.02),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Department *',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 0.5),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.apartment_rounded, color: AppColors.primary.withOpacity(0.5), size: 20),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.primary.withOpacity(0.05)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
            ),
            filled: true,
            fillColor: AppColors.primary.withOpacity(0.02),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          ),
          value: _selectedDept,
          hint: Text('Select Department', style: TextStyle(color: AppColors.textSecondary.withOpacity(0.5), fontSize: 15)),
          items: Constants.departments.map((dept) {
            return DropdownMenuItem(value: dept, child: Text(dept, style: const TextStyle(fontWeight: FontWeight.w600)));
          }).toList(),
          onChanged: (val) => setState(() => _selectedDept = val),
        ),
      ],
    );
  }
}
