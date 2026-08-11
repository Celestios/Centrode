import 'package:flutter/material.dart';
import 'package:centrode/shared/widgets/glass_panel/glass_panel.dart';

class AnalyticsBox extends StatelessWidget {
  const AnalyticsBox({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: GlassPanel(
        height: 140,
        borderRadius: 12.0,
        enableBackdrop: false,
        child: SizedBox.expand(),
      ),
    );
  }
}
