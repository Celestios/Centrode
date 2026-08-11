import 'package:flutter/material.dart';

class SubmenuButtonData {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;

  SubmenuButtonData({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });
}
