import 'dart:io';
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

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(chatActionProvider.notifier).markAsRead(widget.conversationId));
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
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
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
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
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 120), // Extra bottom padding for floating pill
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
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
                  error: (err, stack) => Center(child: Text('Error: $err')),
                ),
              ),
            ],
          ),
          
          // Floating AMOLED Pill
          Positioned(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).padding.bottom + 10,
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
      backgroundColor: Colors.white.withOpacity(0.9),
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.surface,
                backgroundImage: widget.targetUser.photo.isNotEmpty 
                  ? NetworkImage(widget.targetUser.photo) 
                  : null,
                child: widget.targetUser.photo.isEmpty 
                  ? Text(widget.targetUser.name[0], style: const TextStyle(color: AppColors.accent, fontSize: 14)) 
                  : null,
              ),
              if (isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    height: 10,
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.targetUser.name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.3),
              ),
              Text(
                isOnline ? 'Active now' : 'Active ${timeago.format(presenceAsync.value?.lastSeen ?? DateTime.now(), locale: 'en_short')}', 
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary.withOpacity(0.6), fontWeight: FontWeight.w500)
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(icon: const Icon(Icons.videocam_rounded, color: AppColors.accent), onPressed: () {}),
        IconButton(icon: const Icon(Icons.info_rounded, color: AppColors.accent), onPressed: () {}),
        const SizedBox(width: 10),
      ],
    );
  }

  Widget _buildMessageRow(Message msg, bool isMe) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundImage: widget.targetUser.photo.isNotEmpty 
                ? NetworkImage(widget.targetUser.photo) 
                : null,
              child: widget.targetUser.photo.isEmpty 
                ? Text(widget.targetUser.name[0], style: const TextStyle(fontSize: 10)) 
                : null,
            ),
            const SizedBox(width: 8),
          ],
          _buildMessageBubble(msg, isMe),
          if (isMe) ...[
            const SizedBox(width: 4),
            _buildStatusIndicator(msg.status),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message msg, bool isMe) {
    return GestureDetector(
      onLongPress: () => _showReactionPicker(msg),
      child: Container(
        padding: msg.type == 'image' ? const EdgeInsets.all(4) : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          color: isMe ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(22).copyWith(
            bottomLeft: Radius.circular(isMe ? 22 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 22),
          ),
        ),
        child: msg.type == 'image' 
            ? ClipRRect(
                borderRadius: BorderRadius.circular(18),
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
                  height: 1.3,
                  fontWeight: FontWeight.w400,
                ),
              ),
      ),
    );
  }

  void _showReactionPicker(Message msg) {
    final emojis = ['❤️', '😂', '😮', '😢', '😡', '👍'];
    showDialog(
      context: context,
      builder: (ctx) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          margin: const EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: emojis.map((e) => GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(e, style: const TextStyle(fontSize: 24, decoration: TextDecoration.none)),
              ),
            )).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(String status) {
    if (status == 'seen') {
      return CircleAvatar(
        radius: 6,
        backgroundImage: widget.targetUser.photo.isNotEmpty 
          ? NetworkImage(widget.targetUser.photo) 
          : null,
        child: widget.targetUser.photo.isEmpty 
          ? Text(widget.targetUser.name[0], style: const TextStyle(fontSize: 4)) 
          : null,
      );
    }
    
    IconData icon = status == 'delivered' ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded;
    Color color = AppColors.textSecondary.withOpacity(0.2);
    
    return Icon(icon, size: 12, color: color);
  }

  Widget _buildTimestamp(DateTime time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text(
        DateFormat('h:mm a').format(time),
        style: TextStyle(fontSize: 11, color: AppColors.textSecondary.withOpacity(0.4), fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: widget.targetUser.photo.isNotEmpty ? NetworkImage(widget.targetUser.photo) : null,
            child: widget.targetUser.photo.isEmpty ? Text(widget.targetUser.name[0], style: const TextStyle(fontSize: 32)) : null,
          ),
          const SizedBox(height: 20),
          Text(widget.targetUser.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          const Text("You're friends on NWU Connect", style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    final isLoading = ref.watch(chatActionProvider).isLoading;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.amoledBlack,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _messageController,
              maxLines: null,
              enabled: !isLoading,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Message...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: isLoading ? null : _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isLoading ? Colors.grey[800] : AppColors.accent,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
