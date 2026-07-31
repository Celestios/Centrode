import 'package:flutter/material.dart';
import 'package:centrode/presentation/widgets/left_repository_panel.dart';
import 'templates_list_view.dart';

class GlobalTemplatesManagerPanel extends StatelessWidget {
  const GlobalTemplatesManagerPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return const LeftRepositoryPanel(
      title: 'TEMPLATES',
      child: TemplatesListView(),
    );
  }
}
