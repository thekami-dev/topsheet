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
  // Start downloading institutes and departments right away, so the list is ready long before the user reaches the institute step.
  unawaited(RemoteDataService.instance.fetchInstitutes());
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
  await RemoteDataService.instance.ensureDepartments(waitForNetwork: false);
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

/// Builds a Material 3 [ColorScheme] for one palette.
///
/// fromSeed fills every M3 role (containers, inverse, error container...)
/// from the palette accent; then the palette's own neutrals replace the
/// surface/text/outline roles so each theme keeps its identity.
ColorScheme _schemeFor(PaletteColors p, Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final seeded = ColorScheme.fromSeed(
    seedColor: p.accent,
    brightness: brightness,
  );
  Color mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;
  return seeded.copyWith(
    surface: p.bg,
    onSurface: p.text,
    onSurfaceVariant: p.text2,
    surfaceDim: isDark ? p.bg : mix(p.surface2, p.border, 0.5),
    surfaceBright: isDark ? mix(p.surface2, p.border, 0.6) : p.bg,
    surfaceContainerLowest: p.bg,
    surfaceContainerLow: p.surface,
    surfaceContainer: mix(p.surface, p.surface2, 0.5),
    surfaceContainerHigh: p.surface2,
    surfaceContainerHighest: mix(p.surface2, p.border, 0.6),
    outline: mix(p.border, p.text2, 0.55),
    outlineVariant: p.border,
  );
}

ThemeData _buildTheme({required bool isDark, required PaletteColors p}) {
  final scheme = _schemeFor(p, isDark ? Brightness.dark : Brightness.light);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      scrolledUnderElevation: 0,
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    bottomSheetTheme: const BottomSheetThemeData(showDragHandle: true),
    splashFactory: InkSparkle.splashFactory,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
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
