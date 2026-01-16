import 'package:flutter/material.dart';

class AppColors {
  // AMOLED & Premium Palette
  static const Color primary = Color(0xFF1E293B); 
  static const Color amoledBlack = Color(0xFF000000); // True AMOLED Black
  static const Color accent = Color(0xFFFF85A1);  
  static const Color secondary = Color(0xFFFDE2E4); 
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF334155)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient pinkGradient = LinearGradient(
    colors: [Color(0xFFFF85A1), Color(0xFFFDA4AF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient amoledGradient = LinearGradient(
    colors: [Color(0xFF000000), Color(0xFF1E293B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Backgrounds & Surfaces
  static const Color background = Color(0xFFFFFFFF); 
  static const Color surface = Color(0xFFF8FAFC);    
  static const Color inputBackground = Color(0xFFF1F5F9); 
  static const Color cardPink = Color(0xFFFFF0F5);   
  
  // Text
  static const Color textPrimary = Color(0xFF0F172A); 
  static const Color textSecondary = Color(0xFF64748B); 
}
