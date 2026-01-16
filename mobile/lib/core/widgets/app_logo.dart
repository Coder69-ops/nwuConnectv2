import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool isLight;

  const AppLogo({
    super.key, 
    this.size = 60,
    this.isLight = true, // If true, text is white (for dark backgrounds)
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'app_logo',
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset(
          'assets/images/logo.png',
          height: size,
          width: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
