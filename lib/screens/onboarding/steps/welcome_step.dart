import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../onboarding_motion.dart';
import '../widgets/reveal_line.dart';
import '../widgets/sheet_dots_painter.dart';

const _blogUrl = 'https://blog.thekami.tech/posts/what-is-topsheet/';

/// First screen: stars drift across the screen, then fly together into the
/// Topsheet mark, and "Welcome to Topsheet" appears beside it. The (i)
/// button opens the blog post.
class WelcomeStep extends StatefulWidget {
  const WelcomeStep({super.key});

  @override
  State<WelcomeStep> createState() => _WelcomeStepState();
}

class _WelcomeStepState extends State<WelcomeStep>
    with SingleTickerProviderStateMixin {
  static const _introLength = Duration(milliseconds: 6000);
  static const double _sideInset = 28;
  static const double _sheetWidth = 104;
  static const double _sheetHeight = _sheetWidth * 1.25;
  static const double _gap = 28;
  static const double _titleHeight = 162;

  late final AnimationController _intro = AnimationController(vsync: this);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final length = onbMotion(context, _introLength);
    if (length == Duration.zero) {
      _intro.value = 1;
    } else {
      _intro.duration = length;
      _intro.forward();
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  Future<void> _openBlog() async {
    var opened = false;
    try {
      opened = await launchUrl(
        Uri.parse(_blogUrl),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      opened = false;
    }
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't open the link.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = Theme.of(context).textTheme.displayMedium?.copyWith(
      fontSize: 46,
      height: 1.15,
      fontWeight: FontWeight.w400,
      color: scheme.onSurface,
    );
    final brand = base?.copyWith(
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.w800,
      color: scheme.primary,
    );

    return LayoutBuilder(
      builder: (context, box) {
        // Sheet + title sit together, centred vertically below the (i).
        const group = _sheetHeight + _gap + _titleHeight;
        final free = (box.maxHeight - group) / 2;
        final top = free < 56 ? 56.0 : free;
        final sheet = Rect.fromLTWH(_sideInset, top, _sheetWidth, _sheetHeight);

        return Stack(
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: SheetDotsPainter(
                    progress: _intro,
                    sheet: sheet,
                    primary: scheme.primary,
                    muted: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            Positioned(
              left: _sideInset,
              right: _sideInset,
              top: sheet.bottom + _gap,
              child: Semantics(
                label: 'Welcome to Topsheet',
                excludeSemantics: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RevealLine(
                      progress: _intro,
                      begin: 0.70,
                      end: 0.86,
                      child: Text('Welcome', style: base),
                    ),
                    RevealLine(
                      progress: _intro,
                      begin: 0.76,
                      end: 0.92,
                      child: Text('to', style: base),
                    ),
                    RevealLine(
                      progress: _intro,
                      begin: 0.82,
                      end: 1.0,
                      child: Text('Topsheet', style: brand),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 8,
              child: IconButton(
                tooltip: 'What is Topsheet?',
                onPressed: _openBlog,
                icon: Icon(
                  Icons.info_outline_rounded,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
