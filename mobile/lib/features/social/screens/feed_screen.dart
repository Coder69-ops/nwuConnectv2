
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../widgets/post_card.dart';
import '../widgets/comments_bottom_sheet.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/feed_provider.dart';
import '../../notification/providers/notification_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../models/post_model.dart';
import '../../../core/api_client.dart';
import 'package:timeago/timeago.dart' as timeago;

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  String _selectedFilter = 'All'; // All, Department, Friends

  Future<void> _refreshFeed() async {
    return ref.refresh(feedProvider);
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
              await ref.read(feedProvider.notifier).deletePost(postId);
              if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post deleted')));
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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
                 await ref.read(feedProvider.notifier).editPost(post.id, controller.text.trim());
                 if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post updated')));
              }
            },
            child: const Text('Save'),
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
                 future: ref.read(apiClientProvider).get('/feed/$postId/history'),
                 builder: (context, snapshot) {
                   if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                   if (snapshot.hasError) return Text('Error: ${snapshot.error}');
                   
                   final history = snapshot.data?.data as List<dynamic>? ?? [];
                   if (history.isEmpty) return const Text('No edit history found.');
                   
                   return ListView.builder(
                     itemCount: history.length,
                     itemBuilder: (context, index) {
                       final h = history[index];
                       // Assuming h has 'content' and 'editedAt'
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
    final feedAsync = ref.watch(feedProvider);
    final currentUser = ref.watch(currentUserProvider).value;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 48, // Reduced height
                title: const Text('NWU Feed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),

        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.black87),
                onPressed: () => context.push('/notifications'),
              ),
              // Unread Badge
              Consumer(
                builder: (context, ref, child) {
                  final notifications = ref.watch(notificationsProvider).valueOrNull ?? [];
                  final unreadCount = notifications.where((n) => !n.isRead).length;
                  if (unreadCount == 0) return const SizedBox.shrink();
                  
                  return Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 8,
                        minHeight: 8,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs (More Compact)
          Container(
            height: 38, // Reduced from 50
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCategoryTab('All'),
                const SizedBox(width: 8), // Tighter spacing
                _buildCategoryTab('Department'),
                const SizedBox(width: 8),
                _buildCategoryTab('Friends'),
                const SizedBox(width: 8),
                _buildCategoryTab('Popular'),
              ],
            ),
          ),
          
          // Feed List
          Expanded(
            child: feedAsync.when(
              skipLoadingOnRefresh: true, 
              data: (posts) {
                // Client-side Filtering Logic
                final filteredPosts = posts.where((post) {
                  if (_selectedFilter == 'All') return true;
                  if (_selectedFilter == 'Department') {
                    if (currentUser == null) return false;
                    return post.authorDepartment == currentUser.department; 
                  }
                  if (_selectedFilter == 'Friends') {
                     if (currentUser == null) return false;
                     return currentUser.friendIds.contains(post.userId);
                  }
                  if (_selectedFilter == 'Popular') {
                    return post.likes.length > 5;
                  }
                  return true;
                }).toList();

                if (filteredPosts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.filter_list_off, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text('No posts in "$_selectedFilter"', 
                          style: TextStyle(color: Colors.grey[600], fontSize: 16)
                        ),
                      ],
                    ),
                  );
                }
                
                return RefreshIndicator(
                  onRefresh: _refreshFeed,
                  color: Colors.black,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: filteredPosts.length,
                    addAutomaticKeepAlives: true,
                    cacheExtent: 500, // Preload widgets for smoother scrolling
                    itemBuilder: (context, index) {
                      final post = filteredPosts[index];
                      final isLiked = currentUser != null && post.likes.contains(currentUser.firebaseUid); 
                      final isOwner = currentUser != null && post.userId == currentUser.firebaseUid;

                      return RepaintBoundary(
                        child: PostCard(
                          key: ValueKey(post.id),
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
                          onLike: () => ref.read(feedProvider.notifier).toggleLike(post.id),
                          onComment: () {
                            showModalBottomSheet(
                              context: context, 
                              isScrollControlled: true,
                              builder: (_) => CommentsBottomSheet(postId: post.id)
                            );
                          },
                          onShare: () {},
                          onDelete: () => _confirmDelete(post.id),
                          onEdit: () => _showEditDialog(post),
                          onArchive: () async {
                             await ref.read(feedProvider.notifier).archivePost(post.id);
                             if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post archived')));
                          },
                          onViewHistory: () => _showHistory(post.id),
                          onProfileTap: () => context.push('/profile?userId=${post.userId}'),
                        ),
                      );
                    },
                  ),
                );
              },
              error: (err, stack) => Center(child: Text('Error: $err')),
              loading: () => Skeletonizer(
                enabled: true,
                child: ListView.builder(
                  itemCount: 5,
                  itemBuilder: (context, index) => PostCard(
                       id: 'dummy',
                       userName: 'User Name',
                       authorPhoto: '',
                       userDepartment: 'Department',
                       content: 'Loading...',
                       timeAgo: 'Just now',
                       visibility: 'public',
                       onLike: () {},
                       onComment: () {},
                       onShare: () {},
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTab(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(12), // Tighter radius to match content curves
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey[300]!,
            width: 1.2,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ] : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[700],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 13, // Slightly smaller
            ),
          ),
        ),
      ),
    );
  }
}
