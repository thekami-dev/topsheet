import 'package:flutter/material.dart';

import '../core/motion.dart';
import '../data/recall_store.dart';

/* Hallmark · genre: modern-minimal · macrostructure: Workbench
 * design-system: design.md · designed-as-app
 */

/// TextField that suggests previously-typed values for [field] as you type.
///
/// Uses [RawAutocomplete] bound to the caller-owned [controller], so there
/// is exactly one source of truth for the text — no cross-controller
/// listener plumbing, no per-rebuild resyncing.
class RecallTextField extends StatefulWidget {
  final String field;
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? errorText;
  final ValueChanged<String>? onSelected;

  const RecallTextField({
    super.key,
    required this.field,
    required this.label,
    required this.controller,
    this.keyboardType,
    this.errorText,
    this.onSelected,
  });

  @override
  State<RecallTextField> createState() => _RecallTextFieldState();
}

class _RecallTextFieldState extends State<RecallTextField> {
  List<String> _options = [];
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    RecallStore.instance.suggestionsFor(widget.field).then((v) {
      if (mounted) setState(() => _options = v);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      textEditingController: widget.controller,
      focusNode: _focusNode,
      optionsBuilder: (value) {
        if (value.text.isEmpty) return _options;
        return _options.where(
          (o) => o.toLowerCase().contains(value.text.toLowerCase()),
        );
      },
      onSelected: widget.onSelected,
      optionsViewBuilder: (context, onSelected, options) {
        final tier = motionTierOf(context);
        final scheme = Theme.of(context).colorScheme;
        final list = Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220, maxWidth: 340),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scheme.outlineVariant),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, i) {
                    final option = options.elementAt(i);
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.history_rounded, size: 18),
                      title: Text(option),
                      onTap: () => onSelected(option),
                    );
                  },
                ),
              ),
            ),
          ),
        );
        // Suggestions arrive as a material surface, anchored top-left under
        // the field — scale it in from that origin instead of a flat fade.
        if (tier == MotionTier.reduced) return list;
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Motion.fast,
          curve: Curves.easeOutCubic,
          builder: (context, t, child) => Opacity(
            opacity: t,
            child: Transform.scale(
              scale: 0.92 + 0.08 * t,
              alignment: Alignment.topLeft,
              child: child,
            ),
          ),
          child: list,
        );
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        // controller/focusNode are the very instances passed above.
        assert(identical(controller, widget.controller));
        return TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: widget.keyboardType,
          decoration: InputDecoration(
            hintText: widget.label,
            errorText: widget.errorText,
          ),
        );
      },
    );
  }
}
