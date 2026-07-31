import 'dart:ui';
import 'package:centrode/shared/logging.dart';
import '../../models/models.dart';
import '../command_queue_processor.dart';
import '../graph_data_query.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';

/// Text mutation operations for the graph.
class GraphTextMutations {
  final Logger _log = Logger('GraphTextMutations');
  final CommandQueueProcessor controller;

  GraphTextMutations(this.controller);

  void commitEntityText(
    RawUuid id,
    dynamic newTextOrContent, {
    dynamic originalTextOrContent,
  }) {
    final node = controller.store.nodeLookup[id];
    final rel = controller.store.relationLookup[id];

    final Content newContent = newTextOrContent is Content
        ? newTextOrContent
        : ContentFactory.fromText(newTextOrContent as String);

    final Content oldContent = originalTextOrContent is Content
        ? originalTextOrContent
        : (originalTextOrContent is String
              ? ContentFactory.fromText(originalTextOrContent)
              : (node?.content ?? ContentFactory.empty()));

    _log.info('Committing text for $id: "${newContent.text}"');

    if (node != null && _contentEquals(oldContent, newContent)) {
      return;
    }
    if (rel != null && oldContent.text == newContent.text) {
      return;
    }

    Size? preEditSize;
    if (node != null) {
      final oldContentBackup = node.content;
      node.content = oldContent;
      preEditSize = controller.calculateNodeSize(node).size;
      node.content = oldContentBackup;
    } else {
      preEditSize = node?.size;
    }

    if (node != null) {
      node.content = newContent;
      final result = controller.calculateNodeSize(node);
      node.size = result.size;
      node.lineCount = result.lineCount;
    } else if (rel != null) {
      rel.verb = newContent.text;
    }

    controller.syncEngine.processor.queueCommand(
      UpdateTextCommand(
        targetId: id,
        tableName: node?.tableName ?? 'IRelation',
        api: controller.syncEngine.api,
        oldContent: node == null ? null : oldContent,
        newContent: node == null ? null : newContent,
        oldSize: node == null ? null : preEditSize,
        newSize: node?.size,
        oldVerb: rel == null ? null : oldContent.text,
        newVerb: rel == null ? null : newContent.text,
        controller: controller,
      ),
    );

    if (node != null) {
      controller.publishUpdate(
        GraphEntityUpdate(
          id: id,
          tableName: node.tableName,
          type: GraphUpdateType.text,
          payload: newContent.text,
        ),
      );
      controller.publishUpdate(
        GraphEntityUpdate(
          id: id,
          tableName: node.tableName,
          type: GraphUpdateType.size,
          payload: node.size,
        ),
      );
    } else if (rel != null) {
      controller.publishUpdate(
        GraphEntityUpdate(
          id: id,
          tableName: 'IRelation',
          type: GraphUpdateType.text,
          payload: newContent.text,
        ),
      );
    }
  }

  void updateEntityTextLive(RawUuid id, dynamic newTextOrContent) {
    final node = controller.store.nodeLookup[id];
    final rel = controller.store.relationLookup[id];

    final Content newContent = newTextOrContent is Content
        ? newTextOrContent
        : ContentFactory.fromText(newTextOrContent as String);

    if (node != null) {
      if (_contentEquals(node.content, newContent)) {
        return;
      }
      node.content = newContent;
      final result = controller.calculateNodeSize(node, isEditing: true);
      node.size = result.size;
      node.lineCount = result.lineCount;
      controller.publishUpdate(
        GraphEntityUpdate(
          id: id,
          tableName: node.tableName,
          type: GraphUpdateType.text,
          payload: newContent.text,
        ),
      );
      controller.publishUpdate(
        GraphEntityUpdate(
          id: id,
          tableName: node.tableName,
          type: GraphUpdateType.size,
          payload: node.size,
        ),
      );
    } else if (rel != null) {
      if (rel.verb == newContent.text) return;
      rel.verb = newContent.text;
      controller.publishUpdate(
        GraphEntityUpdate(
          id: id,
          tableName: 'IRelation',
          type: GraphUpdateType.text,
          payload: newContent.text,
        ),
      );
    }
  }

  bool _contentEquals(Content a, Content b) {
    if (a.text != b.text) return false;
    if (a.blocks.length != b.blocks.length) return false;
    for (int i = 0; i < a.blocks.length; i++) {
      final ba = a.blocks[i];
      final bb = b.blocks[i];
      if (ba.blockType != bb.blockType) return false;
      if (ba.attrs != bb.attrs) return false;
      if (ba.content.length != bb.content.length) return false;
      for (int j = 0; j < ba.content.length; j++) {
        final ia = ba.content[j];
        final ib = bb.content[j];
        if (ia.inlineType != ib.inlineType) return false;
        if (ia.text != ib.text) return false;

        final marksA = ia.marks;
        final marksB = ib.marks;
        if (marksA == null && marksB == null) continue;
        if (marksA == null || marksB == null) return false;
        if (marksA.length != marksB.length) return false;
        for (int k = 0; k < marksA.length; k++) {
          final ma = marksA[k];
          final mb = marksB[k];
          if (ma.markType != mb.markType) return false;
          if (ma.attrs != mb.attrs) return false;
        }
      }
    }
    return true;
  }
}
