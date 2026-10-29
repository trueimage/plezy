import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';

import '../focus/focusable_chip_mixin.dart';
import '../focus/input_mode_tracker.dart';
import '../theme/mono_tokens.dart';
import '../theme/plezy_layout.dart';
import 'focus_builders.dart';
import 'nocturne/nocturne_spotlight.dart' show NocturneMetrics;

/// A focusable filter chip that shows a color change when focused.
///
/// Unlike FocusableWrapper which uses scale + border, this widget
/// uses a background color change to indicate focus state.
class FocusableFilterChip extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  /// A count drawn after the label in the accent colour (Nocturne), or in
  /// parentheses elsewhere.
  final int? count;

  /// Optional external focus node for programmatic focus control.
  final FocusNode? focusNode;

  /// Called when the user presses DOWN from this chip.
  final VoidCallback? onNavigateDown;

  /// Called when the user presses UP from this chip.
  final VoidCallback? onNavigateUp;

  /// Called when the user presses LEFT from this chip.
  final VoidCallback? onNavigateLeft;

  /// Called when the user presses RIGHT from this chip.
  final VoidCallback? onNavigateRight;

  /// Called when the user presses BACK from this chip.
  final VoidCallback? onBack;

  const FocusableFilterChip({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.count,
    this.focusNode,
    this.onNavigateDown,
    this.onNavigateUp,
    this.onNavigateLeft,
    this.onNavigateRight,
    this.onBack,
  });

  @override
  State<FocusableFilterChip> createState() => _FocusableFilterChipState();
}

class _FocusableFilterChipState extends State<FocusableFilterChip> with FocusableChipStateMixin<FocusableFilterChip> {
  @override
  FocusNode? get widgetFocusNode => widget.focusNode;

  @override
  String get debugLabel => 'filter_chip_${widget.label}';

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    return handleChipKeyEvent(
      node,
      event,
      ChipKeyCallbacks(
        onSelect: widget.onPressed,
        onNavigateDown: widget.onNavigateDown,
        onNavigateUp: widget.onNavigateUp,
        onNavigateLeft: widget.onNavigateLeft,
        onNavigateRight: widget.onNavigateRight,
        onBack: widget.onBack,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (PlezyLayout.isNocturne(context)) return _buildNocturne(context);
    final colorScheme = Theme.of(context).colorScheme;
    // Only show focus effects during keyboard/d-pad navigation
    final showFocus = isFocused && InputModeTracker.isKeyboardMode(context);

    // Use primary color when focused, surface color when not
    final backgroundColor = showFocus ? colorScheme.primary : colorScheme.surfaceContainerHighest;
    final foregroundColor = showFocus ? colorScheme.onPrimary : colorScheme.onSurfaceVariant;
    final label = widget.count == null ? widget.label : '${widget.label} (${widget.count})';

    return FocusBuilders.buildFocusableChip(
      context: context,
      focusNode: focusNode,
      onKeyEvent: _handleKeyEvent,
      onTap: widget.onPressed,
      semanticLabel: label,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      backgroundColor: backgroundColor,
      child: Row(
        mainAxisSize: .min,
        children: [
          AppIcon(icon, fill: 1, size: 16, color: foregroundColor),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: foregroundColor)),
        ],
      ),
    );
  }

  /// Nocturne: an outlined pill that inverts when focused, its count in the
  /// accent colour.
  Widget _buildNocturne(BuildContext context) {
    final tk = tokens(context);
    final m = NocturneMetrics.of(context);
    final showFocus = isFocused && InputModeTracker.isKeyboardMode(context);
    final foreground = showFocus ? tk.bg : tk.text;
    final fontSize = m.pick(tv: 22, desktop: 13, phone: 13);
    final count = widget.count;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: showFocus ? tk.text : tk.outline),
      ),
      child: FocusBuilders.buildFocusableChip(
        context: context,
        focusNode: focusNode,
        onKeyEvent: _handleKeyEvent,
        onTap: widget.onPressed,
        semanticLabel: count == null ? widget.label : '${widget.label} ($count)',
        padding: EdgeInsets.symmetric(horizontal: m.pick(tv: 22, desktop: 14, phone: 12)),
        backgroundColor: showFocus ? tk.text : Colors.transparent,
        child: Row(
          mainAxisSize: .min,
          children: [
            AppIcon(icon, fill: 1, size: fontSize, color: foreground),
            SizedBox(width: m.pick(tv: 10, desktop: 6, phone: 6)),
            Text(
              widget.label,
              style: TextStyle(color: foreground, fontSize: fontSize, fontWeight: FontWeight.w600, height: 1.2),
            ),
            if (count != null) ...[
              SizedBox(width: m.pick(tv: 10, desktop: 6, phone: 6)),
              Text(
                '$count',
                style: TextStyle(
                  color: showFocus ? tk.bg : tk.accent,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData get icon => widget.icon;
}
