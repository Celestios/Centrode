import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:centrode/features/graph/ui/widgets/overlays/vertical_text_format_toolbar.dart';

void main() {
  testWidgets('VerticalTextFormatToolbar renders without crashing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: VerticalTextFormatToolbar(
              onToggleHeader1: () {},
              onToggleHeader2: () {},
              onToggleHeader3: () {},
              onToggleBlockquote: () {},
              onToggleCodeBlock: () {},
              onToggleBulletList: () {},
              onToggleOrderedList: () {},
              onClearBlockFormat: () {},
              onAddHyperlink: () {},
              dragHandle: const SizedBox(width: 32, height: 32),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(VerticalTextFormatToolbar), findsOneWidget);
  });

  testWidgets('Heading button cycles through H1, H2, H3, and normal', (
    WidgetTester tester,
  ) async {
    int h1Count = 0;
    int h2Count = 0;
    int h3Count = 0;
    int clearCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: VerticalTextFormatToolbar(
              onToggleHeader1: () => h1Count++,
              onToggleHeader2: () => h2Count++,
              onToggleHeader3: () => h3Count++,
              onToggleBlockquote: () {},
              onToggleCodeBlock: () {},
              onToggleBulletList: () {},
              onToggleOrderedList: () {},
              onClearBlockFormat: () => clearCount++,
              onAddHyperlink: () {},
            ),
          ),
        ),
      ),
    );

    // Initial state: Title icon
    final headingFinder = find.byIcon(Icons.title_rounded);
    expect(headingFinder, findsOneWidget);

    // Tap 1 -> H1
    await tester.tap(headingFinder);
    await tester.pump();
    expect(h1Count, 1);
    expect(find.byIcon(Icons.looks_one_rounded), findsOneWidget);

    // Tap 2 -> H2
    await tester.tap(find.byIcon(Icons.looks_one_rounded));
    await tester.pump();
    expect(h2Count, 1);
    expect(find.byIcon(Icons.looks_two_rounded), findsOneWidget);

    // Tap 3 -> H3
    await tester.tap(find.byIcon(Icons.looks_two_rounded));
    await tester.pump();
    expect(h3Count, 1);
    expect(find.byIcon(Icons.looks_3_rounded), findsOneWidget);

    // Tap 4 -> Clear / Normal
    await tester.tap(find.byIcon(Icons.looks_3_rounded));
    await tester.pump();
    expect(clearCount, 1);
    expect(find.byIcon(Icons.title_rounded), findsOneWidget);
  });

  testWidgets('List button cycles through Bullet, Numbered, and clear', (
    WidgetTester tester,
  ) async {
    int bulletCount = 0;
    int orderedCount = 0;
    int clearCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: VerticalTextFormatToolbar(
              onToggleHeader1: () {},
              onToggleHeader2: () {},
              onToggleHeader3: () {},
              onToggleBlockquote: () {},
              onToggleCodeBlock: () {},
              onToggleBulletList: () => bulletCount++,
              onToggleOrderedList: () => orderedCount++,
              onClearBlockFormat: () => clearCount++,
              onAddHyperlink: () {},
            ),
          ),
        ),
      ),
    );

    final listFinder = find.byIcon(Icons.format_list_bulleted_rounded);
    expect(listFinder, findsOneWidget);

    // Tap 1 -> Bullet
    await tester.tap(listFinder);
    await tester.pump();
    expect(bulletCount, 1);

    // Tap 2 -> Numbered
    await tester.tap(listFinder);
    await tester.pump();
    expect(orderedCount, 1);
    expect(find.byIcon(Icons.format_list_numbered_rounded), findsOneWidget);

    // Tap 3 -> Clear
    await tester.tap(find.byIcon(Icons.format_list_numbered_rounded));
    await tester.pump();
    expect(clearCount, 1);
  });

  testWidgets('Blockquote, Code block, and Hyperlink trigger callbacks', (
    WidgetTester tester,
  ) async {
    int blockquoteCount = 0;
    int codeBlockCount = 0;
    int linkCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: VerticalTextFormatToolbar(
              onToggleHeader1: () {},
              onToggleHeader2: () {},
              onToggleHeader3: () {},
              onToggleBlockquote: () => blockquoteCount++,
              onToggleCodeBlock: () => codeBlockCount++,
              onToggleBulletList: () {},
              onToggleOrderedList: () {},
              onClearBlockFormat: () {},
              onAddHyperlink: () => linkCount++,
              dragHandle: const KeyedSubtree(
                key: ValueKey('test_drag_handle'),
                child: SizedBox(width: 24, height: 24),
              ),
            ),
          ),
        ),
      ),
    );

    // Verify drag handle rendered
    expect(find.byKey(const ValueKey('test_drag_handle')), findsOneWidget);

    // Tap Blockquote
    await tester.tap(find.byIcon(Icons.format_quote_rounded));
    await tester.pump();
    expect(blockquoteCount, 1);

    // Tap Code block
    await tester.tap(find.byIcon(Icons.code_rounded));
    await tester.pump();
    expect(codeBlockCount, 1);

    // Tap Hyperlink
    await tester.tap(find.byIcon(Icons.insert_link_rounded));
    await tester.pump();
    expect(linkCount, 1);
  });
}
