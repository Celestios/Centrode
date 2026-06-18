enum HitElement { body, resizeLeft, resizeRight, expandToggle, metadataSphere }

class NodeHitResult {
  final String nodeId;
  final HitElement element;

  const NodeHitResult(this.nodeId, this.element);

  @override
  String toString() => 'NodeHitResult($nodeId, $element)';
}
