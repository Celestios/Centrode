import 'package:flutter/material.dart';
import '../shared/section_header.dart';
import '../shared/horizontal_scroll_row.dart';
import 'project_card.dart';

class RecentSection extends StatelessWidget {
  const RecentSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'RECENT'),
        HorizontalScrollRow(
          children: [
            ProjectCard(name: 'Map 1', lastOpened: '2 hours ago'),
            ProjectCard(name: 'Map 2', lastOpened: '1 day ago'),
            ProjectCard(name: 'Map 3', lastOpened: '3 days ago'),
            ProjectCard(name: 'Map 4', lastOpened: '1 week ago'),
            ProjectCard(name: 'Map 5', lastOpened: '2 weeks ago'),
          ],
        ),
      ],
    );
  }
}
