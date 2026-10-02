import 'package:centrode/shared/theme/design_tokens.dart';
import 'package:flutter/material.dart';

class HorizontalScrollRow extends StatelessWidget {
  final List<Widget> children;

  const HorizontalScrollRow({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: WorkspaceTokens.cardHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: UiInsets.horizontalGutter,
        itemCount: children.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: WorkspaceTokens.cardSpacing),
            child: SizedBox(
              width: WorkspaceTokens.cardWidth,
              child: children[index],
            ),
          );
        },
      ),
    );
  }
}
