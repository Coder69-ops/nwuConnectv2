
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/image_upload_service.dart';
import '../../../core/widgets/cached_avatar.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/feed_provider.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _contentController = TextEditingController();
  String _visibility = 'public'; // public, friends, department
  List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  bool _isSubmitting = false;

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _selectedImages.add(image);
      });
    }
  }

  Future<void> _submitPost() async {
    if (_contentController.text.trim().isEmpty && _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add some content or an image')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 1. Upload Images
      List<String> uploadedUrls = [];
      if (_selectedImages.isNotEmpty) {
        final imageUploadService = ref.read(imageUploadServiceProvider);
        for (var image in _selectedImages) {
          // Simplified: Assuming jpeg for picked images for now, ideally strictly detect
          final url = await imageUploadService.uploadImage(File(image.path));
          if (url != null) {
            uploadedUrls.add(url);
          }
        }
      }

      // 2. Create Post
      final success = await ref.read(createPostProvider.notifier).createPost(
            content: _contentController.text.trim(),
            imageUrls: uploadedUrls,
            visibility: _visibility,
          );

      if (success) {
        if (mounted) context.pop();
      } else {
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Failed to create post')),
           );
         }
      }
    } catch (e, st) {
      debugPrint('CreatePost Error: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.value;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            CachedAvatar(
              imageUrl: user?.photoUrl ?? '',
              radius: 18,
              fallbackText: user?.name ?? 'User',
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user?.name ?? 'User',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                _buildVisibilityChip(),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        shadowColor: Colors.black12,
      ),
      body: user == null 
        ? const Center(child: CircularProgressIndicator()) 
        : Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Content Input
                    TextField(
                      controller: _contentController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: "What's on your mind?",
                        hintStyle: TextStyle(fontSize: 16, color: Colors.grey),
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(fontSize: 16, height: 1.5),
                      maxLines: null,
                      minLines: 3,
                    ),
                    const SizedBox(height: 16),
                    if (_selectedImages.isNotEmpty) _buildImagePreview(),
                  ],
                ),
              ),
            ),
            _buildMessengerBottomBar(),
          ],
        ),
    );
  }

  Widget _buildVisibilityChip() {
    return GestureDetector(
      onTap: _showVisibilitySelector,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF6C63FF).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _visibility == 'public' ? Icons.public : (_visibility == 'department' ? Icons.school : Icons.people),
              size: 10,
              color: const Color(0xFF6C63FF),
            ),
            const SizedBox(width: 3),
            Text(
              _visibility == 'public' ? 'Public' : (_visibility == 'department' ? 'Department' : 'Friends'),
              style: const TextStyle(
                color: Color(0xFF6C63FF),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVisibilitySelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Who can see this post?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildVisibilityOption(
                icon: Icons.public,
                color: Colors.blue,
                title: 'Public',
                subtitle: 'Anyone on campus can see this',
                value: 'public',
              ),
              _buildVisibilityOption(
                icon: Icons.school,
                color: Colors.orange,
                title: 'Department Only',
                subtitle: 'Only students in your department',
                value: 'department',
              ),
              _buildVisibilityOption(
                icon: Icons.people,
                color: Colors.green,
                title: 'Friends Only',
                subtitle: 'Only your connected friends',
                value: 'friends',
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVisibilityOption({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String value,
  }) {
    final isSelected = _visibility == value;
    return InkWell(
      onTap: () {
        setState(() => _visibility = value);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMessengerBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Camera Button
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt, color: Color(0xFF6C63FF)),
                tooltip: 'Camera',
              ),
            ),
            const SizedBox(width: 8),
            // Gallery Button
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.image, color: Color(0xFF6C63FF)),
                tooltip: 'Gallery',
              ),
            ),
            const SizedBox(width: 12),
            // Character Count
            Text(
              '${_contentController.text.length}/280',
              style: TextStyle(
                fontSize: 12,
                color: _contentController.text.length > 280 ? Colors.red : Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            // Post Button
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: ElevatedButton(
                onPressed: _isSubmitting || (_contentController.text.trim().isEmpty && _selectedImages.isEmpty)
                    ? null
                    : _submitPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  elevation: 0,
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.send, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Post',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
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

  Widget _buildImagePreview() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _selectedImages.length == 1 ? 1 : 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1,
        ),
        itemCount: _selectedImages.length > 4 ? 4 : _selectedImages.length,
        itemBuilder: (context, index) {
          return Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(_selectedImages[index].path),
                  fit: BoxFit.cover,
                ),
              ),
              // Overlay for more images
              if (index == 3 && _selectedImages.length > 4)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    color: Colors.black54,
                    child: Center(
                      child: Text(
                        '+${_selectedImages.length - 3}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              // Remove button
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: () => setState(() => _selectedImages.removeAt(index)),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
