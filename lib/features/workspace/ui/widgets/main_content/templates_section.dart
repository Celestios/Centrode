import 'package:flutter/material.dart';
import '../shared/section_header.dart';
import '../shared/horizontal_scroll_row.dart';
import 'empty_section_card.dart';

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
            EmptySectionCard(
              title: 'TEMPLATES',
              description: 'Save map snippets as templates for reuse.',
            ),
          ],
        ),
      ],
    );
  }
}
