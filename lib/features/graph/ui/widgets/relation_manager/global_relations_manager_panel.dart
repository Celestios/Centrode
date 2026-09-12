import 'package:flutter/material.dart';
import 'package:centrode/presentation/widgets/left_repository_panel.dart';
import 'relations_list_view.dart';

class GlobalRelationsManagerPanel extends StatelessWidget {
  const GlobalRelationsManagerPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return const LeftRepositoryPanel(
      title: 'LABELS',
      child: RelationsListView(),
    );
  }
}
