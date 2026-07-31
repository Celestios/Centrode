import 'package:flutter/material.dart';
import 'package:centrode/presentation/widgets/left_repository_panel.dart';
import 'tags_list_view.dart';

class GlobalTagsManagerPanel extends StatelessWidget {
  const GlobalTagsManagerPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return const LeftRepositoryPanel(
      title: 'GLOBAL TAGS',
      child: TagsListView(),
    );
  }
}
