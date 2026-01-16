
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/api_client.dart';
import '../../core/services/image_upload_service.dart';
import 'package:mobile/core/theme/app_colors.dart';
import '../auth/providers/auth_provider.dart';

class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  File? _idImage;
  File? _selfieImage;
  bool _isUploading = false;

  Future<void> _pickImage(ImageSource source, bool isIdCard) async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: source);
    
    if (photo != null) {
      setState(() {
        if (isIdCard) {
          _idImage = File(photo.path);
        } else {
          _selfieImage = File(photo.path);
        }
      });
    }
  }

  void _showImageSourceDialog(bool isIdCard) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Wrap(
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: const BoxDecoration(color: Color(0xFFE2E8F0), borderRadius: BorderRadius.all(Radius.circular(2))),
              ),
            ),
            _buildSourceTile(
              icon: Icons.camera_alt_outlined,
              title: 'Take a Photo',
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera, isIdCard);
              },
            ),
            const SizedBox(height: 12),
            _buildSourceTile(
              icon: Icons.photo_library_outlined,
              title: 'Choose from Gallery',
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery, isIdCard);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceTile({required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.05), shape: BoxShape.circle),
        child: Icon(icon, color: AppColors.primary, size: 24),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.primary)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  Future<void> _submitVerification() async {
    if (_idImage == null || _selfieImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload both ID Card and Selfie'), backgroundColor: AppColors.primary, behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final uploadService = ref.read(imageUploadServiceProvider);

      final idCardUrl = await uploadService.uploadImage(_idImage!);
      if (idCardUrl == null) throw Exception("Failed to upload ID Card");

      final selfieUrl = await uploadService.uploadImage(_selfieImage!);
      if (selfieUrl == null) throw Exception("Failed to upload Selfie");

      final apiClient = ref.read(apiClientProvider);
      await apiClient.patch('/user/verification', data: { 
        'idCardUrl': idCardUrl,
        'selfieUrl': selfieUrl,
      });

      ref.invalidate(currentUserProvider);
      if (mounted) context.go('/waiting'); 
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.primary, behavior: SnackBarBehavior.floating));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Verification', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 18)),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 16, 32, 24),
            child: Column(
              children: [
                const Text(
                  'Verify Identity',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: -0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  'To ensure a safe community, upload your student documents for moderation.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                _buildUploadCard(
                  title: 'Student ID Card',
                  subtitle: 'Front side of your official ID',
                  icon: Icons.badge_outlined,
                  image: _idImage,
                  onTap: () => _showImageSourceDialog(true),
                ),
                const SizedBox(height: 24),
                _buildUploadCard(
                  title: 'Real-time Selfie',
                  subtitle: 'Face must be clearly visible',
                  icon: Icons.face_retouching_natural,
                  image: _selfieImage,
                  onTap: () => _showImageSourceDialog(false),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: (_idImage != null && _selfieImage != null && !_isUploading) ? _submitVerification : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  disabledBackgroundColor: AppColors.primary.withOpacity(0.1),
                ),
                child: _isUploading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('SUBMIT FOR REVIEW', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required File? image,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: image != null ? Colors.white : AppColors.cardPink.withOpacity(0.35),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: image != null ? AppColors.accent : AppColors.primary.withOpacity(0.05),
            width: image != null ? 2 : 1.5,
          ),
        ),
        child: image != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(image, fit: BoxFit.cover),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20, right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.edit_rounded, color: AppColors.primary, size: 20),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: AppColors.accent.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 5)),
                    ],
                  ),
                  child: Icon(icon, size: 36, color: AppColors.primary),
                ),
                const SizedBox(height: 20),
                Text(title, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 18)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
      ),
    );
  }
}
