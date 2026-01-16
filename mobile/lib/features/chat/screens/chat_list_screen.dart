import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../providers/chat_provider.dart';
import '../providers/presence_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/cached_image.dart';
import '../../notification/widgets/notification_button.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conversationsAsync = ref.watch(chatConversationsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Chats', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: -0.5)),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt_rounded, color: AppColors.textPrimary),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, color: AppColors.textPrimary, size: 28),
            onPressed: () {},
          ),
          const NotificationButton(),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Messenger Style Search
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 5, 20, 15),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(22),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search',
                  hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.5), fontSize: 16),
                  prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          
          Expanded(
            child: conversationsAsync.when(
              data: (conversations) {
                final filtered = conversations.where((c) => 
                  c.otherUser.name.toLowerCase().contains(_searchQuery)
                ).toList();

                return CustomScrollView(
                  slivers: [
                    // Stories / Active Users Row
                    SliverToBoxAdapter(
                      child: _buildStoriesRow(conversations),
                    ),
                    
                    const SliverToBoxAdapter(child: SizedBox(height: 10)),

                    if (filtered.isEmpty)
                      SliverFillRemaining(child: _buildEmptyState())
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildConversationCard(context, filtered[index]),
                          childCount: filtered.length,
                        ),
                      ),
                  ],
                );
              },
              loading: () => Skeletonizer(
                enabled: true,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemCount: 5,
                  itemBuilder: (context, index) => _buildConversationCard(context, _mockConversation()),
                ),
              ),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoriesRow(List<Conversation> conversations) {
    // Extract unique users from conversations for the "Active" row
    final users = conversations.map((c) => c.otherUser).toList();

    return Container(
      height: 100,
      margin: const EdgeInsets.only(top: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: users.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildAddStoryItem();
          }
          final user = users[index - 1];
          final presenceAsync = ref.watch(userPresenceProvider(user.id));
          final isOnline = presenceAsync.value?.isOnline ?? false;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isOnline ? AppColors.accent : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.surface,
                        backgroundImage: user.photo.isNotEmpty ? NetworkImage(user.photo) : null,
                        child: user.photo.isEmpty 
                          ? Text(user.name[0], style: const TextStyle(fontWeight: FontWeight.bold)) 
                          : null,
                      ),
                    ),
                    if (isOnline)
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 70,
                  child: Text(
                    user.name.split(' ')[0],
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddStoryItem() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, color: AppColors.textPrimary, size: 30),
          ),
          const SizedBox(height: 6),
          const Text('Your Story', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildConversationCard(BuildContext context, Conversation conversation) {
    final otherUser = conversation.otherUser;
    final presenceAsync = ref.watch(userPresenceProvider(otherUser.id));

    return InkWell(
      onTap: () {
        context.push('/chat/details', extra: {
          'conversationId': conversation.id,
          'targetUser': otherUser,
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            // Avatar with Gradient Border and Presence Dot
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.pinkGradient,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.surface,
                      backgroundImage: otherUser.photo.isNotEmpty ? NetworkImage(otherUser.photo) : null,
                      child: otherUser.photo.isEmpty 
                        ? Text(otherUser.name[0], style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)) 
                        : null,
                    ),
                  ),
                ),
                if (presenceAsync.value?.isOnline ?? false)
                  Positioned(
                    right: 4,
                    bottom: 4,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            
            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        otherUser.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        timeago.format(conversation.lastMessageAt, locale: 'en_short'),
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary.withOpacity(0.7)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    conversation.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontWeight: conversation.lastMessage.isNotEmpty ? FontWeight.w400 : FontWeight.w300,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 64, color: AppColors.textSecondary.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? "No conversations yet" : "No results for '$_searchQuery'",
            style: TextStyle(color: AppColors.textSecondary.withOpacity(0.5), fontSize: 16),
          ),
        ],
      ),
    );
  }

  Conversation _mockConversation() {
    return Conversation(
      id: "mock",
      lastMessage: "Loading message...",
      lastMessageAt: DateTime.now(),
      otherUser: ChatUser(id: "1", name: "User Name", photo: ""),
    );
  }
}
