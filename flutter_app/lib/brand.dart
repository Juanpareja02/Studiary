import 'package:flutter/material.dart';

/// Tokens visuales extraídos del brand kit oficial de Studiary.
abstract final class StudiaryBrand {
  static const ink = Color(0xFF27345E);
  static const inkMuted = Color(0xFF556080);
  static const primary = Color(0xFF8A9BFF);
  static const lavender = Color(0xFFB9A7F8);
  static const mint = Color(0xFF8FD9C2);
  static const coral = Color(0xFFF58F8F);
  static const butter = Color(0xFFFFF0B8);
  static const hamster = Color(0xFFD7A46A);
  static const background = Color(0xFFFFF4DE);
  static const surface = Colors.white;
  static const darkSurface = Color(0xFF1D284A);
  static const error = Color(0xFFB53F59);

  static const controlRadius = 12.0;
  static const cardRadius = 20.0;
  static const modalRadius = 28.0;
}

abstract final class BrandAssets {
  static const appIcon = 'assets/branding/app-icon/studiary-app-icon.png';
  static const logo =
      'assets/branding/logos/studiary-logo-primary-transparent.png';
  static const symbol = 'assets/branding/logos/studiary-symbol-512.png';
  static const pattern = 'assets/branding/patterns/studiary-pattern-800.png';

  static const mascotEncourage =
      'assets/branding/mascot/studiary-mascot-encourage.png';
  static const mascotFocus = 'assets/branding/mascot/studiary-mascot-focus.png';
  static const mascotCelebrate =
      'assets/branding/mascot/studiary-mascot-celebrate.png';
  static const mascotReminder =
      'assets/branding/mascot/studiary-mascot-reminder.png';
}

enum MascotPose { encourage, focus, celebrate, reminder }

extension MascotPoseAsset on MascotPose {
  String get asset => switch (this) {
    MascotPose.encourage => BrandAssets.mascotEncourage,
    MascotPose.focus => BrandAssets.mascotFocus,
    MascotPose.celebrate => BrandAssets.mascotCelebrate,
    MascotPose.reminder => BrandAssets.mascotReminder,
  };
}
