
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../providers/auth_provider.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/widgets/app_logo.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isLogin = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    
    // Start animation after the first frame to avoid "Build scheduled during frame" error
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await ref.read(authControllerProvider).signInWithEmailPassword(email, password);
      } else {
        await ref.read(authControllerProvider).signUpWithEmailPassword(email, password);
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.amoledBlack,
      body: Stack(
        children: [
          // Dynamic Background Gradients
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.amoledBlack,
                    Color(0xFF0F172A),
                    AppColors.amoledBlack,
                  ],
                ),
              ),
            ),
          ),
          
          // Aesthetic Blurred Circles
          _AnimatedBackgroundCircle(
            color: AppColors.accent.withOpacity(0.12),
            top: -100,
            right: -50,
            size: 300,
          ),
          _AnimatedBackgroundCircle(
            color: AppColors.primary.withOpacity(0.2),
            bottom: -50,
            left: -80,
            size: 400,
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.05),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _animationController,
                      curve: Curves.easeOutCubic,
                    )),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const AppLogo(size: 100, isLight: true),
                        const SizedBox(height: 32),
                        Text(
                          _isLogin ? 'Welcome Back' : 'Create Account',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _isLogin 
                            ? 'Sign in to stay connected with your campus' 
                            : 'Join the premier network for students',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white.withOpacity(0.6),
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 48),

                        // Glassmorphic Form Container
                        ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                            child: Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildTextField(
                                    controller: _emailController,
                                    label: 'UNIVERSITY EMAIL',
                                    hint: 'name@nwu.edu',
                                    icon: Icons.alternate_email_rounded,
                                  ),
                                  const SizedBox(height: 24),
                                  _buildTextField(
                                    controller: _passwordController,
                                    label: 'PASSWORD',
                                    hint: '••••••••',
                                    icon: Icons.lock_outline_rounded,
                                    isObscure: true,
                                  ),
                                  const SizedBox(height: 40),
                                  _buildSubmitButton(),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Alternative Login & Toggle
                        _buildSocialSection(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: AppColors.pinkGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: _isLoading 
          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Text(
              _isLogin ? 'SIGN IN' : 'GET STARTED',
              style: const TextStyle(
                fontWeight: FontWeight.w900, 
                fontSize: 16, 
                letterSpacing: 2,
                color: Colors.white,
              ),
            ),
      ),
    );
  }

  Widget _buildSocialSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'OR CONTINUE WITH', 
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4), 
                  fontSize: 10, 
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
          ],
        ),
        const SizedBox(height: 24),
        
        // Premium Google Button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
               try {
                 await ref.read(authControllerProvider).signInWithGoogle();
               } catch (e) {
                 if (context.mounted) _showError('Google Sign-In Error: $e');
               }
            },
            borderRadius: BorderRadius.circular(18),
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
                color: Colors.white.withOpacity(0.03),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.network(
                    'https://www.gstatic.com/images/branding/product/2x/googleg_48dp.png',
                    height: 22,
                    errorBuilder: (c, e, s) => const Icon(Icons.g_mobiledata, size: 28, color: Colors.white),
                  ), 
                  const SizedBox(width: 12),
                  const Text(
                    'Google',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 48),
        
        GestureDetector(
          onTap: () => setState(() => _isLogin = !_isLogin),
          child: RichText(
            text: TextSpan(
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 15),
              children: [
                TextSpan(text: _isLogin ? "Don't have an account? " : "Already joining? "),
                TextSpan(
                  text: _isLogin ? "Sign Up" : "Sign In",
                  style: const TextStyle(
                    fontWeight: FontWeight.w900, 
                    color: AppColors.accent,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isObscure = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Colors.white.withOpacity(0.5),
              letterSpacing: 1.2,
            ),
          ),
        ),
        TextField(
          controller: controller,
          obscureText: isObscure,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
          cursorColor: AppColors.accent,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
            prefixIcon: Icon(icon, color: AppColors.accent.withOpacity(0.7), size: 20),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.accent, width: 2),
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.03),
            contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          ),
        ),
      ],
    );
  }
}

class _AnimatedBackgroundCircle extends StatelessWidget {
  final Color color;
  final double? top, bottom, left, right;
  final double size;

  const _AnimatedBackgroundCircle({
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
          filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
          child: const SizedBox.shrink(),
        ),
      ),
    );
  }
}
