import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mycelium/features/graph/ui/widgets/overlays/vertical_text_format_toolbar.dart';

void main() {
  testWidgets('VerticalTextFormatToolbar renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: VerticalTextFormatToolbar(
              onToggleBold: () {},
              onToggleItalic: () {},
              onToggleUnderline: () {},
              onToggleHeader1: () {},
              onToggleHeader2: () {},
              onToggleHeader3: () {},
              onToggleBlockquote: () {},
              onToggleCodeBlock: () {},
              onToggleBulletList: () {},
              onToggleOrderedList: () {},
              onClearBlockFormat: () {},
              onAddHyperlink: () {},
              onSelectFontFamily: (_) {},
              onCycleTextColor: () {},
              onToggleHighlight: () {},
              onCycleHighlightColor: () {},
              onCycleTextAlign: () {},
              onIncreaseFontSize: () {},
              onDecreaseFontSize: () {},
              dragHandle: const SizedBox(width: 32, height: 32),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(VerticalTextFormatToolbar), findsOneWidget);
  });
}
