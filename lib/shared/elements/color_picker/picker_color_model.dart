import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:centrode/shared/utils/color_theory_engine.dart';

/// State container for [CentrodeColorPicker].
///
/// Holds the live HSV/alpha color, the hex text field, and the recent swatch
/// history. Mutating methods notify listeners (so the picker subtree rebuilds)
/// and invoke the optional change callbacks. Continuous drag handlers
/// ([setSaturationValue]/[setHue]/[setAlpha]) do *not* push to recents, while
/// committed changes (swatch tap, hex submit, paste, randomize) do — matching
/// the original interaction model.
class PickerColorModel extends ChangeNotifier {
  HSVColor hsvColor;
  double alpha;
  final TextEditingController hexController;
  List<Color> recents;

  final ValueChanged<Color>? onColorChanged;
  final ValueChanged<Color>? onRecentColorAdded;

  PickerColorModel({
    required Color initialColor,
    this.onColorChanged,
    this.onRecentColorAdded,
    List<Color> recentColors = const [],
  })  : hsvColor = HSVColor.fromColor(initialColor),
        alpha = initialColor.a,
        hexController = TextEditingController(
          text: ColorTheoryEngine.toHex(initialColor).replaceFirst('#', ''),
        ),
        recents = List<Color>.from(recentColors);

  Color get currentColor => hsvColor.toColor().withValues(alpha: alpha);

  void _syncHex(Color c) {
    hexController.text = ColorTheoryEngine.toHex(c).replaceFirst('#', '');
  }

  /// Commit a discrete new color. Pushes to recents unless [pushRecent] is false.
  void commitColor(Color color, {bool updateHex = true, bool pushRecent = false}) {
    hsvColor = HSVColor.fromColor(color);
    alpha = color.a;
    if (updateHex) _syncHex(color);
    if (pushRecent) _pushRecent(color);
    notifyListeners();
    onColorChanged?.call(currentColor);
  }

  void _pushRecent(Color color) {
    recents.remove(color);
    recents.insert(0, color);
    if (recents.length > 6) recents.removeLast();
    onRecentColorAdded?.call(color);
  }

  /// SV canvas drag (continuous) — no recent push.
  void setSaturationValue(double sat, double val) {
    hsvColor = hsvColor
        .withSaturation(sat.clamp(0.0, 1.0))
        .withValue(val.clamp(0.0, 1.0));
    _syncHex(currentColor);
    notifyListeners();
    onColorChanged?.call(currentColor);
  }

  /// Hue slider drag (continuous) — no recent push.
  void setHue(double hue) {
    hsvColor = hsvColor.withHue(hue.clamp(0.0, 360.0));
    _syncHex(currentColor);
    notifyListeners();
    onColorChanged?.call(currentColor);
  }

  /// Alpha slider drag (continuous) — no recent push.
  void setAlpha(double a) {
    alpha = a.clamp(0.0, 1.0);
    _syncHex(currentColor);
    notifyListeners();
    onColorChanged?.call(currentColor);
  }

  void onHexSubmitted(String hex) {
    final parsed = ColorTheoryEngine.tryParseHex(hex);
    if (parsed != null) commitColor(parsed, updateHex: false);
  }

  Future<void> pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      final parsed = ColorTheoryEngine.tryParseHex(data!.text!);
      if (parsed != null) commitColor(parsed);
    }
  }

  Future<void> copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: ColorTheoryEngine.toHex(currentColor)));
  }

  void randomize() {
    commitColor(ColorTheoryEngine.generateHarmonicRandomColor(), pushRecent: true);
  }

  @override
  void dispose() {
    hexController.dispose();
    super.dispose();
  }
}
