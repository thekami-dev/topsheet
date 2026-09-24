import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'data/recall_store.dart';
import 'screens/library_screen.dart';
import 'screens/onboarding_screen.dart';

/* Hallmark · genre: dark-premium · macrostructure: Workbench
 * design-system: design.md · designed-as-app
 */

/// Global, app-wide theme mode. SettingsScreen updates this; MaterialApp
/// listens via themeModeNotifier and rebuilds instantly.
final themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);

Future<void> applyThemeMode(String mode) async {
  themeModeNotifier.value = switch (mode) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
  await RecallStore.instance.setThemeMode(mode);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final saved = await RecallStore.instance.themeMode();
  themeModeNotifier.value = switch (saved) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
  runApp(const TopsheetApp());
}

// Fixed dark-premium palette.
class AppColors {
  static const bg = Color(0xFF0B0B0F);
  static const surface = Color(0xFF15161B);
  static const surface2 = Color(0xFF1B1C22);
  static const border = Color(0xFF26272E);
  static const text = Color(0xFFF2F2F5);
  static const text2 = Color(0xFF9A9AA5);
  static const accent = Color(0xFF6C5CE7);
  static const accent2 = Color(0xFF8A7CF0);
  static const success = Color(0xFF2ECC91);
  static const error = Color(0xFFFF5C5C);
}

// Light counterpart — same accent, inverted neutrals.
class AppColorsLight {
  static const bg = Color(0xFFFAFAFC);
  static const surface = Color(0xFFFFFFFF);
  static const surface2 = Color(0xFFF1F1F5);
  static const border = Color(0xFFE2E2E8);
  static const text = Color(0xFF16171C);
  static const text2 = Color(0xFF6B6C76);
  static const accent = Color(0xFF6C5CE7);
  static const accent2 = Color(0xFF5A4BD1);
  static const success = Color(0xFF1FA971);
  static const error = Color(0xFFE0393E);
}

ThemeData _buildTheme({required bool isDark}) {
  final c = isDark ? AppColors.bg : AppColorsLight.bg;
  final surface = isDark ? AppColors.surface : AppColorsLight.surface;
  final surface2 = isDark ? AppColors.surface2 : AppColorsLight.surface2;
  final border = isDark ? AppColors.border : AppColorsLight.border;
  final text = isDark ? AppColors.text : AppColorsLight.text;
  final text2 = isDark ? AppColors.text2 : AppColorsLight.text2;
  final accent = isDark ? AppColors.accent : AppColorsLight.accent;
  final error = isDark ? AppColors.error : AppColorsLight.error;

  final scheme =
      (isDark ? const ColorScheme.dark() : const ColorScheme.light()).copyWith(
        surface: c,
        onSurface: text,
        surfaceContainerHighest: surface2,
        onSurfaceVariant: text2,
        outline: border,
        outlineVariant: border,
        primary: accent,
        onPrimary: Colors.white,
        primaryContainer: surface2,
        onPrimaryContainer: text,
        secondary: isDark ? AppColors.accent2 : AppColorsLight.accent2,
        tertiary: isDark ? AppColors.success : AppColorsLight.success,
        error: error,
        onError: Colors.white,
        shadow: Colors.black,
        inverseSurface: surface2,
        onInverseSurface: text,
      );

  final baseTextTheme =
      (isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme)
          .apply(fontFamily: 'Inter', bodyColor: text, displayColor: text);

  final textTheme = baseTextTheme.copyWith(
    displaySmall: baseTextTheme.displaySmall?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.6,
      height: 1.06,
    ),
    headlineSmall: baseTextTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.45,
      height: 1.1,
    ),
    titleLarge: baseTextTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.22,
      height: 1.15,
    ),
    titleMedium: baseTextTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: -0.1,
    ),
    bodyLarge: baseTextTheme.bodyLarge?.copyWith(letterSpacing: 0, height: 1.42),
    bodyMedium: baseTextTheme.bodyMedium?.copyWith(
      letterSpacing: 0.05,
      height: 1.38,
      color: text2,
    ),
    labelLarge: baseTextTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: 0.08,
    ),
    labelSmall: baseTextTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: 0.34,
      color: text2,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: isDark ? Brightness.dark : Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: c,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: c,
      foregroundColor: text,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: textTheme.titleLarge,
    ),
    dividerColor: border,
    cardTheme: CardThemeData(
      elevation: 0,
      color: surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: border),
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: text2,
      titleTextStyle: textTheme.bodyLarge?.copyWith(
        color: text,
        fontWeight: FontWeight.w600,
      ),
      subtitleTextStyle: textTheme.bodySmall?.copyWith(color: text2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface2,
      floatingLabelBehavior: FloatingLabelBehavior.never,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      hintStyle: textTheme.bodyMedium?.copyWith(color: text2),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: border),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: border.withValues(alpha: 0.6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: accent, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: error, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: error, width: 1.6),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 0,
      highlightElevation: 0,
      backgroundColor: accent,
      foregroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: surface2,
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: text),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: border),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surface,
      showDragHandle: true,
      dragHandleColor: border,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    splashFactory: InkSparkle.splashFactory,
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}

class TopsheetApp extends StatelessWidget {
  const TopsheetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Topsheet',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: _buildTheme(isDark: false),
          darkTheme: _buildTheme(isDark: true),
          home: const _StartupGate(),
        );
      },
    );
  }
}


/// Decides between the onboarding flow and the library screen based on
/// whether the user has completed first-run setup — checked once at
/// startup so we don't flash the wrong screen.
class _StartupGate extends StatelessWidget {
  const _StartupGate();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: RecallStore.instance.onboardingComplete(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return snapshot.data! ? const LibraryScreen() : const OnboardingScreen();
      },
    );
  }
}
