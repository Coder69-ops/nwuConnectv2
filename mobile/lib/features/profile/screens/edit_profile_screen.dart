import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/api_client.dart';
import '../../../core/services/image_upload_service.dart';
import '../providers/profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> currentProfile;

  const EditProfileScreen({super.key, required this.currentProfile});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _departmentController;
  late TextEditingController _studentIdController;
  late TextEditingController _yearController;
  late TextEditingController _sectionController;
  late TextEditingController _linkedinController;
  late TextEditingController _facebookController;
  
  File? _newAvatar;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  // Privacy settings
  late Map<String, String> _privacy;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentProfile['name'] ?? '');
    _bioController = TextEditingController(text: widget.currentProfile['bio'] ?? '');
    _departmentController = TextEditingController(text: widget.currentProfile['department'] ?? '');
    _studentIdController = TextEditingController(text: widget.currentProfile['studentId'] ?? '');
    _yearController = TextEditingController(text: widget.currentProfile['year'] ?? '');
    _sectionController = TextEditingController(text: widget.currentProfile['section'] ?? '');
    _linkedinController = TextEditingController(text: widget.currentProfile['linkedinUrl'] ?? '');
    _facebookController = TextEditingController(text: widget.currentProfile['facebookUrl'] ?? '');
    
    // Initialize privacy settings from profile or use defaults
    final currentPrivacy = widget.currentProfile['privacy'] as Map<String, dynamic>?;
    _privacy = {
      'email': currentPrivacy?['email'] ?? 'public',
      'studentId': currentPrivacy?['studentId'] ?? 'public',
      'year': currentPrivacy?['year'] ?? 'public',
      'section': currentPrivacy?['section'] ?? 'public',
      'location': currentPrivacy?['location'] ?? 'public',
      'interests': currentPrivacy?['interests'] ?? 'public',
      'department': currentPrivacy?['department'] ?? 'public',
      'bio': currentPrivacy?['bio'] ?? 'public',
    };
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _departmentController.dispose();
    _studentIdController.dispose();
    _yearController.dispose();
    _sectionController.dispose();
    _linkedinController.dispose();
    _facebookController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _newAvatar = File(image.path));
    }
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    final apiClient = ref.read(apiClientProvider);
    final imageUploadService = ref.read(imageUploadServiceProvider);

    try {
      String? photoUrl;
      if (_newAvatar != null) {
         photoUrl = await imageUploadService.uploadImage(_newAvatar!);
      }

      final data = {
        'name': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'department': _departmentController.text.trim(),
        'studentId': _studentIdController.text.trim(),
        'year': _yearController.text.trim(),
        'section': _sectionController.text.trim(),
        'linkedinUrl': _linkedinController.text.trim(),
        'facebookUrl': _facebookController.text.trim(),
        'privacy': _privacy,
      };
      
      if (photoUrl != null) {
        data['photo'] = photoUrl; 
      }

      await apiClient.patch('/user/profile', data: data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated!')));
        ref.invalidate(userProfileProvider(widget.currentProfile['userId']));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildPrivacyDropdown(String field, String label) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButton<String>(
            value: _privacy[field],
            underline: const SizedBox(),
            isDense: true,
            icon: const Icon(Icons.arrow_drop_down, size: 18),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
            items: const [
              DropdownMenuItem(value: 'public', child: Row(children: [Icon(Icons.public, size: 14), SizedBox(width: 4), Text('Public')])),
              DropdownMenuItem(value: 'friends', child: Row(children: [Icon(Icons.people, size: 14), SizedBox(width: 4), Text('Friends')])),
              DropdownMenuItem(value: 'private', child: Row(children: [Icon(Icons.lock, size: 14), SizedBox(width: 4), Text('Private')])),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _privacy[field] = value);
              }
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _isLoading ? null : _save,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: _isLoading 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                : const Text('Save', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Photo Section
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickAvatar,
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF6C63FF), width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6C63FF).withOpacity(0.2),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 55,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: _newAvatar != null 
                               ? FileImage(_newAvatar!) 
                               : (widget.currentProfile['photo'] != null && widget.currentProfile['photo'].isNotEmpty 
                                   ? NetworkImage(widget.currentProfile['photo']) 
                                   : null) as ImageProvider?,
                            child: (_newAvatar == null && (widget.currentProfile['photo'] == null || widget.currentProfile['photo'].isEmpty))
                               ? const Icon(Icons.person, size: 40, color: Colors.grey)
                               : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C63FF),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Tap to change photo', style: TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.w600, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Basic Information Card
            _buildSectionCard(
              title: 'Basic Information',
              icon: Icons.person_outline_rounded,
              children: [
                _buildTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  icon: Icons.badge_outlined,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _bioController,
                  label: 'Bio',
                  icon: Icons.edit_note_rounded,
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                _buildPrivacyDropdown('bio', 'Who can see your bio?'),
              ],
            ),
            const SizedBox(height: 16),

            // Academic Details Card
            _buildSectionCard(
              title: 'Academic Details',
              icon: Icons.school_rounded,
              children: [
                _buildTextField(
                  controller: _departmentController,
                  label: 'Department',
                  icon: Icons.account_balance_outlined,
                ),
                const SizedBox(height: 12),
                _buildPrivacyDropdown('department', 'Who can see your department?'),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _studentIdController,
                  label: 'Student ID',
                  icon: Icons.badge_outlined,
                ),
                const SizedBox(height: 12),
                _buildPrivacyDropdown('studentId', 'Who can see your student ID?'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _yearController,
                        label: 'Year',
                        icon: Icons.calendar_today_outlined,
                        hint: '1.1-4.2',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _sectionController,
                        label: 'Section',
                        icon: Icons.class_outlined,
                        hint: 'A, B, C',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildPrivacyDropdown('year', 'Who can see your batch/section?'),
              ],
            ),
            const SizedBox(height: 16),

            // Social Media Card
            _buildSectionCard(
              title: 'Connect with Me',
              icon: Icons.link_rounded,
              children: [
                _buildTextField(
                  controller: _linkedinController,
                  label: 'LinkedIn Profile',
                  icon: Icons.work_outline_rounded,
                  hint: 'https://linkedin.com/in/yourprofile',
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _facebookController,
                  label: 'Facebook Profile',
                  icon: Icons.facebook_outlined,
                  hint: 'https://facebook.com/yourprofile',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Privacy Settings Card
            _buildSectionCard(
              title: 'Privacy Settings',
              icon: Icons.lock_outline_rounded,
              children: [
                _buildPrivacyRow('Email', 'email', Icons.email_outlined),
                const SizedBox(height: 16),
                _buildPrivacyRow('Location', 'location', Icons.location_on_outlined),
                const SizedBox(height: 16),
                _buildPrivacyRow('Interests', 'interests', Icons.favorite_outline_rounded),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF6C63FF), size: 20),
              ),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, letterSpacing: -0.5)),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? hint,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFF6C63FF)),
        labelStyle: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildPrivacyRow(String label, String field, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ),
        _buildPrivacyBadge(field),
      ],
    );
  }

  Widget _buildPrivacyBadge(String field) {
    final value = _privacy[field] ?? 'public';
    final config = {
      'public': {'icon': Icons.public, 'color': Colors.green, 'label': 'Public'},
      'friends': {'icon': Icons.people, 'color': Colors.orange, 'label': 'Friends'},
      'private': {'icon': Icons.lock, 'color': Colors.red, 'label': 'Private'},
    };
    
    final current = config[value]!;
    
    return GestureDetector(
      onTap: () {
        final options = ['public', 'friends', 'private'];
        final currentIndex = options.indexOf(value);
        final nextIndex = (currentIndex + 1) % options.length;
        setState(() => _privacy[field] = options[nextIndex]);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: (current['color'] as Color).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: (current['color'] as Color).withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(current['icon'] as IconData, size: 16, color: current['color'] as Color),
            const SizedBox(width: 6),
            Text(
              current['label'] as String,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: current['color'] as Color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
