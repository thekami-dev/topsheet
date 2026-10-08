import 'dart:async';

import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'core/app_themes.dart';
import 'core/motion.dart';
import 'core/theme_reveal.dart';
import 'data/recall_store.dart';
import 'services/remote_data_service.dart';
import 'screens/library_screen.dart';
import 'screens/onboarding_screen.dart';

/* Hallmark · genre: dark-premium · macrostructure: Workbench
 * design-system: design.md · designed-as-app
 */

/// Global, app-wide theme mode. SettingsScreen updates this; MaterialApp
/// listens via themeModeNotifier and cross-fades to the new theme.
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
  // Edge-to-edge: draw behind system bars, keep bars transparent.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
  ));
  await loadThemePalette();
  await loadThemePureBlack();
  // Departments come from the cloud (cached): load them before any screen needs them.
  await RemoteDataService.instance.ensureDepartments().timeout(
    const Duration(milliseconds: 1500),
    onTimeout: () => false,
  );
  // Warm the institute list so onboarding finds it ready.
  unawaited(RemoteDataService.instance.fetchInstitutes());
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

ThemeData _buildTheme({required bool isDark, required PaletteColors p}) {
  final c = p.bg;
  final surface = p.surface;
  final surface2 = p.surface2;
  final border = p.border;
  final text = p.text;
  final text2 = p.text2;
  final accent = p.accent;
  final error = p.error;

  final scheme =
      (isDark ? const ColorScheme.dark() : const ColorScheme.light()).copyWith(
        surface: c,
        onSurface: text,
        surfaceTint: Colors.transparent,
        surfaceContainerLowest: c,
        surfaceContainerLow: surface,
        surfaceContainer: surface,
        surfaceContainerHigh: surface2,
        surfaceContainerHighest: surface2,
        onSurfaceVariant: text2,
        outline: border,
        outlineVariant: border,
        primary: accent,
        onPrimary: p.onAccent,
        primaryContainer: surface2,
        onPrimaryContainer: text,
        secondary: p.accent2,
        secondaryContainer: Color.alphaBlend(
          accent.withValues(alpha: 0.22),
          surface2,
        ),
        onSecondaryContainer: text,
        tertiary: p.success,
        error: error,
        onError: Colors.white,
        shadow: Colors.black,
        inverseSurface: surface2,
        onInverseSurface: text,
      );

  // No fontFamily: uses the system font (Roboto on Android).
  final baseTextTheme =
      (isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme)
          .apply(bodyColor: text, displayColor: text);

  final textTheme = baseTextTheme.copyWith(
    displaySmall: baseTextTheme.displaySmall?.copyWith(
      fontWeight: FontWeight.w600,
    ),
    headlineSmall: baseTextTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.w600,
    ),
    titleLarge: baseTextTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
    titleMedium: baseTextTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
    ),
    bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: text2),
    labelLarge: baseTextTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    labelSmall: baseTextTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: 0.8,
      color: text2,
    ),
  );

  const stadium = StadiumBorder();
  OutlineInputBorder field(BorderSide side) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: side,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: text2,
      titleTextStyle: textTheme.bodyLarge?.copyWith(
        color: text,
        fontWeight: FontWeight.w600,
      ),
      subtitleTextStyle: textTheme.bodySmall?.copyWith(color: text2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface2,
      floatingLabelBehavior: FloatingLabelBehavior.never,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: textTheme.bodyMedium?.copyWith(color: text2),
      border: field(BorderSide.none),
      enabledBorder: field(BorderSide.none),
      disabledBorder: field(BorderSide.none),
      focusedBorder: field(BorderSide(color: accent, width: 2)),
      errorBorder: field(BorderSide(color: error, width: 1.5)),
      focusedErrorBorder: field(BorderSide(color: error, width: 2)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: p.onAccent,
        minimumSize: const Size(64, 52),
        shape: stadium,
        textStyle: textTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: text,
        side: BorderSide(color: border),
        minimumSize: const Size(64, 52),
        shape: stadium,
        textStyle: textTheme.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: p.accent2,
        shape: stadium,
        textStyle: textTheme.labelLarge,
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color?>(
          (st) => st.contains(WidgetState.selected)
              ? accent.withValues(alpha: 0.18)
              : Colors.transparent,
        ),
        foregroundColor: WidgetStateProperty.resolveWith<Color?>(
          (st) => st.contains(WidgetState.selected) ? p.accent2 : text2,
        ),
        side: WidgetStatePropertyAll(BorderSide(color: border)),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color?>(
        (st) => st.contains(WidgetState.selected) ? p.onAccent : text2,
      ),
      trackColor: WidgetStateProperty.resolveWith<Color?>(
        (st) => st.contains(WidgetState.selected) ? accent : surface2,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith<Color?>(
        (st) => st.contains(WidgetState.selected)
            ? Colors.transparent
            : border,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 0,
      highlightElevation: 0,
      backgroundColor: accent,
      foregroundColor: p.onAccent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: surface2,
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: text),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: text2.withValues(alpha: 0.4),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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

/// How long MaterialApp's own cross-fade takes (used for light/dark and
/// pure-black changes).
///
/// While a circular theme reveal is running it is zero, so the two effects
/// never overlap. The OS "reduce motion" flag switches the fade off, and
/// sustained jank (weak device) shortens it.
Duration _themeMorphDuration() {
  if (ThemeReveal.instance.running) return Duration.zero;
  final osReduced = WidgetsBinding
      .instance
      .platformDispatcher
      .accessibilityFeatures
      .disableAnimations;
  if (osReduced) return Duration.zero;
  return PerformanceMonitor.instance.tier.value == MotionTier.reduced
      ? Motion.fast
      : Motion.slow;
}

class TopsheetApp extends StatelessWidget {
  const TopsheetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        return ListenableBuilder(
          listenable: Listenable.merge([
            themePaletteNotifier,
            themePureBlackNotifier,
          ]),
          builder: (context, _) {
            final paletteId = themePaletteNotifier.value;
            final pureBlack = themePureBlackNotifier.value;
            final morph = _themeMorphDuration();
            return DynamicColorBuilder(
              builder: (lightDynamic, darkDynamic) {
                return MaterialApp(
                  title: 'Topsheet',
                  debugShowCheckedModeBanner: false,
                  themeMode: mode,
                  themeAnimationDuration: morph,
                  themeAnimationCurve: Motion.standardCurve,
                  theme: _buildTheme(
                    isDark: false,
                    p: resolvePalette(
                      paletteId,
                      false,
                      dynamicScheme: lightDynamic,
                    ),
                  ),
                  darkTheme: _buildTheme(
                    isDark: true,
                    p: resolvePalette(
                      paletteId,
                      true,
                      dynamicScheme: darkDynamic,
                      pureBlack: pureBlack,
                    ),
                  ),
                  builder: (context, child) {
                    final dark =
                        Theme.of(context).brightness == Brightness.dark;
                    final icons = dark ? Brightness.light : Brightness.dark;
                    return AnnotatedRegion<SystemUiOverlayStyle>(
                      value: SystemUiOverlayStyle(
                        statusBarColor: Colors.transparent,
                        systemNavigationBarColor: Colors.transparent,
                        systemNavigationBarDividerColor: Colors.transparent,
                        statusBarIconBrightness: icons,
                        systemNavigationBarIconBrightness: icons,
                      ),
                      child: ThemeRevealHost(child: child!),
                    );
                  },
                  home: const _StartupGate(),
                );
              },
            );
          },
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
