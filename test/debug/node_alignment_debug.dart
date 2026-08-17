import 'package:flutter/material.dart';

// ignore_for_file: avoid_print

void main() => runApp(const MaterialApp(home: NodeAlignmentDebug()));

class NodeAlignmentDebug extends StatefulWidget {
  const NodeAlignmentDebug({super.key});

  @override
  State<NodeAlignmentDebug> createState() => _NodeAlignmentDebugState();
}

class _NodeAlignmentDebugState extends State<NodeAlignmentDebug> {
  bool _isEditing = false;
  final _textController = TextEditingController(text: 'Hello World');

  static const double nodePadding = 8.0;
  static const TextStyle textStyle = TextStyle(fontSize: 16, color: Colors.white);

  @override
  void initState() {
    super.initState();
    _printTextMetrics();
  }

  void _printTextMetrics() {
    final textPainter = TextPainter(
      text: TextSpan(text: _textController.text, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    final strutDefault = StrutStyle.fromTextStyle(textStyle);
    final strutDefaultPainter = TextPainter(
      text: TextSpan(text: _textController.text, style: textStyle),
      strutStyle: strutDefault,
      textDirection: TextDirection.ltr,
    )..layout();

    final strutDisabledPainter = TextPainter(
      text: TextSpan(text: _textController.text, style: textStyle),
      strutStyle: StrutStyle.disabled,
      textDirection: TextDirection.ltr,
    )..layout();

    print('');
    print('=== NODE ALIGNMENT TEXT METRICS ===');
    print('TextStyle: fontSize=${textStyle.fontSize}, height=${textStyle.height}');
    print('Text: "${_textController.text}"');
    print('');
    print('--- No strut (Text.rich default) ---');
    print('  textPainter.size: ${textPainter.width.toStringAsFixed(2)} x ${textPainter.height.toStringAsFixed(2)}');
    print('');
    print('--- StrutStyle.fromTextStyle (default TextField) ---');
    print('  textPainter.size: ${strutDefaultPainter.width.toStringAsFixed(2)} x ${strutDefaultPainter.height.toStringAsFixed(2)}');
    print('');
    print('--- StrutStyle.disabled ---');
    print('  textPainter.size: ${strutDisabledPainter.width.toStringAsFixed(2)} x ${strutDisabledPainter.height.toStringAsFixed(2)}');
    print('');
    print('Height diff (no strut vs default strut): ${(strutDefaultPainter.height - textPainter.height).toStringAsFixed(2)}');
    print('Height diff (no strut vs disabled strut): ${(strutDisabledPainter.height - textPainter.height).toStringAsFixed(2)}');
    print('');
    print('Node container: 200x60, padding: ${nodePadding}all');
    print('Available content area: ${(200 - nodePadding * 2).toStringAsFixed(0)}x${(60 - nodePadding * 2).toStringAsFixed(0)}');
    print('');
    print('=== END NODE METRICS ===');
    print('');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Node Text Alignment Debug', style: TextStyle(color: Colors.white, fontSize: 20)),
            const SizedBox(height: 20),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDisplayMode(),
                const SizedBox(width: 40),
                _buildEditMode(),
              ],
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => setState(() => _isEditing = !_isEditing),
              child: Text(_isEditing ? 'Switch to Display' : 'Switch to Edit'),
            ),
            const SizedBox(height: 20),
            _buildCombinedView(),
          ],
        ),
      ),
    );
  }

  Widget _buildDisplayMode() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Display Mode (Text.rich)', style: TextStyle(color: Colors.green, fontSize: 12)),
        const SizedBox(height: 4),
        _buildNodeContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Center(
                  child: Text.rich(
                    TextSpan(text: _textController.text, style: textStyle),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditMode() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Edit Mode (TextField)', style: TextStyle(color: Colors.blue, fontSize: 12)),
        const SizedBox(height: 4),
        _buildNodeContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: const Color(0xFF2196F3).withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                    child: Material(
                      type: MaterialType.transparency,
                      child: TextField(
                        controller: _textController,
                        textAlign: TextAlign.center,
                        textAlignVertical: TextAlignVertical.center,
                        style: textStyle,
                        strutStyle: StrutStyle.disabled,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCombinedView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _isEditing ? 'Combined: Edit Mode' : 'Combined: Display Mode',
          style: TextStyle(
            color: _isEditing ? Colors.blue : Colors.green,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        _buildNodeContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Center(
                  child: _isEditing ? _buildEditorContent() : _buildDisplayContent(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDisplayContent() {
    return Text.rich(
      TextSpan(text: _textController.text, style: textStyle),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildEditorContent() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: const Color(0xFF2196F3).withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
      child: Material(
        type: MaterialType.transparency,
        child: TextField(
          controller: _textController,
          textAlign: TextAlign.center,
          textAlignVertical: TextAlignVertical.center,
          style: textStyle,
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

  Widget _buildNodeContainer({required Widget child}) {
    return SizedBox(
      width: 200,
      height: 60,
      child: Container(
        padding: const EdgeInsets.all(nodePadding),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey, width: 1),
        ),
        child: child,
      ),
    );
  }
}
