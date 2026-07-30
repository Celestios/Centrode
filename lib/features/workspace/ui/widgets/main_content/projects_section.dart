import 'package:flutter/material.dart';
import '../shared/section_header.dart';
import '../shared/horizontal_scroll_row.dart';
import 'project_card.dart';

class ProjectsSection extends StatelessWidget {
  const ProjectsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'PROJECTS'),
        HorizontalScrollRow(
          children: [
            ProjectCard(name: 'Project 1', lastOpened: '5 days ago'),
            ProjectCard(name: 'Project 2', lastOpened: '1 week ago'),
            ProjectCard(name: 'Project 3', lastOpened: '2 weeks ago'),
          ],
        ),
      ],
    );
  }
}
