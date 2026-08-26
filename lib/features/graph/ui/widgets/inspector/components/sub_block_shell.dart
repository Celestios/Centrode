import 'package:flutter/material.dart';
import 'package:centrode/shared/elements/elements.dart';

/// Collapsible sub-block container within a section shell.
class SubBlockShell extends StatefulWidget {
  final String title;
  final Widget child;
  final Color accentColor;
  final bool initiallyExpanded;

  const SubBlockShell({
    super.key,
    required this.title,
    required this.child,
    required this.accentColor,
    this.initiallyExpanded = false,
  });

  @override
  State<SubBlockShell> createState() => _SubBlockShellState();
}

class _SubBlockShellState extends State<SubBlockShell> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6.0),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.accentColor.withValues(alpha: 0.12),
          width: 0.6,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CentrodeButton(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(8),
            enableHover: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9.0,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: widget.accentColor.withValues(alpha: 0.95),
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 14,
                    color: widget.accentColor.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: widget.child,
            ),
        ],
      ),
    );
  }
}
