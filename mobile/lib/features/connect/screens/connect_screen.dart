import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/cached_image.dart';
import '../../../models/candidate_model.dart';
import '../providers/connect_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/premium_dialog.dart';
import '../widgets/match_dialog.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notification/widgets/notification_button.dart';

// Constants for physics
const double kSwipeThreshold = 100.0;
const double kRotationFactor = 0.05; // RADIANS per pixel dragged

class ConnectScreen extends ConsumerStatefulWidget {
  const ConnectScreen({super.key});

  @override
  ConsumerState<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends ConsumerState<ConnectScreen> with TickerProviderStateMixin {
  // State for the top card
  Offset _dragOffset = Offset.zero;
  AnimationController? _slideBackController;
  Animation<Offset>? _slideBackAnimation;
  int _currentPhotoIndex = 0; // Track current photo
  
  // To track which card is currently top (optimistic updates)
  int _removedCount = 0;

  @override
  void dispose() {
    _slideBackController?.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta;
    });
  }

  void _onTapUp(TapUpDetails details, int totalPhotos, double width) {
    if (totalPhotos <= 1) return;

    final isRightTap = details.localPosition.dx > width / 2;
    setState(() {
      if (isRightTap) {
        if (_currentPhotoIndex < totalPhotos - 1) {
          _currentPhotoIndex++;
        } else {
             _currentPhotoIndex = 0; // Loop back or stop? Let's loop for now or stop. standard is stop.
        }
      } else {
        if (_currentPhotoIndex > 0) {
          _currentPhotoIndex--;
        }
      }
    });
  }

  void _onPanEnd(DragEndDetails details, Candidate candidate) {
    if (_dragOffset.dx.abs() > kSwipeThreshold) {
      // Swipe triggered
      final isRight = _dragOffset.dx > 0;
      _handleSwipeComplete(isRight, candidate);
    } else {
      // Spring back to center
      _slideBackController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      );
      
      _slideBackAnimation = Tween<Offset>(
        begin: _dragOffset,
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideBackController!,
        curve: Curves.easeOutBack,
      ));

      _slideBackController!.addListener(() {
        setState(() {
          _dragOffset = _slideBackAnimation!.value;
        });
      });

      _slideBackController!.forward();
    }
  }

  Future<void> _handleSwipeComplete(bool isRight, Candidate candidate) async {
    final action = isRight ? 'like' : 'pass';
    final width = MediaQuery.of(context).size.width;
    final endX = isRight ? width * 1.5 : -width * 1.5;

    // Animate off screen
    setState(() {
      _dragOffset = Offset(endX, _dragOffset.dy);
    });

    // Need a small delay to let the animation play before rebuilding the stack
    await Future.delayed(const Duration(milliseconds: 200));
    
    // Optimistically remove from view
    setState(() {
      _removedCount++;
      _dragOffset = Offset.zero;
      _currentPhotoIndex = 0; // Reset photo index for next card
    });

    // Provide haptic feedback
    if (isRight) {
       HapticFeedback.heavyImpact();
    } else {
       HapticFeedback.lightImpact();
    }

    // Call API
    try {
      final matchData = await ref.read(swipeActionProvider.notifier).swipe(
        targetId: candidate.userId,
        action: action,
      );

      if (matchData != null && mounted && isRight) {
        final currentUser = ref.read(currentUserProvider).value;
        
        // Show Match Dialog
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
      // If error, maybe show toast? For now silent fail.
    }
  }

  @override
  Widget build(BuildContext context) {
    final candidatesAsync = ref.watch(candidatesProvider);

    return Scaffold(
      backgroundColor: AppColors.background, // Light White Background
      body: Stack(
        children: [
          // 1. Subtle Gradient Background (Light)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    AppColors.surface, // Very light grey/blue
                    AppColors.cardPink, // Subtle pinkish bottom
                  ],
                ),
              ),
            ),
          ),
          
          // 2. Animated Particles (Dark for contrast)
          Positioned.fill(
            child: CustomPaint(
              painter: _ParticlePainter(),
            ),
          ),

          // 3. Main Content
          candidatesAsync.when(
            data: (candidates) {
              // Calculate effective list based on removed count
              final activeCandidates = candidates.skip(_removedCount).toList();

              return Stack(
                children: [
                   // The Card Stack
                  if (activeCandidates.isEmpty)
                    _buildEmptyState()
                  else
                    Positioned.fill(
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top + 60, 
                          bottom: 90, 
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            // Calculate optimized card dimensions based on constraints
                            final cardWidth = constraints.maxWidth * 0.92;
                            // COMPRESSED HEIGHT: Use 75% of available height to avoid cropped feeling
                            // and provide "breathing room"
                            final cardHeight = constraints.maxHeight * 0.75;

                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                // Background Card (Next in line)
                                if (activeCandidates.length > 1)
                                  _buildCard(
                                    activeCandidates[1], 
                                    width: cardWidth,
                                    height: cardHeight,
                                    isFront: false
                                  ),
                                
                                // Front Card (Draggable)
                                GestureDetector(
                                  onPanUpdate: _onPanUpdate,
                                  onPanEnd: (details) => _onPanEnd(details, activeCandidates[0]),
                                  onTapUp: (details) => _onTapUp(details, activeCandidates[0].photos.length, cardWidth),
                                  child: _buildCard(
                                    activeCandidates[0], 
                                    width: cardWidth,
                                    height: cardHeight,
                                    isFront: true
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),

                  // The Glassmorphism Header (Overlay)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: _buildGlassHeader(activeCandidates.length),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
            error: (err, stack) => Center(child: Text('Error loading profiles: $err', style: const TextStyle(color: Colors.black))),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassHeader(int count) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: Colors.white.withOpacity(0.5), // Lighter glass
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 10,
            bottom: 15,
            left: 20,
            right: 20,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Styled Logo / Title
              Row(
                children: [
                  const Icon(Icons.explore_outlined, color: AppColors.textPrimary, size: 28),
                  const SizedBox(width: 8),
                  const Text(
                    "Connect",
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              
              Row(
                children: [
                  // Count Bubble
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                    ),
                    child: Text(
                      "$count Nearby",
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const NotificationButton(), 
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(Candidate candidate, {required double width, required double height, required bool isFront}) {
    // If it's the back card, it stays static in center (maybe slightly smaller)
    // If it's front card, it follows _dragOffset
    
    final transform = Matrix4.identity();
    
    if (isFront) {
      transform.translate(_dragOffset.dx, _dragOffset.dy);
      // Determine rotation based on distance from center
      final rotation = _dragOffset.dx * 0.001; // subtle rotation
      transform.rotateZ(rotation);
    } else {
      // Scale down the back card slightly
      final scale = 0.95;
      final verticalOffset = 10.0; // Show slightly below
      transform.translate(0.0, verticalOffset);
      transform.scale(scale, scale);
    }

    // Stamps Opacity Calculation
    double likeOpacity = 0.0;
    double nopeOpacity = 0.0;
    
    if (isFront && _dragOffset.dx != 0) {
      // Normalize opacity 0 to 1 based on threshold
      final progress = (_dragOffset.dx.abs() / kSwipeThreshold).clamp(0.0, 1.0);
      if (_dragOffset.dx > 0) {
        likeOpacity = progress;
      } else {
        nopeOpacity = progress;
      }
    }

    // Identify which photo to show
    // If not front, just show the first one (0) always
    final photoIndex = isFront ? _currentPhotoIndex : 0;
    final photoUrl = (candidate.photos.isNotEmpty && photoIndex < candidate.photos.length) 
        ? candidate.photos[photoIndex] 
        : (candidate.photos.isNotEmpty ? candidate.photos.first : '');

    return Transform(
      transform: transform,
      alignment: Alignment.center,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: AppColors.cardPink, 
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(isFront ? 0.15 : 0.05), 
              blurRadius: isFront ? 30 : 15,
              offset: isFront ? const Offset(0, 15) : const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Photo with Fade Transition
               photoUrl.isNotEmpty
                ? CachedImage(
                    imageUrl: photoUrl,
                    fit: BoxFit.cover,
                  )
                : Container(
                    color: AppColors.surface,
                    child: const Icon(Icons.person, color: Colors.grey, size: 80),
                  ),

              // Gradient Overlay (Bottom)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.1), // Slight top dim for bars
                        Colors.transparent,
                        Colors.black.withOpacity(0.1),
                        Colors.black.withOpacity(0.8),
                      ],
                      stops: const [0.0, 0.2, 0.6, 1.0],
                    ),
                  ),
                ),
              ),

              // Photo Indicators (Instagram Story Style)
              if (isFront && candidate.photos.length > 1) 
                 Positioned(
                  top: 10, 
                  left: 10, 
                  right: 10,
                  child: Row(
                    children: List.generate(candidate.photos.length, (index) {
                      return Expanded(
                        child: Container(
                          height: 3,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: index == _currentPhotoIndex 
                                ? Colors.white 
                                : Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 2)
                            ]
                          ),
                        ),
                      );
                    }),
                  ),
                 ),

              // Info Content
              Positioned(
                bottom: 30, 
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            candidate.name,
                            style: const TextStyle(
                              color: Colors.white, 
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              height: 1.1,
                              shadows: [Shadow(color: Colors.black45, blurRadius: 5, offset: Offset(0,2))]
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: const Text(
                            'Student', 
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      candidate.department,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        shadows: const [Shadow(color: Colors.black45, blurRadius: 4)]
                      ),
                    ),
                    if (candidate.bio != null && candidate.bio!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        candidate.bio!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 14,
                          height: 1.4,
                          shadows: const [Shadow(color: Colors.black45, blurRadius: 2)]
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ]
                  ],
                ),
              ),

              // STAMPS
              if (isFront) ...[
                // LIKE STAMP 
                Align(
                  alignment: Alignment.center,
                  child: Opacity(
                    opacity: likeOpacity,
                    child: Transform.rotate(
                      angle: -0.2, // Reduced rotation for center stamp
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                           border: Border.all(color: Colors.greenAccent, width: 6),
                           borderRadius: BorderRadius.circular(15),
                           color: Colors.greenAccent.withOpacity(0.2),
                        ),
                        child: const Text(
                          "LIKE",
                          style: TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 52, // Bigger
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // NOPE STAMP
                Align(
                  alignment: Alignment.center,
                  child: Opacity(
                    opacity: nopeOpacity,
                    child: Transform.rotate(
                      angle: 0.2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                           border: Border.all(color: Colors.redAccent, width: 6),
                           borderRadius: BorderRadius.circular(15),
                           color: Colors.redAccent.withOpacity(0.2),
                        ),
                        child: const Text(
                          "NOPE",
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 52, // Bigger
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
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
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person_search_rounded, size: 80, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          const Text(
            "That's everyone for now",
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Check back later for more profiles.",
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () {
              // Refresh logic or manual refresh
              setState(() {
                _removedCount = 0;
              });
              ref.refresh(candidatesProvider);
            },
            icon: const Icon(Icons.refresh),
            label: const Text("Refresh List"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          )
        ],
      ),
    );
  }

  // Helper method for painting particles
  void _drawParticles(Canvas canvas, Size size) {
      // Implementation moved to _ParticlePainter class for simplicity or kept here?
      // Keeping separate class _ParticlePainter below.
  }

}

class _ParticlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textPrimary.withOpacity(0.05) 
      ..style = PaintingStyle.fill;

    // Create a random-ish looking pattern of dots
    final random = math.Random(42); 
    for (var i = 0; i < 50; i++) {
        double x = random.nextDouble() * size.width;
        double y = random.nextDouble() * size.height;
        double radius = random.nextDouble() * 3 + 1;
        canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}



