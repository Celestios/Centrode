import 'package:flutter/material.dart';
import 'recent_section.dart';
import 'projects_section.dart';
import 'templates_section.dart';

class MapsSection extends StatelessWidget {
  const MapsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        RecentSection(),
        ProjectsSection(),
        TemplatesSection(),
      ],
    );
  }
}
