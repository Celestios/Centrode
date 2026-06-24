enum TextFormatType {
  bold,
  italic,
  underline,
  heading1,
  heading2,
  heading3,
  link,
  blockquote,
  codeBlock,
  bulletList,
  orderedList,
  highlight,
  textColor,
  fontFamily,
  textAlign,
}

const blockLevelTypes = {
  TextFormatType.heading1,
  TextFormatType.heading2,
  TextFormatType.heading3,
  TextFormatType.blockquote,
  TextFormatType.codeBlock,
  TextFormatType.bulletList,
  TextFormatType.orderedList,
  TextFormatType.textAlign,
};

bool isBlockFormatType(TextFormatType type) => blockLevelTypes.contains(type);

class FormattingSpan {
  int start;
  int end;
  final TextFormatType type;
  final String? url;

  FormattingSpan({
    required this.start,
    required this.end,
    required this.type,
    this.url,
  });

  FormattingSpan copyWith({int? start, int? end, String? url}) {
    return FormattingSpan(
      start: start ?? this.start,
      end: end ?? this.end,
      type: type,
      url: url ?? this.url,
    );
  }

  @override
  String toString() => 'FormattingSpan($type, $start-$end)';
}
