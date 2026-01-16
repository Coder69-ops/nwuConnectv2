import 'package:flutter/material.dart';
import '../../../core/widgets/cached_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appinio_swiper/appinio_swiper.dart';
import '../../../models/candidate_model.dart';
import '../providers/connect_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/premium_dialog.dart';
import '../widgets/match_dialog.dart';
import '../widgets/match_dialog.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notification/widgets/notification_button.dart';

class ConnectScreen extends ConsumerStatefulWidget {
  const ConnectScreen({super.key});

  @override
  ConsumerState<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends ConsumerState<ConnectScreen> {
  final AppinioSwiperController controller = AppinioSwiperController();

  Future<void> _handleSwipe(int index, SwiperActivity activity, List<Candidate> candidates) async {
    final candidate = candidates[index];
    final dir = activity.direction.toString().toLowerCase();
    final action = dir.contains('right') || dir.contains('top') ? 'like' : 'pass';
    
    // 2. Performance: API Call (Optimistic is handled by AppinioSwiper moving the card)
    try {
      final matchData = await ref.read(swipeActionProvider.notifier).swipe(
        targetId: candidate.userId,
        action: action,
      );

      if (matchData != null && mounted) {
        final currentUser = ref.read(currentUserProvider).value;
        
        // 3. Match Success Popup!
        MatchDialog.show(
          context,
          targetId: candidate.userId,
          targetName: matchData['targetName'] ?? candidate.name,
          targetPhoto: matchData['targetPhoto'] ?? (candidate.photos.isNotEmpty ? candidate.photos.first : ''),
          myPhoto: currentUser?.photoUrl ?? '',
          matchId: matchData['matchId'] ?? '',
        );
      }
    } catch (e) {
      if (mounted) {
        PremiumDialog.show(
          context,
          title: "Connection Issue",
          message: "We couldn't process your swipe. Please check your network and try again.",
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final candidatesAsync = ref.watch(candidatesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
                title: const Text('Connect', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),

        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: NotificationButton(),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: candidatesAsync.when(
            data: (candidates) {
              if (candidates.isEmpty) {
                return _buildEmptyState();
              }

              return Column(
                children: [
                  Expanded(
                    child: AppinioSwiper(
                      controller: controller,
                      cardCount: candidates.length,
                      onSwipeEnd: (int previousIndex, int targetIndex, SwiperActivity activity) {
                         _handleSwipe(previousIndex, activity, candidates);
                      },
                      cardBuilder: (BuildContext context, int index) {
                         return _buildCard(candidates[index]);
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildControls(),
                  const SizedBox(height: 20),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
            error: (err, stack) => Center(child: Text('Something went wrong: $err')),
          ),
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
             padding: const EdgeInsets.all(20),
             decoration: BoxDecoration(
               color: Colors.white,
               shape: BoxShape.circle,
               boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
             ),
             child: const Icon(Icons.people_outline, size: 64, color: Colors.grey),
           ),
           const SizedBox(height: 24),
           const Text(
             'No more explorers!',
             style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
           ),
           const SizedBox(height: 8),
           const Text(
             'Check back later for new connections.',
             textAlign: TextAlign.center,
             style: TextStyle(color: Colors.grey, fontSize: 16),
           ),
         ],
       ),
     );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => controller.swipeLeft(),
          child: _CircleButton(
            icon: Icons.close_rounded,
            color: AppColors.primary, // Slate Black
            size: 60,
          ),
        ),
        const SizedBox(width: 40),
        GestureDetector(
          onTap: () => controller.swipeRight(),
          child: _CircleButton(
            icon: Icons.favorite_rounded,
            color: AppColors.accent, // Rose Pink
            size: 60,
          ),
        ),
      ],
    );
  }

  Widget _buildCard(Candidate candidate) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background Photo (Cached)
                candidate.photos.isNotEmpty 
                  ? CachedImage(imageUrl: candidate.photos.first)
                  : Container(
                      color: const Color(0xFFE5E7EB),
                      child: const Icon(Icons.person, size: 120, color: Colors.white),
                    ),
                
                // Content Overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.1),
                          Colors.black.withOpacity(0.8),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                
                // Info
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            candidate.name,
                            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          if (candidate.department == 'CSE')
                             const Icon(Icons.verified, color: Colors.blue, size: 24),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          candidate.department,
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (candidate.bio != null) 
                        Text(
                          candidate.bio!,
                          style: const TextStyle(color: Colors.white70, fontSize: 16),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const _CircleButton({required this.icon, required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}
