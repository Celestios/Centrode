import 'package:flutter/material.dart';

// ignore_for_file: avoid_print

void main() => runApp(const MaterialApp(home: AlignmentDebugScreen()));

class AlignmentDebugScreen extends StatelessWidget {
  const AlignmentDebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Text Alignment Debug', style: TextStyle(color: Colors.white, fontSize: 20)),
              const SizedBox(height: 20),
              _printTextMetrics(),
              const SizedBox(height: 30),
              _buildTestCase('1. Text.rich (display mode)', _buildDisplayText()),
              const SizedBox(height: 20),
              _buildTestCase('2. TextField (vertical=2, strut default)', _buildCurrentEditor()),
              const SizedBox(height: 20),
              _buildTestCase('3. TextField (vertical=0, strut default)', _buildZeroPaddingEditor()),
              const SizedBox(height: 20),
              _buildTestCase('4. TextField (vertical=0, StrutStyle.disabled)', _buildDisabledStrutEditor()),
              const SizedBox(height: 20),
              _buildTestCase('5. TextField (expands=true, strut disabled)', _buildExpandsEditor()),
              const SizedBox(height: 20),
              _buildTestCase('6. EditableText (raw, no InputDecorator)', _buildRawEditable()),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _printTextMetrics() {
    final style = const TextStyle(fontSize: 16, color: Colors.white);
    final textPainter = TextPainter(
      text: TextSpan(text: 'Hello World', style: style),
      textDirection: TextDirection.ltr,
    )..layout();

    final strutStyle = StrutStyle.fromTextStyle(style);
    final strutPainter = TextPainter(
      text: TextSpan(text: 'Hello World', style: style),
      strutStyle: strutStyle,
      textDirection: TextDirection.ltr,
    )..layout();

    final disabledStrutPainter = TextPainter(
      text: TextSpan(text: 'Hello World', style: style),
      strutStyle: StrutStyle.disabled,
      textDirection: TextDirection.ltr,
    )..layout();

    print('');
    print('=== TEXT METRICS (TextPainter) ===');
    print('TextStyle: fontSize=16, height=null');
    print('');
    print('--- No strut (Text.rich default) ---');
    print('  size: ${textPainter.width.toStringAsFixed(2)} x ${textPainter.height.toStringAsFixed(2)}');
    print('');
    print('--- StrutStyle.fromTextStyle (default TextField) ---');
    print('  size: ${strutPainter.width.toStringAsFixed(2)} x ${strutPainter.height.toStringAsFixed(2)}');
    print('');
    print('--- StrutStyle.disabled ---');
    print('  size: ${disabledStrutPainter.width.toStringAsFixed(2)} x ${disabledStrutPainter.height.toStringAsFixed(2)}');
    print('');
    print('Height diff (no strut vs default strut): ${(strutPainter.height - textPainter.height).toStringAsFixed(2)}');
    print('Height diff (no strut vs disabled strut): ${(disabledStrutPainter.height - textPainter.height).toStringAsFixed(2)}');
    print('');
    print('=== END TEXT METRICS ===');
    print('');

    return const SizedBox.shrink();
  }

  Widget _buildTestCase(String label, Widget child) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        SizedBox(
          width: 200,
          height: 60,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red, width: 1),
            ),
            child: child,
          ),
        ),
      ],
    );
  }

  Widget _buildDisplayText() {
    return Center(
      child: Text.rich(
        TextSpan(text: 'Hello World', style: const TextStyle(fontSize: 16, color: Colors.white)),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildCurrentEditor() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF2196F3).withValues(alpha: 0.6), width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Theme(
        data: ThemeData().copyWith(
          textSelectionTheme: const TextSelectionThemeData(
            selectionColor: Color(0x602196F3),
            cursorColor: Color(0xFF2196F3),
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: TextField(
            controller: TextEditingController(text: 'Hello World'),
            textAlign: TextAlign.center,
            textAlignVertical: TextAlignVertical.center,
            style: const TextStyle(fontSize: 16, color: Colors.white),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildZeroPaddingEditor() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF2196F3).withValues(alpha: 0.6), width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
      child: Theme(
        data: ThemeData().copyWith(
          textSelectionTheme: const TextSelectionThemeData(
            selectionColor: Color(0x602196F3),
            cursorColor: Color(0xFF2196F3),
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: TextField(
            controller: TextEditingController(text: 'Hello World'),
            textAlign: TextAlign.center,
            textAlignVertical: TextAlignVertical.center,
            style: const TextStyle(fontSize: 16, color: Colors.white),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDisabledStrutEditor() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF2196F3).withValues(alpha: 0.6), width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
      child: Theme(
        data: ThemeData().copyWith(
          textSelectionTheme: const TextSelectionThemeData(
            selectionColor: Color(0x602196F3),
            cursorColor: Color(0xFF2196F3),
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: TextField(
            controller: TextEditingController(text: 'Hello World'),
            textAlign: TextAlign.center,
            textAlignVertical: TextAlignVertical.center,
            style: const TextStyle(fontSize: 16, color: Colors.white),
            strutStyle: StrutStyle.disabled,
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandsEditor() {
    return Center(
      child: SizedBox(
        width: 188,
        height: 56,
        child: TextField(
          controller: TextEditingController(text: 'Hello World'),
          textAlign: TextAlign.center,
          textAlignVertical: TextAlignVertical.center,
          expands: true,
          maxLines: null,
          style: const TextStyle(fontSize: 16, color: Colors.white),
          strutStyle: StrutStyle.disabled,
          decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }

  Widget _buildRawEditable() {
    return Center(
      child: EditableText(
        controller: TextEditingController(text: 'Hello World'),
        focusNode: FocusNode(),
        cursorColor: const Color(0xFF2196F3),
        backgroundCursorColor: Colors.white,
        style: const TextStyle(fontSize: 16, color: Colors.white),
        textAlign: TextAlign.center,
      ),
    );
  }
}
