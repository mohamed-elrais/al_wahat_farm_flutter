import 'package:flutter/material.dart';

abstract final class AppColors {
  static const paper = Color(0xFFF8F4E9);
  static const card = Color(0xFFFFFDF7);
  static const ink = Color(0xFF173D28);
  static const green = Color(0xFF285C36);
  static const orange = Color(0xFFCC6637);
  static const muted = Color(0xFF6E7168);
  static const line = Color(0xFFE5DCC8);
  static const softGreen = Color(0xFFE8EFDE);
  static const sand = Color(0xFFE8D6AE);
  static const road = Color(0xFFB9A47D);
  static const issue = Color(0xFFB65535);
  static const waterMain = Color(0xFF2F6E99);
  static const waterSubmain = Color(0xFF5B8CAB);
}

abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

abstract final class AppRadii {
  static const control = 11.0;
  static const card = 18.0;
  static const sheet = 24.0;
}

abstract final class AppBreakpoints {
  static const tablet = 820.0;
  static const wide = 1180.0;
}
