import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:centrode/shared/elements/centrode_button.dart';
import 'package:centrode/shared/elements/centrode_segmented_control.dart';
import 'package:centrode/shared/elements/centrode_compact_slider.dart';
import 'package:centrode/shared/theme/design_tokens.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CentrodeButton', () {
    testWidgets('tap triggers onTap callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CentrodeButton(
              onTap: () => tapped = true,
              child: const Text('Tap me'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap me'));
      expect(tapped, isTrue);
    });

    testWidgets('hover scale animation activates on hover', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CentrodeButton(
              onTap: () {},
              child: const Text('Hover me'),
            ),
          ),
        ),
      );

      final gesture = await tester.createGesture();
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(tester.getCenter(find.text('Hover me')));
      await tester.pump();
      // AnimatedScale should be rendering with hover scale
      final animatedScale = tester.widget<AnimatedScale>(
        find.ancestor(of: find.text('Hover me'), matching: find.byType(AnimatedScale)).first,
      );
      expect(animatedScale.scale, closeTo(UiMotion.hoverScale, 0.1));
    });

    testWidgets('disabled button does not fire onTap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CentrodeButton(
              isEnabled: false,
              onTap: () => tapped = true,
              child: const Text('Disabled'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Disabled'));
      expect(tapped, isFalse);
    });

    testWidgets('builder provides isHovered and isPressed state', (tester) async {
      bool? lastHovered;
      bool? lastPressed;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CentrodeButton(
              onTap: () {},
              builder: (context, isHovered, isPressed) {
                lastHovered = isHovered;
                lastPressed = isPressed;
                return const Text('Built');
              },
            ),
          ),
        ),
      );

      expect(lastHovered, isFalse);
      expect(lastPressed, isFalse);
    });
  });

  group('CentrodeSegmentedControl', () {
    testWidgets('renders all segment items', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CentrodeSegmentedControl<int>(
              items: [
                (icon: Icons.looks_one, label: 'One', mode: 1, tooltip: null, accentBadge: null),
                (icon: Icons.looks_two, label: 'Two', mode: 2, tooltip: null, accentBadge: null),
                (icon: Icons.looks_3, label: 'Three', mode: 3, tooltip: null, accentBadge: null),
              ],
              currentMode: 1,
              onSelected: (_) {},
              isCompact: false,
            ),
          ),
        ),
      );

      expect(find.text('One'), findsOneWidget);
      expect(find.text('Two'), findsOneWidget);
      expect(find.text('Three'), findsOneWidget);
    });

    testWidgets('tapping a different segment triggers onSelected', (tester) async {
      int? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CentrodeSegmentedControl<int>(
              items: [
                (icon: Icons.looks_one, label: 'One', mode: 1, tooltip: null, accentBadge: null),
                (icon: Icons.looks_two, label: 'Two', mode: 2, tooltip: null, accentBadge: null),
                (icon: Icons.looks_3, label: 'Three', mode: 3, tooltip: null, accentBadge: null),
              ],
              currentMode: 1,
              onSelected: (v) => selected = v,
              isCompact: false,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Two'));
      await tester.pumpAndSettle();
      expect(selected, equals(2));
    });

    testWidgets('sliding indicator exists via AnimatedPositioned', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CentrodeSegmentedControl<int>(
              items: [
                (icon: Icons.looks_one, label: 'A', mode: 1, tooltip: null, accentBadge: null),
                (icon: Icons.looks_two, label: 'B', mode: 2, tooltip: null, accentBadge: null),
              ],
              currentMode: 1,
              onSelected: (_) {},
              isCompact: false,
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedPositioned), findsOneWidget);
    });

    testWidgets('compact mode hides text labels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CentrodeSegmentedControl<int>(
              items: [
                (icon: Icons.looks_one, label: 'One', mode: 1, tooltip: null, accentBadge: null),
                (icon: Icons.looks_two, label: 'Two', mode: 2, tooltip: null, accentBadge: null),
              ],
              currentMode: 1,
              onSelected: (_) {},
              isCompact: true,
            ),
          ),
        ),
      );

      expect(find.text('One'), findsNothing);
      expect(find.text('Two'), findsNothing);
    });
  });

  group('CentrodeCompactSlider', () {
    testWidgets('displays label and formatted value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CentrodeCompactSlider(
              label: 'Opacity',
              value: 75.0,
              min: 0,
              max: 100,
              activeColor: Colors.blue,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Opacity'), findsOneWidget);
      expect(find.text('75px'), findsOneWidget);
    });

    testWidgets('clamps value to min/max bounds', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CentrodeCompactSlider(
              label: 'Size',
              value: 150,
              min: 0,
              max: 100,
              activeColor: Colors.red,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      // Value is clamped to max=100 in display
      expect(find.text('100px'), findsOneWidget);
    });

    testWidgets('slider widget is rendered', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CentrodeCompactSlider(
              label: 'Gap',
              value: 4.0,
              min: 0,
              max: 20,
              activeColor: Colors.green,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('percentage unit formats without decimals', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CentrodeCompactSlider(
              label: 'Fill',
              value: 50.0,
              min: 0,
              max: 100,
              unit: '%',
              activeColor: Colors.purple,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('50%'), findsOneWidget);
    });
  });
}
