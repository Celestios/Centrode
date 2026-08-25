import 'dart:async';
import 'package:centrode/src/rust/bridge/stream.dart';
import 'package:centrode/src/rust/domain/base_models.dart' hide Size;
import 'package:centrode/src/rust/domain/types.dart';
import 'package:centrode/src/rust/domain/snapshot.dart';

abstract interface class ViewportApi {
  Future<void> updateViewportState({required ViewportState state});
  Future<BoundingBox?> getOptArea();
  Future<void> setOptArea({BoundingBox? bounds});
  Future<GraphSnapshot> getGraphSnapshot();
  Future<List<Nodes>> querySearch({required String query});
  Stream<GraphEvent> createGraphStream();
  Future<void> close();
}
