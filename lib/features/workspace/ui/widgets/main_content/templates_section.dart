import 'package:flutter/material.dart';
import '../shared/section_header.dart';
import '../shared/horizontal_scroll_row.dart';
import 'project_card.dart';

class TemplatesSection extends StatelessWidget {
  const TemplatesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'TEMPLATES'),
        HorizontalScrollRow(
          children: [
            ProjectCard(name: 'Template 1', lastOpened: 'Created 3 days ago'),
            ProjectCard(name: 'Template 2', lastOpened: 'Created 1 week ago'),
          ],
        ),
      ],
    );
  }
}
