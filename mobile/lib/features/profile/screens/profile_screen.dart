import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../../social/widgets/post_card.dart';
import '../../social/repositories/feed_repository.dart';
import '../../social/widgets/comments_bottom_sheet.dart'; 
import '../../social/providers/feed_provider.dart';
import '../../../models/post_model.dart';
import '../../../core/api_client.dart';
import '../../../core/services/image_upload_service.dart';
import '../../chat/screens/chat_screen.dart';
import '../../chat/providers/chat_provider.dart';
import '../providers/profile_provider.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';
import 'package:timeago/timeago.dart' as timeago;

// Provider for fetching specific user's posts
final userPostsProvider = FutureProvider.family<List<Post>, String>((ref, userId) async {
  final repository = ref.watch(feedRepositoryProvider);
  final data = await repository.getUserFeed(userId);
  return data.map((e) => Post.fromJson(Map<String, dynamic>.from(e))).toList();
});

class ProfileScreen extends ConsumerWidget {
  final String? userId; // If null, assume current user

  const ProfileScreen({super.key, this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: currentUserAsync.when(
        data: (currentUser) {
           if (currentUser == null) return const Center(child: Text('Please login'));
           
           final targetId = userId ?? currentUser.firebaseUid;
           final isMe = targetId == currentUser.firebaseUid;

           return _ProfileContent(targetId: targetId, isMe: isMe);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _ProfileContent extends ConsumerStatefulWidget {
  final String targetId;
  final bool isMe;

  const _ProfileContent({required this.targetId, required this.isMe});

  @override
  ConsumerState<_ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends ConsumerState<_ProfileContent> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingCover = false;
  File? _optimisticCover;

  Future<void> _updateCoverPhoto(Map<String, dynamic> currentProfile) async {
      try {
         final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
         if (image == null) return;

         // Crop Image
         final CroppedFile? croppedFile = await ImageCropper().cropImage(
            sourcePath: image.path,
            uiSettings: [
              AndroidUiSettings(
                toolbarTitle: 'Adjust Cover',
                toolbarColor: Colors.black,
                toolbarWidgetColor: Colors.white,
                initAspectRatio: CropAspectRatioPreset.ratio16x9,
                lockAspectRatio: false,
              ),
              IOSUiSettings(
                title: 'Adjust Cover',
              ),
            ],
          );

         if (croppedFile == null) return;

         final File file = File(croppedFile.path);

         // Optimistic Update
         setState(() {
            _optimisticCover = file;
            _isUploadingCover = true;
         });
         
         final imageUploadService = ref.read(imageUploadServiceProvider);
         final apiClient = ref.read(apiClientProvider);

         // 1. Upload Image
         final String? coverUrl = await imageUploadService.uploadImage(file);
         
         if (coverUrl == null) {
            throw Exception('Upload failed');
         }

         // 2. Patch Profile
         final data = {
             'name': currentProfile['name'],
             'department': currentProfile['department'],
             'bio': currentProfile['bio'],
             'studentId': currentProfile['studentId'],
             'year': currentProfile['year'],
             'section': currentProfile['section'],
             'coverPhoto': coverUrl
         };
         
         await apiClient.patch('/user/profile', data: data);

         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cover photo updated!')));
            ref.invalidate(userProfileProvider(widget.targetId));
         }

      } catch (e) {
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
         setState(() => _optimisticCover = null); // Revert on error
      } finally {
         if (mounted) setState(() => _isUploadingCover = false);
      }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider(widget.targetId));
    final postsAsync = ref.watch(userPostsProvider(widget.targetId));

    // Define skeleton data
    final dummyProfile = {
      'id': 'skeleton',
      'name': 'Loading Name...',
      'department': 'Department Name',
      'postsCount': 0,
      'friendsCount': 0,
      'bio': 'This is a dummy bio to show the skeleton state of the profile page caching system.',
    };

    return Scaffold(
      backgroundColor: Colors.white,
      body: Skeletonizer(
        enabled: profileAsync.isLoading && !profileAsync.hasValue,
        child: DefaultTabController(
          length: 2,
          child: Stack(
            children: [
              NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverToBoxAdapter(
                      child: _buildProfileHeader(
                        context, 
                        ref, 
                        profileAsync.value ?? dummyProfile,
                      ),
                    ),
                    SliverPersistentHeader(
                       delegate: _SliverAppBarDelegate(
                         TabBar(
                           labelColor: Colors.black,
                           unselectedLabelColor: Colors.grey.shade400,
                           indicatorColor: const Color(0xFF6C63FF),
                           indicatorWeight: 3,
                           indicatorSize: TabBarIndicatorSize.label,
                           labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.5),
                           unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                           tabs: const [
                             Tab(text: "Posts"),
                             Tab(text: "About"),
                           ],
                         ),
                       ),
                       pinned: true,
                    ),
                  ];
                },
                body: TabBarView(
                  children: [
                     _ProfilePostsTab(postsAsync: postsAsync, userId: widget.targetId),
                     SingleChildScrollView(
                       padding: const EdgeInsets.all(16),
                       child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                                // Academic Profile Card
                                if (profileAsync.value?['department'] != null || 
                                    profileAsync.value?['studentId'] != null ||
                                    profileAsync.value?['year'] != null ||
                                    profileAsync.value?['section'] != null) ...[
                                  _buildSectionCard(
                                    title: 'Academic Profile',
                                    icon: Icons.school_rounded,
                                    children: [
                                      if (profileAsync.value?['department'] != null)
                                        _buildInfoTile(Icons.account_balance_outlined, 'Department', profileAsync.value?['department']),
                                      if (profileAsync.value?['studentId'] != null && (profileAsync.value?['studentId'] as String).isNotEmpty)
                                        _buildInfoTile(Icons.badge_outlined, 'Student ID', profileAsync.value?['studentId']),
                                      if ((profileAsync.value?['year'] != null && (profileAsync.value?['year'] as String).isNotEmpty) || 
                                          (profileAsync.value?['section'] != null && (profileAsync.value?['section'] as String).isNotEmpty))
                                        _buildInfoTile(Icons.class_outlined, 'Batch/Section', '${profileAsync.value?['year'] ?? ''} ${profileAsync.value?['section'] ?? ''}'),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                // Contact & Personal Card
                                if (profileAsync.value?['email'] != null || 
                                    profileAsync.value?['location'] != null ||
                                    profileAsync.value?['joinedAt'] != null) ...[
                                  _buildSectionCard(
                                    title: 'Contact & Personal',
                                    icon: Icons.person_outline_rounded,
                                    children: [
                                      if (profileAsync.value?['email'] != null)
                                        _buildInfoTile(Icons.email_outlined, 'Email', profileAsync.value?['email']),
                                      if (profileAsync.value?['location'] != null && (profileAsync.value?['location'] as String).isNotEmpty)
                                        _buildInfoTile(Icons.location_on_outlined, 'Location', profileAsync.value?['location']),
                                      if (profileAsync.value?['joinedAt'] != null)
                                        _buildInfoTile(Icons.calendar_today_outlined, 'Joined', timeago.format(DateTime.parse(profileAsync.value?['joinedAt']))),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                
                                // Connect with Me (Social Media Links)
                                if ((profileAsync.value?['linkedinUrl'] != null && (profileAsync.value?['linkedinUrl'] as String).isNotEmpty) ||
                                    (profileAsync.value?['facebookUrl'] != null && (profileAsync.value?['facebookUrl'] as String).isNotEmpty)) ...[
                                  _buildSectionCard(
                                    title: 'Connect with Me',
                                    icon: Icons.link_rounded,
                                    children: [
                                      if (profileAsync.value?['linkedinUrl'] != null && (profileAsync.value?['linkedinUrl'] as String).isNotEmpty)
                                        _buildSocialMediaButton(
                                          icon: Icons.work_outline_rounded,
                                          label: 'LinkedIn',
                                          url: profileAsync.value?['linkedinUrl'],
                                          color: const Color(0xFF0077B5),
                                        ),
                                      if (profileAsync.value?['linkedinUrl'] != null && 
                                          (profileAsync.value?['linkedinUrl'] as String).isNotEmpty &&
                                          profileAsync.value?['facebookUrl'] != null && 
                                          (profileAsync.value?['facebookUrl'] as String).isNotEmpty)
                                        const SizedBox(height: 12),
                                      if (profileAsync.value?['facebookUrl'] != null && (profileAsync.value?['facebookUrl'] as String).isNotEmpty)
                                        _buildSocialMediaButton(
                                          icon: Icons.facebook_outlined,
                                          label: 'Facebook',
                                          url: profileAsync.value?['facebookUrl'],
                                          color: const Color(0xFF1877F2),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                
                                // Interests Section
                                if (profileAsync.value?['interests'] != null && (profileAsync.value?['interests'] as List).isNotEmpty) ...[
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.grey.shade200, width: 1),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.03),
                                          blurRadius: 10,
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
                                              child: const Icon(Icons.favorite_outline_rounded, color: Color(0xFF6C63FF), size: 18),
                                            ),
                                            const SizedBox(width: 12),
                                            const Text('Interests', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.5)),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: (profileAsync.value?['interests'] as List).map((interest) => Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  const Color(0xFF6C63FF).withOpacity(0.08),
                                                  const Color(0xFF6C63FF).withOpacity(0.04),
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.2), width: 1),
                                            ),
                                            child: Text(
                                              interest.toString(), 
                                              style: const TextStyle(
                                                fontSize: 13, 
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF6C63FF),
                                                letterSpacing: 0.2,
                                              ),
                                            ),
                                          )).toList(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                          ],
                       ),
                     )
                  ]
                ),
              ),
              
              // Floating AppBar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  leading: context.canPop() 
                      ? IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                          onPressed: () => context.pop(),
                        )
                      : null,
                  actions: [
                    if (widget.isMe)
                       IconButton(
                         icon: const Icon(Icons.settings_outlined, color: Colors.white), 
                         onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                         }
                       ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, WidgetRef ref, Map<String, dynamic> profile) {
    final isSkeleton = profile['id'] == 'skeleton';
    
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomLeft,
          children: [
             // 1. Cover Photo Area with Premium Gradient
             Container(
               height: 240,
               width: double.infinity,
               child: Stack(
                 fit: StackFit.expand,
                 children: [
                    if (_optimisticCover != null)
                        Image.file(_optimisticCover!, fit: BoxFit.cover)
                    else 
                       Builder(builder: (context) {
                           final cover = profile['coverPhoto'] as String?;
                           if (cover != null && cover.isNotEmpty) {
                              return CachedNetworkImage(
                                imageUrl: cover, 
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(color: Colors.grey[200]),
                                errorWidget: (context, url, error) => const Icon(Icons.error),
                              );
                           }
                           return Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF6C63FF), Color(0xFF3B3399)], 
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                           );
                       }),
                    
                    // Subtle dark overlay for better text contrast on top
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.black.withOpacity(0.4), Colors.transparent],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),

                    // Bottom Curve
                    Positioned(
                      bottom: -1,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 35,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(35),
                            topRight: Radius.circular(35),
                          ),
                        ),
                      ),
                    ),

                    // Camera Button
                    if (widget.isMe)
                      Positioned(
                        bottom: 24, 
                        right: 20,
                        child: _isUploadingCover 
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : GestureDetector(
                                onTap: () => _updateCoverPhoto(profile),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                                ),
                              ),
                      )
                 ],
               ),
             ),
             
             // 2. Avatar with Shadow
             Positioned(
               bottom: -45,
               left: 0,
               right: 0,
               child: Center(
                 child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white, 
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, 8))]
                    ),
                    child: CircleAvatar(
                      radius: 55,
                      backgroundImage: (profile['photo'] != null && profile['photo'].isNotEmpty)
                        ? CachedNetworkImageProvider(profile['photo'])
                        : null,
                      backgroundColor: Colors.grey[100],
                      child: (profile['photo'] == null || profile['photo'].isEmpty)
                        ? Text(
                            profile['name'] != null && profile['name'].isNotEmpty ? profile['name'][0].toUpperCase() : '?', 
                            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Color(0xFF6C63FF))
                          )
                        : null,
                    ),
                  ),
               ),
             ),
          ],
        ),

        const SizedBox(height: 55),

        // 3. User Info
        Text(
          profile['name'] ?? 'User Name',
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.8),
        ),
        if (profile['department'] != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.08), 
                borderRadius: BorderRadius.circular(20)
              ),
              child: Text(
                profile['department'], 
                style: const TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.2)
              ),
            ),
          ),
          
        const SizedBox(height: 18),
        
        if (!isSkeleton && profile['bio'] != null && profile['bio'].isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                profile['bio'],
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700], fontSize: 14, height: 1.5, fontWeight: FontWeight.w400),
              ),
            ),
            
        const SizedBox(height: 24),
        
        // Stats Row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStatItem('Posts', profile['postsCount'] ?? 0),
            Container(height: 30, width: 1, color: Colors.grey[200], margin: const EdgeInsets.symmetric(horizontal: 30)),
            _buildStatItem('Friends', profile['friendsCount'] ?? 0),
          ],
        ),
        
        const SizedBox(height: 28),
        
        // Buttons Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: 
                    // Action Buttons
            Row(
              children: [
                if (widget.isMe) ...[
                  // Edit Profile Button (for own profile)
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditProfileScreen(currentProfile: profile),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shadowColor: Colors.black.withOpacity(0.4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.edit_outlined, size: 20),
                            SizedBox(width: 8),
                            Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  // For other users - show buttons based on connection status
                  if (profile['connectionStatus'] == 'friend') ...[
                    // Message Button (for friends)
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () async {
                            try {
                              final apiClient = ref.read(apiClientProvider);
                              final response = await apiClient.post('/chat/start', data: {'targetId': widget.targetId});
                              final conversationId = response.data['_id'];
                              if (context.mounted) {
                                final chatUser = ChatUser(id: widget.targetId, name: profile['name'], photo: profile['photo'] ?? '');
                                Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(conversationId: conversationId, targetUser: chatUser)));
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shadowColor: Colors.black.withOpacity(0.4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.message_outlined, size: 20),
                              SizedBox(width: 8),
                              Text('Message', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ] else if (profile['connectionStatus'] == 'pending') ...[
                    // Pending Button (connection request sent)
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: null, // Disabled
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            disabledForegroundColor: Colors.grey,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.schedule_outlined, size: 20),
                              SizedBox(width: 8),
                              Text('Pending', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Connect Button (for strangers)
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () async {
                            try {
                              final apiClient = ref.read(apiClientProvider);
                              final response = await apiClient.post('/connect/swipe', data: {
                                'targetId': widget.targetId,
                                'action': 'like',
                              });
                              
                              if (context.mounted) {
                                if (response.data != null && response.data['match'] == true) {
                                  // It's a match!
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(Icons.favorite, color: Colors.white),
                                          const SizedBox(width: 8),
                                          Text('It\'s a match with ${profile['name']}! 🎉'),
                                        ],
                                      ),
                                      backgroundColor: const Color(0xFF6C63FF),
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                  // Refresh profile to update status
                                  ref.invalidate(userProfileProvider(widget.targetId));
                                } else {
                                  // Connection request sent
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Connection request sent to ${profile['name']}'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  // Refresh profile to show pending status
                                  ref.invalidate(userProfileProvider(widget.targetId));
                                }
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.black, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_add_outlined, color: Colors.black, size: 20),
                              SizedBox(width: 8),
                              Text('Connect', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 15)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
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
                child: Icon(icon, color: const Color(0xFF6C63FF), size: 18),
              ),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.5)),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialMediaButton({
    required IconData icon,
    required String label,
    required String? url,
    required Color color,
  }) {
    return InkWell(
      onTap: () async {
        if (url != null && url.isNotEmpty) {
          // Simple URL opening - you can add url_launcher package for better handling
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Opening $label: $url')),
          );
          // TODO: Add url_launcher to open in browser
          // await launchUrl(Uri.parse(url));
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
            Icon(Icons.open_in_new, color: color, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int count) {
    return Column(
      children: [
        Text('$count', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _ProfilePostsTab extends ConsumerStatefulWidget {
  final AsyncValue<List<Post>> postsAsync;
  final String userId; 

  const _ProfilePostsTab({required this.postsAsync, required this.userId});

  @override
  ConsumerState<_ProfilePostsTab> createState() => _ProfilePostsTabState();
}

class _ProfilePostsTabState extends ConsumerState<_ProfilePostsTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Future<void> _deletePost(String postId) async {
      try {
        await ref.read(feedRepositoryProvider).deletePost(postId);
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post deleted')));
           ref.invalidate(userPostsProvider(widget.userId));
           ref.invalidate(feedProvider);
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
  }

  Future<void> _archivePost(String postId) async {
      try {
        await ref.read(feedRepositoryProvider).archivePost(postId);
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post archived')));
           ref.invalidate(userPostsProvider(widget.userId));
           ref.invalidate(feedProvider);
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
  }

  Future<void> _editPost(String postId, String newContent) async {
      try {
        await ref.read(feedRepositoryProvider).editPost(postId, newContent);
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post updated')));
           ref.invalidate(userPostsProvider(widget.userId));
           ref.invalidate(feedProvider); // Refresh main feed too
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
  }

  void _showEditDialog(Post post) {
    final controller = TextEditingController(text: post.content);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Post'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (controller.text.trim().isNotEmpty) {
                 await _editPost(post.id, controller.text.trim());
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String postId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Post?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _deletePost(postId);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  void _showHistory(String postId) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             const Text('Edit History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
             const SizedBox(height: 16),
             Expanded(
               child: FutureBuilder(
                 future: ref.read(feedRepositoryProvider).getPostHistory(postId),
                 builder: (context, snapshot) {
                   if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                   if (snapshot.hasError) return Text('Error: ${snapshot.error}');
                   
                   final history = snapshot.data as List<dynamic>? ?? [];
                   if (history.isEmpty) return const Text('No edit history found.');
                   
                   return ListView.builder(
                     itemCount: history.length,
                     itemBuilder: (context, index) {
                       final h = history[index];
                       return ListTile(
                         title: Text(h['content']),
                         subtitle: Text(
                           timeago.format(DateTime.parse(h['editedAt'])),
                           style: const TextStyle(fontSize: 12),
                         ),
                         leading: const Icon(Icons.history, size: 20),
                       );
                     },
                   );
                 },
               ),
             )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required
    final currentUser = ref.watch(currentUserProvider).value;

    return Skeletonizer(
      enabled: widget.postsAsync.isLoading && !widget.postsAsync.hasValue,
      child: widget.postsAsync.when(
        data: (posts) {
           if (posts.isEmpty) {
             return const Center(child: Padding(
               padding: EdgeInsets.only(top: 40),
               child: Text('No posts yet', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
             ));
           }
           return ListView.builder(
             padding: EdgeInsets.zero,
             shrinkWrap: true, // Needed if nested in certain scrolls
             physics: const NeverScrollableScrollPhysics(), // Managed by NestedScrollView
             itemCount: posts.length,
             itemBuilder: (context, index) {
                 final post = posts[index];
                 final isLiked = currentUser != null && post.likes.contains(currentUser.firebaseUid);
                 final isOwner = currentUser != null && post.userId == currentUser.firebaseUid;

                 return PostCard(
                    id: post.id,
                    userName: post.authorName,
                    authorPhoto: post.authorPhoto,
                    userDepartment: post.authorDepartment,
                    content: post.content,
                    timeAgo: timeago.format(post.createdAt), 
                    visibility: post.visibility,
                    imageUrls: post.imageUrls,
                    isLiked: isLiked, 
                    likesCount: post.likes.length,
                    commentsCount: post.commentsCount,
                    isOwner: isOwner,
                    isEdited: post.isEdited,
                    onLike: () async {
                        await ref.read(feedProvider.notifier).toggleLike(post.id); 
                        ref.invalidate(userPostsProvider(widget.userId)); 
                    },
                    onComment: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => CommentsBottomSheet(postId: post.id)
                    ),
                    onShare: () {},
                    onDelete: () => _confirmDelete(post.id),
                    onArchive: () => _archivePost(post.id),
                    onEdit: () => _showEditDialog(post),
                    onViewHistory: () => _showHistory(post.id),
                 );
             },
           );
        },
        loading: () => ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: 3,
          itemBuilder: (context, index) => PostCard(
            id: 'skeleton',
            userName: 'Loading...',
            authorPhoto: '',
            userDepartment: 'Department',
            content: 'This is a skeleton content for the post card in profile feed.',
            timeAgo: 'Just now',
            visibility: 'public',
            imageUrls: const [],
            isLiked: false,
            likesCount: 0,
            commentsCount: 0,
            isOwner: false,
            onLike: () {},
            onComment: () {},
            onShare: () {},
          ),
        ),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
