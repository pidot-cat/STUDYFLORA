import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography helpers. The mock-ups use three families:
///  * Poppins – most app screens (Home, Garden, Shop, Inventory)
///  * Plus Jakarta Sans – auth screens, quiz, settings detail screens
///  * Playfair Display – the "StudyFlora" wordmark & a few serif titles
class T {
  static TextStyle p(double size,
          {FontWeight w = FontWeight.w400, Color? c, double? h, double? ls, FontStyle? style}) =>
      GoogleFonts.poppins(fontSize: size, fontWeight: w, color: c, height: h, letterSpacing: ls, fontStyle: style);

  static TextStyle j(double size,
          {FontWeight w = FontWeight.w400, Color? c, double? h, double? ls, FontStyle? style}) =>
      GoogleFonts.plusJakartaSans(
          fontSize: size, fontWeight: w, color: c, height: h, letterSpacing: ls, fontStyle: style);

  static TextStyle serif(double size, {FontWeight w = FontWeight.w700, Color? c, double? h}) =>
      GoogleFonts.playfairDisplay(fontSize: size, fontWeight: w, color: c, height: h);
}

class AppTheme {
  static ThemeData build(bool dark) {
    final c = dark ? SFColors.dark : SFColors.light;
    final base = dark ? ThemeData.dark(useMaterial3: true) : ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: c.bg,
      colorScheme: base.colorScheme.copyWith(
        primary: c.primary,
        onPrimary: c.primaryText,
        surface: c.card,
        error: c.danger,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(bodyColor: c.text, displayColor: c.text),
      splashFactory: InkRipple.splashFactory,
      extensions: [c],
    );
  }
}
