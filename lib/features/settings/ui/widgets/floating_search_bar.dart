import 'package:flutter/material.dart';
import 'package:centrode/shared/theme/design_tokens.dart';
import 'package:centrode/shared/widgets/glass_panel/glass_panel.dart';
import '../../presentation/settings_controller.dart';

class SettingsTopControlsBar extends StatefulWidget {
  final SettingsController controller;

  const SettingsTopControlsBar({
    super.key,
    required this.controller,
  });

  @override
  State<SettingsTopControlsBar> createState() => _SettingsTopControlsBarState();
}

class _SettingsTopControlsBarState extends State<SettingsTopControlsBar> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _textController.text.isEmpty) {
        setState(() => _isExpanded = false);
      } else if (_focusNode.hasFocus) {
        setState(() => _isExpanded = true);
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Search bar: compact bar by default (130px), expands to 240px on activation
        GestureDetector(
          onTap: () {
            if (!_isExpanded) {
              setState(() => _isExpanded = true);
            }
            _focusNode.requestFocus();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: _isExpanded ? 240.0 : 130.0,
            height: 38.0,
            child: GlassPanel(
              borderRadius: UiRadius.pill,
              border: Border.all(
                color: _isExpanded
                    ? theme.colorScheme.primary.withValues(alpha: 0.5)
                    : Colors.transparent,
                width: 0.8,
              ),
              color: isDark
                  ? const Color(0xFF24242C).withValues(alpha: 0.92)
                  : Colors.white.withValues(alpha: 0.95),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      size: UiIconSize.standard,
                      color: _isExpanded
                          ? theme.colorScheme.primary
                          : theme.iconTheme.color?.withValues(alpha: 0.75),
                    ),
                    const SizedBox(width: UiSpacing.tight),
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        style: theme.textTheme.bodyMedium,
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          hintStyle: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.45),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: widget.controller.updateSearchQuery,
                      ),
                    ),
                    if (_textController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _textController.clear();
                          widget.controller.updateSearchQuery('');
                          setState(() {});
                        },
                        child: Icon(
                          Icons.close_rounded,
                          size: UiIconSize.dense,
                          color: theme.iconTheme.color?.withValues(alpha: 0.6),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Circular red close button at top-right
        const _CircularRedCloseButton(),
      ],
    );
  }
}

class _CircularRedCloseButton extends StatefulWidget {
  const _CircularRedCloseButton();

  @override
  State<_CircularRedCloseButton> createState() => _CircularRedCloseButtonState();
}

class _CircularRedCloseButtonState extends State<_CircularRedCloseButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => Navigator.of(context).maybePop(),
        child: AnimatedContainer(
          duration: UiMotion.fast,
          width: 34.0,
          height: 34.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isHovered ? const Color(0xFFFF5252) : const Color(0xFFE53935),
            boxShadow: [
              BoxShadow(
                color: (_isHovered ? const Color(0xFFFF5252) : const Color(0xFFE53935))
                    .withValues(alpha: 0.35),
                blurRadius: _isHovered ? 8.0 : 4.0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.close_rounded,
              size: 18.0,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
