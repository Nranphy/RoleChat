import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const railWidth = 80.0;
  static const conversationWidth = 380.0;
  static const timelineWidth = 760.0;
  static const cornerRadius = 18.0;
  static const wideBreakpoint = 840.0;
  static const seeds = [
    Color(0xff5625ba),
    Color(0xff597b66),
    Color(0xff537ea0),
    Color(0xff8a6ba7),
    Color(0xffb47267),
    Color(0xffa2884d),
  ];
  static const seedNames = ['紫色', '森林', '海盐', '暮紫', '珊瑚', '麦田'];
  static ThemeData build(Color seed, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.rainbow,
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(cornerRadius / 2),
          borderSide: BorderSide(color: scheme.outline),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: scheme.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cornerRadius / 2),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cornerRadius),
        ),
      ),
      chipTheme: ChipThemeData(
        showCheckmark: false,
        backgroundColor: scheme.surfaceContainer,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cornerRadius),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: brightness == Brightness.dark
            ? scheme.surfaceContainerHighest
            : scheme.surfaceContainer,
        thickness: 1,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
