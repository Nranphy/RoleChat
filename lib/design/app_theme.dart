import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const seeds = [
    Color(0xff597b66),
    Color(0xff537ea0),
    Color(0xff8a6ba7),
    Color(0xffb47267),
    Color(0xffa2884d),
  ];
  static const seedNames = ['森林', '海盐', '暮紫', '珊瑚', '麦田'];
  static ThemeData build(Color seed, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      popupMenuTheme: PopupMenuThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      fontFamily: 'RoleChatRoboto',
      textTheme: ThemeData(brightness: brightness).textTheme
          .copyWith(
            bodyMedium: const TextStyle(
              fontSize: 15,
              height: 1.5,
              letterSpacing: .1,
            ),
            bodyLarge: const TextStyle(
              fontSize: 16,
              height: 1.5,
              letterSpacing: .1,
            ),
          )
          .apply(
            fontFamily: 'RoleChatRoboto',
            fontFamilyFallback: const ['NotoSansSC', 'NotoColorEmoji'],
          ),
      fontFamilyFallback: const ['NotoSansSC', 'NotoColorEmoji'],
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      chipTheme: ChipThemeData(
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: .45),
        thickness: 1,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
