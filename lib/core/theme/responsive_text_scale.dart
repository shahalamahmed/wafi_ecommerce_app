import 'package:flutter/material.dart';

abstract final class ResponsiveTextScale {
  static const double compactBreakpoint = 400;
  static const double compactScale = 0.85;

  static double factorForWidth(double width) {
    return width < compactBreakpoint ? compactScale : 1;
  }

  static ThemeData apply(ThemeData baseTheme, double scaleFactor) {
    if (scaleFactor == 1) {
      return baseTheme;
    }

    return baseTheme.copyWith(
      textTheme: _scaleTextTheme(baseTheme.textTheme, scaleFactor),
      primaryTextTheme: _scaleTextTheme(baseTheme.primaryTextTheme, scaleFactor),
      appBarTheme: baseTheme.appBarTheme.copyWith(
        titleTextStyle: _scaleStyle(baseTheme.appBarTheme.titleTextStyle, scaleFactor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: baseTheme.elevatedButtonTheme.style?.copyWith(
          textStyle: WidgetStatePropertyAll(
            _scaleStyle(baseTheme.elevatedButtonTheme.style?.textStyle?.resolve({}), scaleFactor),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: baseTheme.outlinedButtonTheme.style?.copyWith(
          textStyle: WidgetStatePropertyAll(
            _scaleStyle(baseTheme.outlinedButtonTheme.style?.textStyle?.resolve({}), scaleFactor),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: baseTheme.textButtonTheme.style?.copyWith(
          textStyle: WidgetStatePropertyAll(
            _scaleStyle(baseTheme.textButtonTheme.style?.textStyle?.resolve({}), scaleFactor),
          ),
        ),
      ),
      inputDecorationTheme: baseTheme.inputDecorationTheme.copyWith(
        hintStyle: _scaleStyle(baseTheme.inputDecorationTheme.hintStyle, scaleFactor),
        labelStyle: _scaleStyle(baseTheme.inputDecorationTheme.labelStyle, scaleFactor),
        floatingLabelStyle: _scaleStyle(
          baseTheme.inputDecorationTheme.floatingLabelStyle,
          scaleFactor,
        ),
        errorStyle: _scaleStyle(baseTheme.inputDecorationTheme.errorStyle, scaleFactor),
      ),
      bottomNavigationBarTheme: baseTheme.bottomNavigationBarTheme.copyWith(
        selectedLabelStyle: _scaleStyle(
          baseTheme.bottomNavigationBarTheme.selectedLabelStyle,
          scaleFactor,
        ),
        unselectedLabelStyle: _scaleStyle(
          baseTheme.bottomNavigationBarTheme.unselectedLabelStyle,
          scaleFactor,
        ),
      ),
      chipTheme: baseTheme.chipTheme.copyWith(
        labelStyle: _scaleStyle(baseTheme.chipTheme.labelStyle, scaleFactor),
        secondaryLabelStyle: _scaleStyle(
          baseTheme.chipTheme.secondaryLabelStyle,
          scaleFactor,
        ),
      ),
      dialogTheme: baseTheme.dialogTheme.copyWith(
        titleTextStyle: _scaleStyle(baseTheme.dialogTheme.titleTextStyle, scaleFactor),
        contentTextStyle: _scaleStyle(baseTheme.dialogTheme.contentTextStyle, scaleFactor),
      ),
      snackBarTheme: baseTheme.snackBarTheme.copyWith(
        contentTextStyle: _scaleStyle(baseTheme.snackBarTheme.contentTextStyle, scaleFactor),
      ),
      listTileTheme: baseTheme.listTileTheme.copyWith(
        titleTextStyle: _scaleStyle(baseTheme.listTileTheme.titleTextStyle, scaleFactor),
        subtitleTextStyle: _scaleStyle(baseTheme.listTileTheme.subtitleTextStyle, scaleFactor),
      ),
      tabBarTheme: baseTheme.tabBarTheme.copyWith(
        labelStyle: _scaleStyle(baseTheme.tabBarTheme.labelStyle, scaleFactor),
        unselectedLabelStyle: _scaleStyle(
          baseTheme.tabBarTheme.unselectedLabelStyle,
          scaleFactor,
        ),
      ),
    );
  }

  static TextStyle? _scaleStyle(TextStyle? style, double scaleFactor) {
    final fontSize = style?.fontSize;
    if (style == null || fontSize == null) {
      return style;
    }

    return style.copyWith(fontSize: fontSize * scaleFactor);
  }

  static TextTheme _scaleTextTheme(TextTheme textTheme, double scaleFactor) {
    return textTheme.copyWith(
      displayLarge: _scaleStyle(textTheme.displayLarge, scaleFactor),
      displayMedium: _scaleStyle(textTheme.displayMedium, scaleFactor),
      displaySmall: _scaleStyle(textTheme.displaySmall, scaleFactor),
      headlineLarge: _scaleStyle(textTheme.headlineLarge, scaleFactor),
      headlineMedium: _scaleStyle(textTheme.headlineMedium, scaleFactor),
      headlineSmall: _scaleStyle(textTheme.headlineSmall, scaleFactor),
      titleLarge: _scaleStyle(textTheme.titleLarge, scaleFactor),
      titleMedium: _scaleStyle(textTheme.titleMedium, scaleFactor),
      titleSmall: _scaleStyle(textTheme.titleSmall, scaleFactor),
      bodyLarge: _scaleStyle(textTheme.bodyLarge, scaleFactor),
      bodyMedium: _scaleStyle(textTheme.bodyMedium, scaleFactor),
      bodySmall: _scaleStyle(textTheme.bodySmall, scaleFactor),
      labelLarge: _scaleStyle(textTheme.labelLarge, scaleFactor),
      labelMedium: _scaleStyle(textTheme.labelMedium, scaleFactor),
      labelSmall: _scaleStyle(textTheme.labelSmall, scaleFactor),
    );
  }
}
