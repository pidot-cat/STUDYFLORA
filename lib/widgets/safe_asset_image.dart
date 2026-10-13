import 'package:flutter/material.dart';

/// Loads an asset image and falls back to a neutral placeholder if the file
/// has not been added to `assets/images/` yet.
class SafeAssetImage extends StatelessWidget {
  const SafeAssetImage({
    super.key,
    required this.path,
    required this.fallbackIcon,
    this.fallbackBackground = const Color(0xFFD9E8DF),
    this.fallbackForeground = const Color(0xFF1B5E45),
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
  });

  final String path;
  final IconData fallbackIcon;
  final Color fallbackBackground;
  final Color fallbackForeground;
  final BoxFit fit;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      path,
      fit: fit,
      alignment: alignment,
      errorBuilder: (_, __, ___) => Container(
        color: fallbackBackground,
        alignment: Alignment.center,
        child: Icon(fallbackIcon, color: fallbackForeground),
      ),
    );
  }
}
