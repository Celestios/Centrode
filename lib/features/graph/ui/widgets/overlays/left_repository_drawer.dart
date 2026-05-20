import 'dart:ui';
import 'package:flutter/material.dart';

class LeftRepositoryDrawer extends StatefulWidget {
  const LeftRepositoryDrawer({super.key});

  @override
  State<LeftRepositoryDrawer> createState() => _LeftRepositoryDrawerState();
}

class _LeftRepositoryDrawerState extends State<LeftRepositoryDrawer> {
  bool _isMinimized = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    final textColor = theme.textTheme.bodyMedium?.color ?? onSurface;

    final borderRadiusVal = theme.cardTheme.shape is RoundedRectangleBorder
        ? (theme.cardTheme.shape as RoundedRectangleBorder).borderRadius
        : BorderRadius.circular(16);

    return ClipRRect(
      borderRadius: borderRadiusVal,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          width: _isMinimized ? 52 : 220,
          decoration: BoxDecoration(
            color: theme.cardColor.withValues(alpha: 0.85),
            borderRadius: borderRadiusVal,
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.3),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(3, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                child: SizedBox(
                  height: 32,
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      AnimatedOpacity(
                        opacity: _isMinimized ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 150),
                        child: Text(
                          'REPOSITORY',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            _isMinimized
                                ? Icons.keyboard_double_arrow_right_rounded
                                : Icons.keyboard_double_arrow_left_rounded,
                            color: textColor.withValues(alpha: 0.7),
                            size: 18,
                          ),
                          onPressed: () {
                            setState(() {
                              _isMinimized = !_isMinimized;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.3)),

              // Placeholder Empty State
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _isMinimized
                        ? Icon(
                            Icons.folder_off_outlined,
                            color: textColor.withValues(alpha: 0.4),
                            size: 20,
                          )
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const NeverScrollableScrollPhysics(),
                            child: SizedBox(
                              width: 188,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.folder_off_outlined,
                                    color: textColor.withValues(alpha: 0.3),
                                    size: 36,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No templates loaded',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textColor.withValues(alpha: 0.5),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
