import 'package:flutter/material.dart';
import '../theme/adrense_theme.dart';

/// Theme-aware, keyboard-accessible search control with a focus glow.
class AnimatedSearchField extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;
  const AnimatedSearchField({super.key, required this.controller,
    required this.onChanged, this.hintText = 'Search medicines...'});

  @override
  State<AnimatedSearchField> createState() => _AnimatedSearchFieldState();
}

class _AnimatedSearchFieldState extends State<AnimatedSearchField> {
  final FocusNode focus = FocusNode();
  bool focused = false;

  @override
  void initState() {
    super.initState();
    focus.addListener(_onFocus);
  }

  void _onFocus() {
    if (mounted) setState(() => focused = focus.hasFocus);
  }

  @override
  void dispose() {
    focus.removeListener(_onFocus);
    focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
        boxShadow: focused ? [BoxShadow(color: t.teal.withValues(alpha: .13),
          blurRadius: 20, spreadRadius: 1)] : const [],
      ),
      child: TextField(
        focusNode: focus,
        controller: widget.controller,
        onChanged: widget.onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.search_rounded, color: t.teal),
          hintText: widget.hintText,
          suffixIcon: widget.controller.text.isEmpty ? null : IconButton(
            tooltip: 'Clear search',
            icon: Icon(Icons.close_rounded, color: t.muted),
            onPressed: () {widget.controller.clear();widget.onChanged('');},
          ),
        ),
      ),
    );
  }
}
