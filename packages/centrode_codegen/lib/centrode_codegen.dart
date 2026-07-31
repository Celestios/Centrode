import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'src/ui_node_generator.dart';

Builder uiNodeBuilderFactory(BuilderOptions options) =>
    LibraryBuilder(UiNodeGenerator(), generatedExtension: '.ui.dart');
