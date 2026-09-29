import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'centrode_close_button.dart';
import '../theme/design_tokens.dart';
import 'surfaces/double_edge_surface.dart';
import 'surfaces/inset_surface.dart';

class CentrodeModalDialog extends StatelessWidget {
  final Widget? icon;
  final Widget? title;
  final Widget? content;
  final bool showInput;
  final TextEditingController? inputController;
  final String? inputPlaceholder;
  final ValueChanged<String>? onInputSubmitted;
  final List<Widget>? actions;
  final VoidCallback? onClose;
  final double width;
  final Color? accentColor;
  final Gradient? gradient;

  const CentrodeModalDialog({
    super.key,
    this.icon,
    this.title,
    this.content,
    this.showInput = false,
    this.inputController,
    this.inputPlaceholder,
    this.onInputSubmitted,
    this.actions,
    this.onClose,
    this.width = 440.0,
    this.accentColor,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = accentColor ?? theme.colorScheme.primary;

    final hasSingleAction = (actions != null && actions!.length == 1);
    final hasNoActions = (actions == null || actions!.isEmpty);
    final showTopCloseButton = !hasSingleAction;

    final resolvedCloseAction = CentrodeCloseButton(
      onTap: onClose ?? () => Navigator.of(context).maybePop(),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onClose ?? () => Navigator.of(context).maybePop(),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 18.0, sigmaY: 18.0),
                child: Container(
                  color: Colors.black.withValues(alpha: isDark ? 0.48 : 0.32),
                ),
              ),
            ),
          ),
          Center(
            child: Material(
              color: Colors.transparent,
              child: SizedBox(
                width: width,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showTopCloseButton) ...[
                      Align(
                        alignment: Alignment.topRight,
                        child: resolvedCloseAction,
                      ),
                      const SizedBox(height: 8.0),
                    ],
                    CentrodeDoubleEdgeSurface(
                      cornerRadius: 28.0,
                      gradient: gradient,
                      backgroundColor: isDark
                          ? const Color(0xFF131921).withValues(alpha: 0.88)
                          : Colors.white.withValues(alpha: 0.90),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.50 : 0.15),
                          blurRadius: 28.0,
                          offset: const Offset(0, 10),
                        ),
                        BoxShadow(
                          color: primaryColor.withValues(alpha: isDark ? 0.20 : 0.15),
                          blurRadius: 36.0,
                          offset: const Offset(0, 14),
                        ),
                      ],
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (icon != null || title != null)
                            Row(
                              children: [
                                if (icon != null) ...[
                                  Container(
                                    padding: const EdgeInsets.all(8.0),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withValues(alpha: isDark ? 0.25 : 0.12),
                                      borderRadius: BorderRadius.circular(UiRadius.control),
                                    ),
                                    child: IconTheme(
                                      data: IconThemeData(
                                        color: primaryColor,
                                        size: UiIconSize.standard,
                                      ),
                                      child: icon!,
                                    ),
                                  ),
                                  const SizedBox(width: 12.0),
                                ],
                                if (title != null)
                                  Expanded(
                                    child: DefaultTextStyle(
                                      style: TextStyle(
                                        fontSize: 17.0,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.2,
                                        color: isDark
                                            ? const Color(0xFFF1F5F9)
                                            : const Color(0xFF1E252B),
                                      ),
                                      child: title!,
                                    ),
                                  ),
                              ],
                            ),
                          if (content != null) ...[
                            if (icon != null || title != null)
                              const SizedBox(height: 14.0),
                            DefaultTextStyle(
                              style: TextStyle(
                                fontSize: 13.5,
                                height: 1.45,
                                color: isDark
                                    ? const Color(0xFFCBD5E1)
                                    : const Color(0xFF333E48),
                              ),
                              child: content!,
                            ),
                          ],
                          if (showInput) ...[
                            const SizedBox(height: 16.0),
                            CentrodeDebossedField(
                              controller: inputController,
                              hintText: inputPlaceholder ?? '',
                              accentColor: primaryColor,
                              onSubmitted: onInputSubmitted,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (!hasNoActions || hasSingleAction) ...[
                      const SizedBox(height: 14.0),
                      if (hasSingleAction)
                        Row(
                          children: [
                            resolvedCloseAction,
                            const SizedBox(width: 12.0),
                            Expanded(child: actions!.first),
                          ],
                        )
                      else
                        Row(
                          children: [
                            for (int i = 0; i < actions!.length; i++) ...[
                              if (i > 0) const SizedBox(width: 12.0),
                              Expanded(child: actions![i]),
                            ],
                          ],
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
