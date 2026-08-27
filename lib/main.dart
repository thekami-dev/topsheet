import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

/* Hallmark · genre: modern-minimal · macrostructure: Workbench
 * design-system: design.md · designed-as-app
 */

void main() => runApp(const TopsheetApp());

/// Fallback seed used when dynamic platform colors are unavailable.
const _fallbackSeed = Color(0xFF127A6C);

class TopsheetApp extends StatelessWidget {
  const TopsheetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final lightScheme =
            lightDynamic?.harmonized() ??
            ColorScheme.fromSeed(seedColor: _fallbackSeed);
        final darkScheme =
            darkDynamic?.harmonized() ??
            ColorScheme.fromSeed(
              seedColor: _fallbackSeed,
              brightness: Brightness.dark,
            );

        ThemeData buildTheme(ColorScheme scheme, {required bool isDark}) {
          final base =
              (isDark ? Typography.whiteCupertino : Typography.blackCupertino)
                  .copyWith()
                  .apply(
                    bodyColor: scheme.onSurface,
                    displayColor: scheme.onSurface,
                  );

          final textTheme = base.copyWith(
            displaySmall: base.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.55,
              height: 1.06,
            ),
            headlineSmall: base.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.45,
              height: 1.1,
            ),
            titleLarge: base.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.22,
              height: 1.15,
            ),
            titleMedium: base.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
            ),
            bodyLarge: base.bodyLarge?.copyWith(letterSpacing: 0, height: 1.42),
            bodyMedium: base.bodyMedium?.copyWith(
              letterSpacing: 0.05,
              height: 1.38,
            ),
            labelLarge: base.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.08,
            ),
            labelSmall: base.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.34,
            ),
          );

          return ThemeData(
            useMaterial3: true,
            colorScheme: scheme,
            scaffoldBackgroundColor: Colors.transparent,
            textTheme: textTheme,
            appBarTheme: AppBarTheme(
              centerTitle: false,
              backgroundColor: Colors.transparent,
              foregroundColor: scheme.onSurface,
              elevation: 0,
              scrolledUnderElevation: 0,
              surfaceTintColor: Colors.transparent,
              titleTextStyle: textTheme.titleLarge,
            ),
            dividerColor: scheme.outlineVariant.withValues(alpha: 0.24),
            cardTheme: CardThemeData(
              elevation: 0,
              color: scheme.surface.withValues(alpha: isDark ? 0.34 : 0.72),
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                  color: scheme.outlineVariant.withValues(alpha: 0.35),
                ),
              ),
            ),
            listTileTheme: ListTileThemeData(
              iconColor: scheme.onSurfaceVariant,
              titleTextStyle: textTheme.bodyLarge?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              subtitleTextStyle: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: scheme.surfaceContainerHighest.withValues(
                alpha: isDark ? 0.34 : 0.55,
              ),
              floatingLabelBehavior: FloatingLabelBehavior.never,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
              hintStyle: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: scheme.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: scheme.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: scheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: scheme.primary, width: 1.6),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: scheme.error, width: 1.2),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: scheme.error, width: 1.6),
              ),
            ),
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              elevation: 0,
              highlightElevation: 0,
              extendedTextStyle: textTheme.labelLarge,
              extendedPadding: const EdgeInsets.symmetric(horizontal: 20),
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            snackBarTheme: SnackBarThemeData(
              behavior: SnackBarBehavior.floating,
              backgroundColor: scheme.inverseSurface,
              contentTextStyle: textTheme.bodyMedium?.copyWith(
                color: scheme.onInverseSurface,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            bottomSheetTheme: BottomSheetThemeData(
              backgroundColor: scheme.surface.withValues(
                alpha: isDark ? 0.92 : 0.96,
              ),
              showDragHandle: true,
              dragHandleColor: scheme.outlineVariant,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
            ),
            splashFactory: InkSparkle.splashFactory,
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              },
            ),
          );
        }

        return MaterialApp(
          title: 'Topsheet',
          debugShowCheckedModeBanner: false,
          themeMode: ThemeMode.system,
          theme: buildTheme(lightScheme, isDark: false),
          darkTheme: buildTheme(darkScheme, isDark: true),
          home: const HomeScreen(),
        );
      },
    );
  }
}
