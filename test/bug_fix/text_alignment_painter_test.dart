// =============================================================================
// Bug Report: Text Alignment in Canvas Painter
// =============================================================================
//
// PROBLEM:
// Text alignment (left/center/right) set on paragraphs via the toolbar only
// reflected on the FIRST paragraph in the canvas painter. All subsequent
// paragraphs ignored their alignment and defaulted to center.
//
// SYMPTOMS:
// 1. Painter path: only the first block's alignment was applied. Blocks after
//    the first always rendered centered regardless of what alignment was set.
// 2. Widget path (collapsed mode): used only the first block's alignment for
//    ALL text — by design (single RichText with maxLines).
// 3. Widget path (expanded mode): correctly rendered per-block alignment.
// 4. Cycling alignment: could only cycle once per edit session. Had to exit
//    and re-enter edit mode to cycle again.
// 5. After cycling, spans would shatter into thousands of 1-2 char fragments,
//    growing exponentially (14 → 105 → 560 → 2380 → ...).
//
// ROOT CAUSES (3 separate bugs):
//
// Bug 1: buildContent() textAlign break-skip (text_ast_serializer.dart)
//   In buildContent(), the span-matching loop used a single pass with `break`
//   statements for block-type detection (heading, blockquote, etc.). If a
//   heading span appeared BEFORE a textAlign span in the list, the break
//   prevented the textAlign from being read. The textAlign variable stayed
//   null, and the ContentBlock was created without textAlign in attrs.
//
//   Fix: Split the loop into two passes — first collects textAlign from ALL
//   spans (no breaks), then detects block type (with breaks). This ensures
//   textAlign is never skipped regardless of span ordering.
//
// Bug 2: cycleTextAlign() only processed cursor line (text_format_state_machine.dart)
//   When "select all" was used and alignment was cycled, only the single line
//   containing the cursor received a textAlign span. Other selected lines
//   were ignored.
//
//   Fix: Compute selectedLineBounds from the full selection range (not just
//   cursor position). Apply alignment to ALL lines in the selection.
//
// Bug 3: Span trimming created inter-line fragments (text_format_state_machine.dart)
//   The trimming logic processed each selected line independently, creating
//   1-char fragments for the \n characters between lines. These fragments:
//   a) Accumulated exponentially on each cycle (14 → 105 → 560 → ...)
//   b) The first fragment "overlapped" the first line, fooling currentAlign
//      detection into always finding 'center' (the fragment's alignment),
//      so the cycle never advanced past center→right.
//
//   Fix: Trim against the ENTIRE selection range as a single region, not
//   per-line. This eliminates inter-line fragments entirely.
//
// FILES CHANGED:
//   - lib/features/graph/ui/canvas/text_ast_serializer.dart
//     buildContent(): Two-pass loop for textAlign + block type detection.
//
//   - lib/features/graph/ui/canvas/text_format_state_machine.dart
//     cycleTextAlign(): Multi-line selection support + range-based trimming.
//
//   - lib/features/graph/ui/canvas/content_text_editing_controller.dart
//     (debug prints removed, no logic changes)
//
// HOW TO TEST:
//   1. Run: flutter run -d windows -t test/bug_fix/text_alignment_painter_test.dart
//   2. Toggle alignment chips for Block 0 and Block 1 independently.
//   3. Both Widget path and Painter path should reflect per-block alignment.
//   4. In the real app: create a node with \n between lines, set different
//      alignments on each paragraph, exit edit mode, verify painter shows
//      correct per-block alignment.
//   5. Cycle alignment multiple times without exiting edit mode — should
//      cycle through null → left → center → right → null → ... reliably.
//
// CALLOUT: The real app's alignment flow:
//   Toolbar click → cycleTextAlign() → modifies formattingSpans
//   → notifyListeners() → editor rebuilds → buildContent() creates Content
//   → ContentBlock with attrs.textAlign → painter reads via
//   buildPerBlockTextSpans() → TextPainter with per-block textAlign.
//
//   Any break in this chain (span fragmentation, missing attrs, single-line
//   selection) causes alignment to not propagate to the painter.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:mycelium/features/graph/presentation/strategies/node_text_span_builder.dart';
import 'package:mycelium/src/rust/domain/contents.dart';

void main() {
  runApp(const MaterialApp(home: AlignmentBugTestWidget()));
}

class AlignmentBugTestWidget extends StatefulWidget {
  const AlignmentBugTestWidget({super.key});

  @override
  State<AlignmentBugTestWidget> createState() => _AlignmentBugTestWidgetState();
}

class _AlignmentBugTestWidgetState extends State<AlignmentBugTestWidget> {
  TextAlign _block0Align = TextAlign.left;
  TextAlign _block1Align = TextAlign.right;

  Content get _content => Content(
    text: 'first paragraph\nsecond paragraph',
    blocks: [
      ContentBlock(
        blockType: BlockType.paragraph,
        content: [InlineElement(inlineType: InlineType.text, text: 'first paragraph')],
        attrs: BlockAttrs(textAlign: _block0Align.name),
      ),
      ContentBlock(
        blockType: BlockType.paragraph,
        content: [InlineElement(inlineType: InlineType.text, text: 'second paragraph')],
        attrs: BlockAttrs(textAlign: _block1Align.name),
      ),
    ],
  );

  Widget _buildAlignSelector(String label, TextAlign current, ValueChanged<TextAlign> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${current.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Row(
          children: [TextAlign.left, TextAlign.center, TextAlign.right].map((a) =>
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(a.name),
                selected: current == a,
                onSelected: (_) => onChanged(a),
              ),
            ),
          ).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = const TextStyle(fontSize: 16, color: Colors.black);
    final blockSpans = NodeTextSpanBuilder.buildPerBlockTextSpans(_content, baseStyle);

    return Scaffold(
      appBar: AppBar(title: const Text('Alignment Bug Test')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _buildAlignSelector('Block 0', _block0Align, (a) => setState(() => _block0Align = a)),
            const SizedBox(height: 12),
            _buildAlignSelector('Block 1', _block1Align, (a) => setState(() => _block1Align = a)),
            const SizedBox(height: 24),
            const Divider(),
            const Text('Widget path (per-block RichText):', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              width: 300,
              height: 80,
              decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
              child: _buildWidgetPath(blockSpans),
            ),
            const SizedBox(height: 24),
            const Text('Painter path (per-block RichText):', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              width: 300,
              height: 80,
              decoration: BoxDecoration(border: Border.all(color: Colors.blue)),
              child: _buildPainterPath(blockSpans),
            ),
            const SizedBox(height: 24),
            const Text('Data check:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            for (int i = 0; i < blockSpans.length; i++)
              Text('Block $i: textAlign=${blockSpans[i].$2}'),
          ],
        ),
      ),
    );
  }

  Widget _buildWidgetPath(List<(TextSpan, TextAlign)> blockSpans) {
    if (blockSpans.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (span, align) in blockSpans)
          RichText(text: span, textAlign: align),
      ],
    );
  }

  Widget _buildPainterPath(List<(TextSpan, TextAlign)> blockSpans) {
    if (blockSpans.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (span, align) in blockSpans)
          RichText(text: span, textAlign: align),
      ],
    );
  }
}
