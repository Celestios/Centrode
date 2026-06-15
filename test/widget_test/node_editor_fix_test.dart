import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(home: NodeEditorTest()));

class NodeEditorTest extends StatefulWidget {
  const NodeEditorTest({super.key});

  @override
  State<NodeEditorTest> createState() => _NodeEditorTestState();
}

class _NodeEditorTestState extends State<NodeEditorTest> {
  int _selectedConfig = 0;

  static const TextStyle textStyle = TextStyle(fontSize: 16, color: Colors.white);
  static const double nodePadding = 8.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Node Editor Fix Test', style: TextStyle(color: Colors.white, fontSize: 20)),
            const SizedBox(height: 10),
            const Text('Top = display mode (Text.rich)', style: TextStyle(color: Colors.green, fontSize: 11)),
            const Text('Bottom = edit mode (your choice)', style: TextStyle(color: Colors.blue, fontSize: 11)),
            const SizedBox(height: 20),

            _buildConfigButtons(),
            const SizedBox(height: 20),

            // Display reference on top
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Display (Text.rich)', style: TextStyle(color: Colors.green, fontSize: 11)),
                    const SizedBox(height: 4),
                    _wrapInNodeContainer(
                      child: Text.rich(
                        TextSpan(text: 'Hello World', style: textStyle),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 30),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Edit: ${_configName(_selectedConfig)}', style: const TextStyle(color: Colors.blue, fontSize: 11)),
                    const SizedBox(height: 4),
                    _wrapInNodeContainer(
                      child: _buildEditorForConfig(_selectedConfig),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  String _configName(int i) => switch (i) {
    0 => 'Original (forceStrutHeight, v=2)',
    1 => 'StrutStyle.disabled, v=0',
    2 => 'StrutStyle.disabled, v=0, expands=true',
    3 => 'No strut, v=0',
    4 => 'No strut, v=0, expands=true',
    5 => 'EditableText (raw)',
    6 => 'EditableText + GestureBuilder',
    7 => '6 + no magnifier, no handles',
    _ => 'Unknown',
  };

  Widget _buildConfigButtons() {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: List.generate(8, (i) => ElevatedButton(
        onPressed: () => setState(() => _selectedConfig = i),
        style: ElevatedButton.styleFrom(
          backgroundColor: _selectedConfig == i ? Colors.blue : Colors.grey[800],
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
        child: Text('$i', style: const TextStyle(fontSize: 11)),
      )),
    );
  }

  Widget _buildEditorForConfig(int config) {
    return switch (config) {
      0 => _buildOriginalEditor(),
      1 => _buildStrutDisabledV0(),
      2 => _buildStrutDisabledExpands(),
      3 => _buildNoStrutV0(),
      4 => _buildNoStrutExpands(),
      5 => _buildRawEditable(),
      6 => _buildEditableWithGestureDetector(),
      7 => _buildDesktopStyle(),
      _ => const SizedBox.shrink(),
    };
  }

  // Config 0: Original code (before any changes)
  Widget _buildOriginalEditor() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF2196F3).withValues(alpha: 0.6), width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Material(
        type: MaterialType.transparency,
        child: TextField(
          controller: TextEditingController(text: 'Hello World'),
          maxLines: null,
          minLines: 1,
          expands: false,
          textAlign: TextAlign.center,
          textAlignVertical: TextAlignVertical.center,
          style: textStyle,
          strutStyle: StrutStyle.fromTextStyle(textStyle, forceStrutHeight: true),
          decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }

  // Config 1: StrutStyle.disabled, vertical=0
  Widget _buildStrutDisabledV0() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF2196F3).withValues(alpha: 0.6), width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
      child: Material(
        type: MaterialType.transparency,
        child: TextField(
          controller: TextEditingController(text: 'Hello World'),
          maxLines: null,
          minLines: 1,
          expands: false,
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

  // Config 2: StrutStyle.disabled, vertical=0, expands=true (needs SizedBox, no Center)
  Widget _buildStrutDisabledExpands() {
    return SizedBox(
      width: 184,
      height: 44,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF2196F3).withValues(alpha: 0.6), width: 1.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
        child: Material(
          type: MaterialType.transparency,
          child: TextField(
            controller: TextEditingController(text: 'Hello World'),
            maxLines: null,
            minLines: null,
            expands: true,
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
    );
  }

  // Config 3: No strut, vertical=0
  Widget _buildNoStrutV0() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF2196F3).withValues(alpha: 0.6), width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
      child: Material(
        type: MaterialType.transparency,
        child: TextField(
          controller: TextEditingController(text: 'Hello World'),
          maxLines: null,
          minLines: 1,
          expands: false,
          textAlign: TextAlign.center,
          textAlignVertical: TextAlignVertical.center,
          style: textStyle,
          decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }

  // Config 4: No strut, vertical=0, expands=true (needs SizedBox, no Center)
  Widget _buildNoStrutExpands() {
    return SizedBox(
      width: 184,
      height: 44,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF2196F3).withValues(alpha: 0.6), width: 1.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
        child: Material(
          type: MaterialType.transparency,
          child: TextField(
            controller: TextEditingController(text: 'Hello World'),
            maxLines: null,
            minLines: null,
            expands: true,
            textAlign: TextAlign.center,
            textAlignVertical: TextAlignVertical.center,
            style: textStyle,
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

  // Config 5: Raw EditableText
  Widget _buildRawEditable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF2196F3).withValues(alpha: 0.6), width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
      child: Material(
        type: MaterialType.transparency,
        child: EditableText(
          controller: TextEditingController(text: 'Hello World'),
          focusNode: FocusNode(),
          maxLines: null,
          minLines: 1,
          expands: false,
          textAlign: TextAlign.center,
          cursorColor: const Color(0xFF2196F3),
          backgroundCursorColor: Colors.grey,
          selectionColor: const Color(0x602196F3),
          style: textStyle,
          strutStyle: StrutStyle.disabled,
          selectionControls: MaterialTextSelectionControls(),
          showSelectionHandles: true,
        ),
      ),
    );
  }

  Widget _buildEditableWithGestureDetector() {
    final editableKey = GlobalKey<EditableTextState>();
    final delegate = _TestGestureDelegate(editableKey);
    final builder = TextSelectionGestureDetectorBuilder(delegate: delegate);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF2196F3).withValues(alpha: 0.6), width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
      child: Material(
        type: MaterialType.transparency,
          child: builder.buildGestureDetector(
            behavior: HitTestBehavior.translucent,
            child: EditableText(
              key: editableKey,
              controller: TextEditingController(text: 'Hello World'),
              focusNode: FocusNode(),
              maxLines: null,
              minLines: 1,
              expands: false,
              textAlign: TextAlign.center,
              autofocus: true,
              cursorColor: const Color(0xFF2196F3),
              backgroundCursorColor: Colors.grey,
              selectionColor: const Color(0x602196F3),
              style: textStyle,
              strutStyle: StrutStyle.disabled,
              selectionControls: MaterialTextSelectionControls(),
              showSelectionHandles: true,
              magnifierConfiguration: TextMagnifierConfiguration.disabled,
            ),
          ),
      ),
    );
  }

  Widget _buildDesktopStyle() {
    final editableKey = GlobalKey<EditableTextState>();
    final delegate = _TestGestureDelegate(editableKey);
    final builder = TextSelectionGestureDetectorBuilder(delegate: delegate);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF2196F3).withValues(alpha: 0.6), width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
      child: Material(
        type: MaterialType.transparency,
        child: builder.buildGestureDetector(
          behavior: HitTestBehavior.translucent,
            child: EditableText(
              key: editableKey,
              controller: TextEditingController(text: 'Hello World'),
              focusNode: FocusNode(),
              maxLines: null,
              minLines: 1,
              expands: false,
              textAlign: TextAlign.center,
              autofocus: true,
              cursorColor: const Color(0xFF2196F3),
              backgroundCursorColor: Colors.grey,
              selectionColor: const Color(0x602196F3),
              style: textStyle,
              strutStyle: StrutStyle.disabled,
              selectionControls: MaterialTextSelectionControls(),
              showSelectionHandles: false,
              magnifierConfiguration: TextMagnifierConfiguration.disabled,
            ),
        ),
      ),
    );
  }

  Widget _wrapInNodeContainer({required Widget child}) {
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
        child: Center(child: child),
      ),
    );
  }
}

class _TestGestureDelegate implements TextSelectionGestureDetectorBuilderDelegate {
  _TestGestureDelegate(this._key);
  final GlobalKey<EditableTextState> _key;

  @override
  GlobalKey<EditableTextState> get editableTextKey => _key;

  @override
  bool get forcePressEnabled => false;

  @override
  bool get selectionEnabled => true;
}
