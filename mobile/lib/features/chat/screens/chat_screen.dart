import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../providers/chat_provider.dart';
import '../providers/presence_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/cached_image.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final ChatUser targetUser;

  const ChatScreen({super.key, required this.conversationId, required this.targetUser});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> with TickerProviderStateMixin {
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  late AnimationController _sendButtonController;

  @override
  void initState() {
    super.initState();
    _sendButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    Future.microtask(() => ref.read(chatActionProvider.notifier).markAsRead(widget.conversationId));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _sendButtonController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    _sendButtonController.forward().then((_) => _sendButtonController.reverse());
    await ref.read(chatActionProvider.notifier).sendMessage(widget.targetUser.id, text);
    _scrollToBottom();
  }

  void _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      final url = await ref.read(chatActionProvider.notifier).uploadImage(image.path);
      if (url != null) {
        await ref.read(chatActionProvider.notifier).sendMessage(
          widget.targetUser.id, 
          "Sent a photo", 
          type: 'image', 
          imageUrl: url
        );
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatStreamProvider(widget.conversationId));

    return Scaffold(
      backgroundColor: AppColors.background, // Light Theme
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          // Background Pattern
          Positioned.fill(
            child: CustomPaint(
              painter: _ChatBackgroundPainter(),
            ),
          ),
          
          // Messages
          Column(
            children: [
              Expanded(
                child: messagesAsync.when(
                  data: (messages) {
                    if (messages.isEmpty) {
                      return _buildEmptyState();
                    }
                    
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 100, 16, 120),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe = msg.senderId != widget.targetUser.id;
                        final showTime = index == 0 || 
                            msg.createdAt.difference(messages[index - 1].createdAt).inMinutes > 5;

                        return Column(
                          children: [
                            if (showTime) _buildTimestamp(msg.createdAt),
                            _buildMessageRow(msg, isMe),
                          ],
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 3,
                    ),
                  ),
                  error: (err, stack) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.primary, size: 48),
                        const SizedBox(height: 16),
                        Text('Error: $err', style: const TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // Floating Input Area with Light Glassmorphism
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 12,
            child: _buildInputArea(),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final presenceAsync = ref.watch(userPresenceProvider(widget.targetUser.id));
    final isOnline = presenceAsync.value?.isOnline ?? false;

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8), // Frosted glass
              border: Border(
                bottom: BorderSide(
                  color: AppColors.textSecondary.withOpacity(0.05),
                  width: 1,
                ),
              ),
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isOnline ? Colors.white : Colors.transparent,
                    width: isOnline ? 0 : 0,
                  ),
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.surface,
                  backgroundImage: widget.targetUser.photo.isNotEmpty 
                    ? NetworkImage(widget.targetUser.photo) 
                    : null,
                  child: widget.targetUser.photo.isEmpty 
                    ? Text(widget.targetUser.name[0], style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)) 
                    : null,
                ),
              ),
              if (isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.targetUser.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  isOnline ? 'Active now' : 'Active ${timeago.format(presenceAsync.value?.lastSeen ?? DateTime.now(), locale: 'en_short')}', 
                  style: TextStyle(
                    fontSize: 11,
                    color: isOnline ? Colors.green : AppColors.textSecondary.withOpacity(0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.videocam_rounded, color: AppColors.textPrimary.withOpacity(0.7), size: 26),
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(Icons.info_outline_rounded, color: AppColors.textPrimary.withOpacity(0.7), size: 24),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildMessageRow(Message msg, bool isMe) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[ 
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.surface,
              backgroundImage: widget.targetUser.photo.isNotEmpty 
                ? NetworkImage(widget.targetUser.photo) 
                : null,
              child: widget.targetUser.photo.isEmpty 
                ? Text(widget.targetUser.name[0], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)) 
                : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(child: _buildMessageBubble(msg, isMe)),
          if (isMe) ...[ 
            const SizedBox(width: 6),
            _buildStatusIndicator(msg.status),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message msg, bool isMe) {
    return GestureDetector(
      onLongPress: () => _showReactionPicker(msg),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: msg.type == 'image' ? const EdgeInsets.all(4) : const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          // Gradient for ME, Soft Grey for OTHER
          gradient: isMe ? AppColors.pinkGradient : null,
          color: isMe ? null : const Color(0xFFF2F4F7), // Soft grey/blue
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomLeft: Radius.circular(isMe ? 20 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 20),
          ),
          boxShadow: [
             if (isMe)
              BoxShadow(
                color: AppColors.primary.withOpacity(0.2), // Softer shadow
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: msg.type == 'image' 
          ? ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedImage(
                imageUrl: msg.imageUrl ?? '',
                fit: BoxFit.cover,
              ),
            )
          : Text(
              msg.content,
              style: TextStyle(
                color: isMe ? Colors.white : AppColors.textPrimary,
                fontSize: 15,
                height: 1.4,
                fontWeight: FontWeight.w400,
              ),
            ),
      ),
    );
  }

  void _showReactionPicker(Message msg) {
    // ... (keeps same implementation, maybe subtle style tweak) ...
    // Using previous implementation for brevity unless change needed
    final emojis = ['❤️', '😂', '😮', '😢', '😡', '👍'];
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.1), // Lighter barrier
      builder: (ctx) => Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              margin: const EdgeInsets.symmetric(horizontal: 40),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: emojis.map((e) => GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      e,
                      style: const TextStyle(
                        fontSize: 28,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                )).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(String status) {
    if (status == 'seen') {
      return CircleAvatar(
        radius: 7,
        backgroundColor: AppColors.surface,
        backgroundImage: widget.targetUser.photo.isNotEmpty 
          ? NetworkImage(widget.targetUser.photo) 
          : null,
        child: widget.targetUser.photo.isEmpty 
          ? Text(widget.targetUser.name[0], style: const TextStyle(fontSize: 6, fontWeight: FontWeight.bold)) 
          : null,
      );
    }
    
    IconData icon = status == 'delivered' ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded;
    Color color = status == 'delivered' 
      ? AppColors.primary.withOpacity(0.5)
      : AppColors.textSecondary.withOpacity(0.3);
    
    return Icon(icon, size: 14, color: color);
  }

  Widget _buildTimestamp(DateTime time) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface, // Use surface instead of grey
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.textSecondary.withOpacity(0.1)),
      ),
      child: Text(
        DateFormat('h:mm a').format(time),
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              gradient: AppColors.pinkGradient,
              shape: BoxShape.circle,
            ),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.surface,
                backgroundImage: widget.targetUser.photo.isNotEmpty ? NetworkImage(widget.targetUser.photo) : null,
                child: widget.targetUser.photo.isEmpty 
                  ? Text(widget.targetUser.name[0], style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary)) 
                  : null,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            widget.targetUser.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "You're friends on NWU Connect",
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    final isLoading = ref.watch(chatActionProvider).isLoading;

    // Light Glass Styling
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withOpacity(1),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.textSecondary.withOpacity(0.1), // Softer shadow
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withOpacity(0.08), // Subtle grey circle
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add_photo_alternate_rounded, color: AppColors.textSecondary, size: 20),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  maxLines: null,
                  enabled: !isLoading,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 16), // Dark text
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.5),
                      fontSize: 16,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ScaleTransition(
                scale: Tween<double>(begin: 1.0, end: 0.9).animate(_sendButtonController),
                child: GestureDetector(
                  onTap: isLoading ? null : _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: isLoading ? null : AppColors.pinkGradient,
                      color: isLoading ? Colors.grey[300] : null,
                      shape: BoxShape.circle,
                      boxShadow: isLoading ? null : [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom Background Painter for subtle dark pattern (Light Mode)
class _ChatBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textSecondary.withOpacity(0.03) // Very subtle dark dots
      ..style = PaintingStyle.fill;

    for (double i = 0; i < size.width; i += 30) {
      for (double j = 0; j < size.height; j += 30) {
        if ((i+j) % 60 == 0) { // Staggered or sparse pattern
           canvas.drawCircle(Offset(i, j), 1.5, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
