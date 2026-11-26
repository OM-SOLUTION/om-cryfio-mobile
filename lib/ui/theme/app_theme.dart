import 'package:flutter/material.dart';

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
}

/// Colors for states that Material's [ColorScheme] has no role for.
@immutable
class StatusColors extends ThemeExtension<StatusColors> {
  const StatusColors({
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warningContainer,
    required this.onWarningContainer,
  });

  final Color successContainer;
  final Color onSuccessContainer;
  final Color warningContainer;
  final Color onWarningContainer;

  static const light = StatusColors(
    successContainer: Color(0xFFD7F0DC),
    onSuccessContainer: Color(0xFF0B3D1A),
    warningContainer: Color(0xFFFFE9B8),
    onWarningContainer: Color(0xFF4A3500),
  );

  static const dark = StatusColors(
    successContainer: Color(0xFF1F4D2B),
    onSuccessContainer: Color(0xFFC8F0D0),
    warningContainer: Color(0xFF5A4300),
    onWarningContainer: Color(0xFFFFE3A3),
  );

  @override
  StatusColors copyWith({
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warningContainer,
    Color? onWarningContainer,
  }) {
    return StatusColors(
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
    );
  }

  @override
  StatusColors lerp(ThemeExtension<StatusColors>? other, double t) {
    if (other is! StatusColors) return this;
    return StatusColors(
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      onSuccessContainer: Color.lerp(
        onSuccessContainer,
        other.onSuccessContainer,
        t,
      )!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      onWarningContainer: Color.lerp(
        onWarningContainer,
        other.onWarningContainer,
        t,
      )!,
    );
  }
}

/// Colors of `Folder`. Both themes use the same blue folder for now.
@immutable
class FolderColors extends ThemeExtension<FolderColors> {
  const FolderColors({
    required this.backTop,
    required this.backBottom,
    required this.page,
    required this.pageShade,
    required this.cover,
  });

  /// Builds a whole palette from one color, the folder's main blue. The back
  /// panel fades to a deeper shade of it and the page shading sits in between.
  factory FolderColors.fromBase(Color base) {
    final hsv = HSVColor.fromColor(base);
    final deep = hsv
        .withHue((hsv.hue + 23) % 360)
        .withSaturation(hsv.saturation * 0.95)
        .withValue(hsv.value * 0.71)
        .toColor();

    return FolderColors(
      backTop: base,
      backBottom: deep,
      page: Colors.white,
      pageShade: Color.lerp(base, deep, 0.25)!,
      cover: base,
    );
  }

  /// Top of the back panel's gradient, and the folder's main color.
  final Color backTop;

  /// Bottom of the back panel's gradient.
  final Color backBottom;
  final Color page;

  /// The curled edge shading on the front page.
  final Color pageShade;

  /// The front cover, solid at the bottom and half see-through at the top.
  final Color cover;

  static const standard = FolderColors(
    backTop: Color(0xFF3592E9),
    backBottom: Color(0xFF2D3FA5),
    page: Color(0xFFFFFFFF),
    pageShade: Color(0xFF337BD7),
    cover: Color(0xFF3592E9),
  );

  @override
  FolderColors copyWith({
    Color? backTop,
    Color? backBottom,
    Color? page,
    Color? pageShade,
    Color? cover,
  }) {
    return FolderColors(
      backTop: backTop ?? this.backTop,
      backBottom: backBottom ?? this.backBottom,
      page: page ?? this.page,
      pageShade: pageShade ?? this.pageShade,
      cover: cover ?? this.cover,
    );
  }

  @override
  FolderColors lerp(ThemeExtension<FolderColors>? other, double t) {
    if (other is! FolderColors) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return FolderColors(
      backTop: mix(backTop, other.backTop),
      backBottom: mix(backBottom, other.backBottom),
      page: mix(page, other.page),
      pageShade: mix(pageShade, other.pageShade),
      cover: mix(cover, other.cover),
    );
  }
}

/// The single place where the app's look is defined. Every value here is a
/// placeholder until the visual direction is decided.
abstract final class AppTheme {
  static const seedColor = Color(0xFF5B4BB7);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    );
    // Buttons keep a 48 dp touch target.
    const minimumSize = Size(64, 48);

    return ThemeData(
      colorScheme: scheme,
      extensions: [
        brightness == Brightness.light ? StatusColors.light : StatusColors.dark,
        FolderColors.standard,
      ],
      appBarTheme: AppBarTheme(
        centerTitle: false,
        scrolledUnderElevation: 0,
        // Set explicitly: otherwise Material switches the bar to a darker
        // color (surfaceContainer) as soon as the page scrolls under it.
        backgroundColor: scheme.surface,
      ),
      // The bottom bar is the same color as the pages above it.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: minimumSize, shape: shape),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(minimumSize: minimumSize, shape: shape),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: minimumSize, shape: shape),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
