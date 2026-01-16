import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import 'edit_profile_screen.dart';
import '../providers/profile_provider.dart';
import '../../../core/widgets/cached_image.dart';
import '../../../core/widgets/cached_avatar.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: currentUserAsync.when(
        data: (currentUser) {
          if (currentUser == null) {
            return const Center(child: Text('Please login'));
          }

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              // User Profile Card
              _buildProfileCard(context, currentUser),
              const SizedBox(height: 20),

              // Account & Profile Section
              _buildSectionCard(
                title: 'Account & Profile',
                children: [
                  _buildSettingTile(
                    icon: Icons.person_outline,
                    title: 'Edit Profile',
                    subtitle: 'Update your personal information',
                    onTap: () async {
                      final profileMap = {
                        'name': currentUser.name,
                        'bio': currentUser.bio ?? '',
                        'department': currentUser.department,
                        'studentId': currentUser.studentId,
                        'year': currentUser.year,
                        'section': currentUser.section,
                        'coverPhoto': currentUser.coverPhoto,
                        'photo': currentUser.photo,
                        'email': currentUser.email,
                      };
                      Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileScreen(currentProfile: profileMap)));
                    },
                  ),
                  _buildDivider(),
                  _buildSettingTile(
                    icon: Icons.shield_outlined,
                    title: 'Privacy Settings',
                    subtitle: 'Control who can see your information',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Privacy settings coming soon')),
                      );
                    },
                  ),
                  _buildDivider(),
                  _buildSettingTile(
                    icon: Icons.block_outlined,
                    title: 'Blocked Users',
                    subtitle: 'Manage blocked accounts',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Blocked users coming soon')),
                      );
                    },
                  ),
                  _buildDivider(),
                  _buildSettingTile(
                    icon: Icons.lock_outline,
                    title: 'Change Password',
                    subtitle: 'Update your account password',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Password change coming soon')),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Notifications Section
              _buildSectionCard(
                title: 'Notifications',
                children: [
                  _buildSwitchTile(
                    icon: Icons.notifications_outlined,
                    title: 'Push Notifications',
                    subtitle: 'Receive notifications on your device',
                    value: true,
                    onChanged: (value) {},
                  ),
                  _buildDivider(),
                  _buildSwitchTile(
                    icon: Icons.article_outlined,
                    title: 'Post Notifications',
                    subtitle: 'Get notified about new posts',
                    value: true,
                    onChanged: (value) {},
                  ),
                  _buildDivider(),
                  _buildSwitchTile(
                    icon: Icons.message_outlined,
                    title: 'Message Notifications',
                    subtitle: 'Get notified about new messages',
                    value: true,
                    onChanged: (value) {},
                  ),
                  _buildDivider(),
                  _buildSwitchTile(
                    icon: Icons.person_add_outlined,
                    title: 'Connection Requests',
                    subtitle: 'Get notified about new connections',
                    value: true,
                    onChanged: (value) {},
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Preferences Section
              _buildSectionCard(
                title: 'Preferences',
                children: [
                  _buildSwitchTile(
                    icon: Icons.data_saver_off_outlined,
                    title: 'Data Saver',
                    subtitle: 'Reduce data usage',
                    value: false,
                    onChanged: (value) {},
                  ),
                  _buildDivider(),
                  _buildSettingTile(
                    icon: Icons.language_outlined,
                    title: 'Language',
                    subtitle: 'English',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Language selection coming soon')),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Support & Info Section
              _buildSectionCard(
                title: 'Support & Info',
                children: [
                  _buildSettingTile(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    subtitle: 'Get help with the app',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Help center coming soon')),
                      );
                    },
                  ),
                  _buildDivider(),
                  _buildSettingTile(
                    icon: Icons.description_outlined,
                    title: 'Terms of Service',
                    subtitle: 'Read our terms',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Terms of service coming soon')),
                      );
                    },
                  ),
                  _buildDivider(),
                  _buildSettingTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    subtitle: 'Read our privacy policy',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Privacy policy coming soon')),
                      );
                    },
                  ),
                  _buildDivider(),
                  _buildSettingTile(
                    icon: Icons.info_outline,
                    title: 'About NWU Connect',
                    subtitle: 'Version 1.0.0',
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'NWU Connect',
                        applicationVersion: '1.0.0',
                        children: [
                          const Text('NWU Connect is your campus companion for social connection, verified news, and more.'),
                        ],
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Danger Zone Section
              _buildSectionCard(
                title: 'Danger Zone',
                children: [
                  _buildSettingTile(
                    icon: Icons.delete_outline,
                    title: 'Delete Account',
                    subtitle: 'Permanently delete your account',
                    iconColor: Colors.red,
                    titleColor: Colors.red,
                    onTap: () async {
                      final shouldDelete = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Account'),
                          content: const Text('Are you sure you want to permanently delete your account? This action cannot be undone.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Delete', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );

                      if (shouldDelete == true && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Account deletion coming soon')),
                        );
                      }
                    },
                  ),
                  _buildDivider(),
                  _buildSettingTile(
                    icon: Icons.logout,
                    title: 'Logout',
                    subtitle: 'Sign out of your account',
                    iconColor: Colors.red,
                    titleColor: Colors.red,
                    onTap: () async {
                      final shouldLogout = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Logout'),
                          content: const Text('Are you sure you want to log out?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Logout', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );

                      if (shouldLogout == true) {
                        await ref.read(authControllerProvider).signOut();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, currentUser) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200, width: 2),
            ),
            child: ClipOval(
              child: currentUser.photo != null && currentUser.photo!.isNotEmpty
                  ? CachedAvatar(imageUrl: currentUser.photo!, radius: 30)
                  : Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.person, size: 30, color: Colors.grey),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        currentUser.name ?? 'User',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.verified, color: Colors.blue, size: 18),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  currentUser.department ?? 'Department',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          // Arrow
          Icon(Icons.chevron_right, color: Colors.grey[400]),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1.2,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    Color? titleColor,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? Colors.black).withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor ?? Colors.black, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: titleColor,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            )
          : null,
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.black, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            )
          : null,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.black,
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 60,
      endIndent: 16,
      color: Colors.grey[200],
    );
  }
}
