/// Strongly typed tool modes for canvas interaction state dispatching.
enum CanvasToolMode {
  select('select'),
  pan('pan'),
  draw('draw'),
  optimize('optimize'),
  frame('frame');

  final String value;
  const CanvasToolMode(this.value);

  static CanvasToolMode fromString(String? val) {
    return switch (val) {
      'pan' => CanvasToolMode.pan,
      'draw' => CanvasToolMode.draw,
      'optimize' => CanvasToolMode.optimize,
      'frame' => CanvasToolMode.frame,
      _ => CanvasToolMode.select,
    };
  }

  bool get isPan => this == CanvasToolMode.pan;
  bool get isDraw => this == CanvasToolMode.draw;
  bool get isOptimize => this == CanvasToolMode.optimize;
  bool get isFrame => this == CanvasToolMode.frame;
  bool get isSelect => this == CanvasToolMode.select;
}
