import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:centrode/shared/elements/centrode_button.dart';
import 'package:centrode/shared/elements/centrode_segmented_control.dart';
import 'package:centrode/shared/elements/centrode_compact_slider.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
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

      expect(find.text('One'), findsWidgets);
      expect(find.text('Two'), findsWidgets);
      expect(find.text('Three'), findsWidgets);
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

      await tester.tap(find.text('Two'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(selected, equals(2));
    });

    testWidgets('sliding indicator exists via LiquidGlassView', (tester) async {
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

      expect(find.byType(LiquidGlassView), findsOneWidget);
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
    testWidgets('renders properly with initial value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CentrodeCompactSlider(
              value: 0.5,
              min: 0.0,
              max: 1.0,
              activeColor: Colors.blue,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(CentrodeCompactSlider), findsOneWidget);
    });

    testWidgets('slider responds to drag gestures', (tester) async {
      double changedValue = 0.0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              child: CentrodeCompactSlider(
                value: 0.0,
                min: 0.0,
                max: 100.0,
                activeColor: Colors.red,
                onChanged: (val) {
                  changedValue = val;
                },
              ),
            ),
          ),
        ),
      );

      final sliderFinder = find.byType(CentrodeCompactSlider);
      expect(sliderFinder, findsOneWidget);
      await tester.drag(sliderFinder, const Offset(50, 0));
      await tester.pump();
      expect(changedValue, greaterThan(0));
    });
  });
}
