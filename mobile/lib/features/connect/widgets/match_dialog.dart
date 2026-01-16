import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/cached_image.dart';
import '../../chat/providers/chat_provider.dart';
import 'package:go_router/go_router.dart';

class MatchDialog extends ConsumerStatefulWidget {
  final String targetId;
  final String targetName;
  final String targetPhoto;
  final String myPhoto;
  final String matchId;

  const MatchDialog({
    super.key,
    required this.targetId,
    required this.targetName,
    required this.targetPhoto,
    required this.myPhoto,
    required this.matchId,
  });

  static Future<void> show(
    BuildContext context, {
    required String targetId,
    required String targetName,
    required String targetPhoto,
    required String myPhoto,
    required String matchId,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false, // Force interaction
      builder: (context) => MatchDialog(
        targetId: targetId,
        targetName: targetName,
        targetPhoto: targetPhoto,
        myPhoto: myPhoto,
        matchId: matchId,
      ),
    );
  }

  @override
  ConsumerState<MatchDialog> createState() => _MatchDialogState();
}

class _MatchDialogState extends ConsumerState<MatchDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _myAvatarOffset;
  late Animation<Offset> _targetAvatarOffset;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _myAvatarOffset = Tween<Offset>(
      begin: const Offset(-2, 0),
      end: const Offset(-0.3, 0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
    ));

    _targetAvatarOffset = Tween<Offset>(
      begin: const Offset(2, 0),
      end: const Offset(0.3, 0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sayHello() async {
    setState(() => _isSending = true);
    try {
      await ref.read(chatActionProvider.notifier).sendMessage(
        widget.targetId,
        "Hey ${widget.targetName}, we matched! 👋",
      );
      if (mounted) {
        Navigator.pop(context);
        context.push('/chat/details', extra: {
          'conversationId': widget.matchId,
          'targetUser': ChatUser(
            id: widget.targetId,
            name: widget.targetName,
            photo: widget.targetPhoto,
          ),
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.amoledBlack,
      body: Stack(
        children: [
          // Aura Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.amoledBlack,
                    Color(0xFF0F172A),
                    AppColors.amoledBlack,
                  ],
                ),
              ),
            ),
          ),

          // Animated Aura Circles
          _AnimatedAuraCircle(
            color: AppColors.accent.withOpacity(0.15),
            top: 100,
            left: -50,
            size: 300,
          ),
          _AnimatedAuraCircle(
            color: AppColors.primary.withOpacity(0.25),
            bottom: 100,
            right: -50,
            size: 350,
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title Animation
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Column(
                        children: [
                          const Text(
                            "It's a Match! 💖",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "You both liked each other",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 18,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 80),

                    // Avatars Animation
                    SizedBox(
                      height: 160,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SlideTransition(
                            position: _myAvatarOffset,
                            child: _buildAvatar(widget.myPhoto, isMine: true),
                          ),
                          SlideTransition(
                            position: _targetAvatarOffset,
                            child: _buildAvatar(widget.targetPhoto, isMine: false),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 80),

                    // Interaction Buttons
                    FadeTransition(
                      opacity: _scaleAnimation,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            _buildSayHelloButton(),
                            const SizedBox(height: 24),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white60,
                              ),
                              child: const Text(
                                "Keep Exploring",
                                style: TextStyle(
                                  fontSize: 16, 
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSayHelloButton() {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: AppColors.pinkGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSending ? null : _sayHello,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: _isSending 
          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : const Text(
              "Say Hello 👋", 
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
      ),
    );
  }

  Widget _buildAvatar(String photoUrl, {required bool isMine}) {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.9), 
          width: 5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isMine ? AppColors.accent : AppColors.primary).withOpacity(0.3),
            blurRadius: 25,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: photoUrl.isNotEmpty
            ? CachedImage(imageUrl: photoUrl, fit: BoxFit.cover)
            : Container(
                color: AppColors.surface, 
                child: const Icon(Icons.person, size: 60, color: AppColors.textSecondary),
              ),
      ),
    );
  }
}

class _AnimatedAuraCircle extends StatelessWidget {
  final Color color;
  final double? top, bottom, left, right;
  final double size;

  const _AnimatedAuraCircle({
    required this.color,
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
        child: BackdropFilter(
          filter: ColorFilter.mode(
            Colors.white.withOpacity(0.05),
            BlendMode.overlay,
          ),
          child: const SizedBox.shrink(),
        ),
      ),
    );
  }
}
