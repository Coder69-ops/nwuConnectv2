import 'package:flutter/material.dart';
import '../../../core/widgets/cached_image.dart';
import '../../../core/widgets/cached_avatar.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PostCard extends StatefulWidget {
  final String id;
  final String userName;
  final String userDepartment;
  final String content;
  final List<String> imageUrls;
  final String timeAgo;
  final String visibility;
  
  final bool isLiked;
  final int likesCount;
  final int commentsCount;
  
  final String authorPhoto;
  
  final bool isOwner;
  final bool isEdited;

  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onArchive;
  final VoidCallback? onViewHistory;
  final VoidCallback? onProfileTap;

  const PostCard({
    super.key,
    required this.id,
    required this.userName,
    required this.authorPhoto,
    required this.userDepartment,
    required this.content,
    this.imageUrls = const [],
    required this.timeAgo,
    required this.visibility,
    this.isLiked = false,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isOwner = false,
    this.isEdited = false,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    this.onEdit,
    this.onDelete,
    this.onArchive,
    this.onViewHistory,
    this.onProfileTap,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with SingleTickerProviderStateMixin {
  late bool _localIsLiked;
  late int _localLikesCount;
  bool _showHeart = false;
  late AnimationController _heartController;
  late Animation<double> _heartScale;
  late Animation<double> _heartOpacity;

  @override
  void initState() {
    super.initState();
    _localIsLiked = widget.isLiked;
    _localLikesCount = widget.likesCount;
    
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _heartScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.2).chain(CurveTween(curve: Curves.easeOutBack)), weight: 40),
      TweenSequenceItem(tween: Tween<double>(begin: 1.2, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 60),
    ]).animate(_heartController);

    _heartOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.0), weight: 40),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
    ]).animate(_heartController);

    _heartController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _showHeart = false);
        _heartController.reset();
      }
    });
  }

  @override
  void didUpdateWidget(PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync if upstream changes (e.g. from refresh or other users)
    if (oldWidget.isLiked != widget.isLiked) {
      _localIsLiked = widget.isLiked;
    }
    if (oldWidget.likesCount != widget.likesCount) {
      _localLikesCount = widget.likesCount;
    }
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    // 1. Optimistic Update
    setState(() {
      _localIsLiked = !_localIsLiked;
      _localLikesCount = _localIsLiked ? _localLikesCount + 1 : _localLikesCount - 1;
      _showHeart = true;
    });

    // 2. Trigger Animation
    _heartController.forward();

    // 3. Background API Call via parent callback
    widget.onLike();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Header ---
                _buildHeader(),
                const SizedBox(height: 12),
                
                // --- Interactive Content Area ---
                GestureDetector(
                  onDoubleTap: _handleDoubleTap,
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.content.isNotEmpty)
                        Text(widget.content, style: const TextStyle(fontSize: 15, height: 1.4, color: Colors.black87)),
                      
                      if (widget.imageUrls.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildImageGrid(context),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
                
                // --- Actions Bar ---
                Row(
                  children: [
                    _ActionButton(
                      icon: _localIsLiked ? Icons.favorite : Icons.favorite_border,
                      label: _localLikesCount > 0 ? '$_localLikesCount' : 'Like',
                      color: _localIsLiked ? Colors.red : Colors.grey[600]!,
                      onTap: () {
                        // Regular tap also optimistic
                        setState(() {
                          _localIsLiked = !_localIsLiked;
                          _localLikesCount = _localIsLiked ? _localLikesCount + 1 : _localLikesCount - 1;
                        });
                        widget.onLike();
                      },
                    ),
                    const SizedBox(width: 16),
                    _ActionButton(
                      icon: Icons.chat_bubble_outline,
                      label: widget.commentsCount > 0 ? '${widget.commentsCount}' : 'Comment',
                      color: Colors.grey[600]!,
                      onTap: widget.onComment,
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: widget.onShare, 
                      icon: Icon(Icons.share_outlined, color: Colors.grey[600], size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // --- Premium Heart Pop Overlay ---
          if (_showHeart)
            AnimatedBuilder(
              animation: _heartController,
              builder: (context, child) {
                return Opacity(
                  opacity: _heartOpacity.value,
                  child: Transform.scale(
                    scale: _heartScale.value,
                    child: Icon(
                      _localIsLiked ? Icons.favorite : Icons.favorite_outline,
                      color: _localIsLiked ? Colors.red.withOpacity(0.9) : Colors.grey.withOpacity(0.7),
                      size: 100,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return GestureDetector(
      onTap: widget.onProfileTap,
      child: Row(
        children: [
          CachedAvatar(
            imageUrl: widget.authorPhoto,
            radius: 20,
            fallbackText: widget.userName,
          ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(child: Text(widget.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  if (widget.userDepartment == 'CSE' || widget.userDepartment == 'Admin') ...[
                     const SizedBox(width: 4),
                     Icon(Icons.verified, size: 14, color: Colors.blue[400])
                  ]
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(widget.userDepartment, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  const SizedBox(width: 4),
                  Text('•', style: TextStyle(color: Colors.grey, fontSize: 10)),
                  const SizedBox(width: 4),
                  Text(widget.timeAgo, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  if (widget.isEdited) ...[
                    const SizedBox(width: 4),
                    Text('(Edited)', style: TextStyle(color: Colors.grey[500], fontSize: 11, fontStyle: FontStyle.italic)),
                  ],
                  const SizedBox(width: 4),
                  Icon(
                    widget.visibility == 'public' ? Icons.public : (widget.visibility == 'friends' ? Icons.people : Icons.school),
                    size: 12,
                    color: Colors.grey[500],
                  )
                ],
              ),
            ],
          ),
        ),
        _buildMoreMenu(),
      ],
      ),
    );
  }

  Widget _buildMoreMenu() {
    return widget.isOwner ? PopupMenuButton<String>(
            icon: Icon(Icons.more_horiz, color: Colors.grey),
            onSelected: (value) {
              if (value == 'edit') widget.onEdit?.call();
              if (value == 'archive') widget.onArchive?.call();
              if (value == 'delete') widget.onDelete?.call();
              if (value == 'history') widget.onViewHistory?.call();
            },
            itemBuilder: (context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'edit',
                child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit post')]),
              ),
              if (widget.isEdited)
                PopupMenuItem<String>(
                  value: 'history',
                  child: Row(children: [Icon(Icons.history, size: 18), SizedBox(width: 8), Text('View history')]),
                ),
              PopupMenuItem<String>(
                value: 'archive',
                child: Row(children: [Icon(Icons.archive_outlined, size: 18), SizedBox(width: 8), Text('Archive')]),
              ),
              PopupMenuItem<String>(
                value: 'delete',
                child: Row(children: [Icon(Icons.delete_outline, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))]),
              ),
            ],
          ) : const SizedBox.shrink();
  }

  Widget _buildImageGrid(BuildContext context) {
    if (widget.imageUrls.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: 500),
          child: CachedImage(imageUrl: widget.imageUrls[0], fit: BoxFit.fitWidth),
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: widget.imageUrls.length > 4 ? 4 : widget.imageUrls.length,
      itemBuilder: (context, index) {
        if (index == 3 && widget.imageUrls.length > 4) {
             return ClipRRect(
               borderRadius: BorderRadius.circular(8),
               child: Stack(
                 fit: StackFit.expand,
                 children: [
                   CachedImage(imageUrl: widget.imageUrls[index], fit: BoxFit.cover),
                   Container(
                     color: Colors.black.withOpacity(0.5),
                     child: Center(child: Text('+${widget.imageUrls.length - 3}', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
                   )
                 ]
               )
             );
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedImage(imageUrl: widget.imageUrls[index], fit: BoxFit.cover),
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
