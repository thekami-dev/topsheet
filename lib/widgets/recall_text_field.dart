import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../core/motion.dart';
import '../data/recall_store.dart';

/// TextField that suggests previously-typed values for [field] as you type.
///
/// Uses [RawAutocomplete] bound to the caller-owned [controller], so there
/// is exactly one source of truth for the text.
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
        final reduced = motionTierOf(context) == MotionTier.reduced;
        final scheme = Theme.of(context).colorScheme;
        final list = Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220, maxWidth: 340),
            child: Material(
              elevation: 3,
              color: scheme.surfaceContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4),
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, i) {
                  final option = options.elementAt(i);
                  return ListTile(
                    dense: true,
                    leading: HugeIcon(
                      icon: HugeIcons.strokeRoundedHistory,
                      size: 18,
                    ),
                    title: Text(option),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
        if (reduced) return list;
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Motion.fast,
          curve: Motion.enter,
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
