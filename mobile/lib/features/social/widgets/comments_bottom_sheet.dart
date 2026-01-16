import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../social/providers/feed_provider.dart';
import '../../../core/api_client.dart';
import '../../../core/widgets/cached_avatar.dart';
import 'package:timeago/timeago.dart' as timeago;

final commentsProvider = FutureProvider.family<List<dynamic>, String>((ref, postId) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.get('/feed/$postId/comments');
  return response.data as List<dynamic>;
});

class CommentsBottomSheet extends ConsumerStatefulWidget {
  final String postId;

  const CommentsBottomSheet({super.key, required this.postId});

  @override
  ConsumerState<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends ConsumerState<CommentsBottomSheet> {
  final _commentController = TextEditingController();
  String? _replyingToCommentId; // ID of comment being replied to
  String? _replyingToUserName; // Name of user being replied to

  void _submit() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final isReply = _replyingToCommentId != null;

    try {
      _commentController.clear();
      FocusScope.of(context).unfocus(); // Close keyboard momentarily

      if (isReply) {
        await ref.read(feedProvider.notifier).replyToComment(
          widget.postId, 
          _replyingToCommentId!, 
          text
        );
        // Reset reply state
        setState(() {
          _replyingToCommentId = null;
          _replyingToUserName = null;
        });
      } else {
        await ref.read(feedProvider.notifier).addComment(widget.postId, text);
      }

      ref.invalidate(commentsProvider(widget.postId));
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Posted!')));

    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  void _startReply(String commentId, String userName) {
    setState(() {
      _replyingToCommentId = commentId;
      _replyingToUserName = userName;
    });
    // Focus text field
    // Future.delayed to allow UI to rebuild with the "Replying to..." banner
    Future.delayed(const Duration(milliseconds: 100), () {
        // FocusScope.of(context).requestFocus(_focusNode); // Add focusNode if needed
    });
  }

  void _cancelReply() {
    setState(() {
      _replyingToCommentId = null;
      _replyingToUserName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(commentsProvider(widget.postId));

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7, // More "half-open" feel
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40, height: 4, 
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              margin: const EdgeInsets.only(top: 12, bottom: 12),
            ),
            const Text('Comments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))), // Amoled Black secondary
            const Divider(color: Colors.black12),
            
            Expanded(
              child: commentsAsync.when(
                data: (comments) {
                  if (comments.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey[200]),
                          const SizedBox(height: 8),
                          const Text('No comments yet', style: TextStyle(color: Colors.grey)),
                          Text('Start the conversation!', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final c = comments[index];
                      final replies = (c['replies'] as List?) ?? []; 
                      
                      return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildCommentItem(
                              commentId: c['_id'],
                              authorName: c['authorName'],
                              authorPhoto: c['authorPhoto'],
                              text: c['text'],
                              createdAt: c['createdAt'],
                              onReply: () => _startReply(c['_id'], c['authorName']),
                            ),
                            // Nested Replies
                            if (replies.isNotEmpty)
                                Padding(
                                    padding: const EdgeInsets.only(left: 48.0, bottom: 8),
                                    child: ListView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: replies.length,
                                        itemBuilder: (ctx, rIndex) {
                                            final r = replies[rIndex];
                                            return Padding(
                                              padding: const EdgeInsets.only(top: 8.0),
                                              child: _buildCommentItem(
                                                commentId: c['_id'], // Reply technically keeps parent thread ID focus for now or just generic
                                                authorName: r['authorName'] ?? 'Unknown User', // Use REAL name
                                                authorPhoto: r['authorPhoto'],
                                                text: r['text'],
                                                createdAt: r['createdAt'],
                                                isReply: true,
                                                onReply: () => _startReply(c['_id'], r['authorName'] ?? 'User'),
                                              ),
                                            );
                                        }
                                    ),
                                ),
                          ],
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text('Error loading comments', style: TextStyle(color: Colors.red[300]))),
              ),
            ),
            
            Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 0 : 84, // Clear nav bar only when keyboard is closed
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Reply Context Banner
                    if (_replyingToCommentId != null)
                        Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            color: Colors.grey[50],
                            child: Row(
                                children: [
                                    Text(
                                      'Replying to ', 
                                      style: TextStyle(color: Colors.grey[600], fontSize: 12)
                                    ),
                                    Text(
                                      _replyingToUserName ?? 'User', 
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E293B))
                                    ),
                                    const Spacer(),
                                    GestureDetector(
                                      onTap: _cancelReply, 
                                      child: Icon(Icons.close, size: 16, color: Colors.grey[400])
                                    )
                                ],
                            ),
                        ),
                    
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                              child: TextField(
                                controller: _commentController,
                                style: const TextStyle(color: Colors.black87, fontSize: 15),
                                decoration: InputDecoration(
                                  hintText: _replyingToCommentId != null ? 'Write a reply...' : 'Add a comment...',
                                  hintStyle: TextStyle(color: Colors.grey[400]),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                                minLines: 1,
                                maxLines: 4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Send Button (Using Amoled Black as secondary)
                          GestureDetector(
                            onTap: _submit,
                            child: Container(
                              height: 44,
                              width: 44,
                              decoration: const BoxDecoration(
                                color: Color(0xFF1E293B), // Amoled Black
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 22),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

  // Define helper widget effectively inside the class or extracted
  Widget _buildCommentItem({
    required String commentId,
    required String authorName,
    required String? authorPhoto,
    required String text,
    required String createdAt,
    required VoidCallback onReply,
    bool isReply = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isReply ? 12 : 16.0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                CachedAvatar(
                  imageUrl: authorPhoto,
                  radius: isReply ? 14 : 18,
                  fallbackText: authorName,
                ),
                if (!isReply)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: Colors.grey[100],
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(authorName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E293B))),
                      const SizedBox(width: 8),
                      Text(
                        timeago.format(DateTime.parse(createdAt), locale: 'en_short'), 
                        style: TextStyle(color: Colors.grey[500], fontSize: 11)
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(text, style: TextStyle(fontSize: 14, color: Colors.black.withOpacity(0.8), height: 1.35)),
                  const SizedBox(height: 4),
                  
                  GestureDetector(
                    onTap: onReply,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        'Reply', 
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey[600])
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
