import 'package:flutter/material.dart';

import '../utils/scroll_utils.dart';
import 'focus_theme.dart';
import 'focus_tokens.dart';
import 'input_mode_tracker.dart';
import 'owned_focus_node_binding.dart';

/// Manages the internal/external FocusNode lifecycle for list-tile widgets and
/// auto-scrolls the tile into view when it gains focus.
mixin FocusableTileStateMixin<T extends StatefulWidget> on State<T> {
  final _focusNodeBinding = OwnedFocusNodeBinding();
  FocusNode? _boundExternalNode;

  FocusNode? get widgetFocusNode;

  FocusNode get effectiveFocusNode => _focusNodeBinding.node;

  @override
  void initState() {
    super.initState();
    _bindFocusNode();
  }

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_boundExternalNode != widgetFocusNode) {
      _bindFocusNode();
    }
  }

  @override
  void dispose() {
    _focusNodeBinding.dispose();
    super.dispose();
  }

  void _bindFocusNode() {
    _boundExternalNode = widgetFocusNode;
    _focusNodeBinding.bind(externalNode: widgetFocusNode, listener: _onFocusChange);
  }

  bool _inverted = false;

  /// [tile] drawn the way the theme shows a focused list row. With
  /// [FocusListStyle.inverted] a D-pad-focused row turns into a light fill
  /// with dark text, on every focus tier; the fill style is the tile's own
  /// focus highlight and passes [tile] through untouched.
  Widget buildListFocus(BuildContext context, Widget tile) {
    if (FocusTheme.of(context).listStyle != FocusListStyle.inverted) return tile;
    final focused = effectiveFocusNode.hasFocus && InputModeTracker.isKeyboardMode(context);
    if (!focused) return tile;
    final scheme = Theme.of(context).colorScheme;
    return Theme(
      data: Theme.of(context).copyWith(focusColor: scheme.onSurface),
      child: ListTileTheme.merge(
        textColor: scheme.surface,
        iconColor: scheme.surface,
        selectedColor: scheme.surface,
        child: DefaultTextStyle.merge(
          style: TextStyle(color: scheme.surface),
          child: tile,
        ),
      ),
    );
  }

  void _onFocusChange() {
    final inverted = effectiveFocusNode.hasFocus && FocusTheme.of(context).listStyle == FocusListStyle.inverted;
    if (inverted != _inverted && mounted) setState(() => _inverted = inverted);
    // Reveal on focus is keyboard/D-pad-only: pointer-mode focus is
    // programmatic and invisible, so revealing it would yank the scroll view
    // (issue #2031).
    if (effectiveFocusNode.hasFocus && InputModeTracker.currentMode == InputMode.keyboard) {
      scrollContextToCenter(context);
    }
  }
}
