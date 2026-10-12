import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../onboarding_motion.dart';
import '../widgets/sheet_dots_painter.dart';
import '../widgets/twisted_word.dart';

const _blogUrl = 'https://blog.thekami.tech/posts/what-is-topsheet/'\;

/// First screen: dots gather into the Topsheet mark, then "Welcome to
/// Topsheet" tumbles in underneath. The (i) button opens the blog post.
class WelcomeStep extends StatefulWidget {
  const WelcomeStep({super.key});

  @override
  State<WelcomeStep> createState() => _WelcomeStepState();
}

class _WelcomeStepState extends State<WelcomeStep>
    with SingleTickerProviderStateMixin {
  static const _introLength = Duration(milliseconds: 5200);

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

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: RepaintBoundary(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: SheetDotsPainter(
                    progress: _intro,
                    primary: scheme.primary,
                    muted: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
              child: Semantics(
                label: 'Welcome to Topsheet',
                excludeSemantics: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TwistedWord(word: 'Welcome', style: base, progress: _intro),
                    TwistedWord(
                      word: 'to',
                      style: base,
                      progress: _intro,
                      firstIndex: 7,
                    ),
                    TwistedWord(
                      word: 'Topsheet',
                      style: brand,
                      progress: _intro,
                      firstIndex: 9,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        Positioned(
          top: 4,
          right: 8,
          child: IconButton(
            tooltip: 'What is Topsheet?',
            onPressed: _openBlog,
            icon: Icon(Icons.info_outline_rounded, color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
