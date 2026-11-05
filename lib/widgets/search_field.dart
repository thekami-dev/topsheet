import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// Material 3 search bar with a clear button. Shared by the onboarding
/// lists and the picker sheet.
class SearchField extends StatefulWidget {
  final String hint;
  final ValueChanged<String> onChanged;

  const SearchField({super.key, required this.hint, required this.onChanged});

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SearchBar(
      controller: _controller,
      hintText: widget.hint,
      elevation: const WidgetStatePropertyAll(0),
      textInputAction: TextInputAction.search,
      onChanged: widget.onChanged,
      leading: HugeIcon(icon: HugeIcons.strokeRoundedSearch01, size: 22),
      trailing: [
        if (_controller.text.isNotEmpty)
          IconButton(
            tooltip: 'Clear',
            icon: HugeIcon(icon: HugeIcons.strokeRoundedCancel01, size: 20),
            onPressed: () {
              _controller.clear();
              widget.onChanged('');
            },
          ),
      ],
    );
  }
}
