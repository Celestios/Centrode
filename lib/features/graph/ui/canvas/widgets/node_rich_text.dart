import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../engine/config.dart';
import '../../../models/models.dart';
import '../../../presentation/strategies/node_layout_strategy.dart';

class NodeRichText extends StatefulWidget {
  final Content content;
  final TextStyle baseStyle;
  final bool isExpanded;

  const NodeRichText({
    super.key,
    required this.content,
    required this.baseStyle,
    required this.isExpanded,
  });

  @override
  State<NodeRichText> createState() => _NodeRichTextState();
}

class _NodeRichTextState extends State<NodeRichText> {
  final List<TapGestureRecognizer> _recognizers = [];
  TextSpan? _cachedTextSpan;
  List<(TextSpan, TextAlign)>? _cachedBlockSpans;
  Content? _cachedContent;
  TextStyle? _cachedBaseStyle;

  @override
  void dispose() {
    _clearRecognizers();
    super.dispose();
  }

  void _clearRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  void _ensureBuilt() {
    if (_cachedContent == widget.content && _cachedBaseStyle == widget.baseStyle) return;
    _clearRecognizers();
    _cachedContent = widget.content;
    _cachedBaseStyle = widget.baseStyle;

    _cachedTextSpan = NodeLayoutStrategy.buildRichTextSpan(
      widget.content,
      widget.baseStyle,
      onLinkTap: (url) async {
        final Uri uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      },
      registerRecognizer: (recognizer) {
        _recognizers.add(recognizer);
      },
    );

    _cachedBlockSpans = NodeLayoutStrategy.buildPerBlockTextSpans(
      widget.content,
      widget.baseStyle,
      onLinkTap: (url) async {
        final Uri uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      },
      registerRecognizer: (recognizer) {
        _recognizers.add(recognizer);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    _ensureBuilt();

    if (widget.isExpanded) {
      return ClipRect(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i < _cachedBlockSpans!.length; i++)
              Text.rich(
                _cachedBlockSpans![i].$1,
                textAlign: _cachedBlockSpans![i].$2,
              ),
          ],
        ),
      );
    }

    final alignment = _cachedBlockSpans != null && _cachedBlockSpans!.isNotEmpty
        ? _cachedBlockSpans!.first.$2
        : TextAlign.center;

    return Text.rich(
      _cachedTextSpan!,
      textAlign: alignment,
      overflow: TextOverflow.fade,
      maxLines: AppConfig.node.collapsedLineLimit,
    );
  }
}
