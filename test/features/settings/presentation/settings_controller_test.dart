import 'package:flutter_test/flutter_test.dart';
import 'package:centrode/features/settings/presentation/settings_controller.dart';
import 'package:centrode/features/settings/presentation/settings_category.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsController', () {
    late SettingsController controller;

    setUp(() {
      controller = SettingsController();
    });

    tearDown(() async {
      await Future.delayed(const Duration(milliseconds: 150));
      try {
        controller.dispose();
      } catch (_) {}
    });

    test('initial state has appearance category selected', () {
      expect(controller.selectedCategory, SettingsCategory.appearance);
    });

    test('initial state has empty search query', () {
      expect(controller.searchQuery, '');
    });

    test('selectCategory updates selectedCategory and notifies listeners', () {
      int notificationCount = 0;
      controller.addListener(() => notificationCount++);

      controller.selectCategory(SettingsCategory.physics);

      expect(controller.selectedCategory, SettingsCategory.physics);
      expect(notificationCount, 1);
    });

    test('selectCategory with same category does not notify', () {
      int notificationCount = 0;
      controller.addListener(() => notificationCount++);

      controller.selectCategory(SettingsCategory.appearance);

      expect(notificationCount, 0);
    });

    test('updateSearchQuery updates searchQuery and notifies listeners', () {
      int notificationCount = 0;
      controller.addListener(() => notificationCount++);

      controller.updateSearchQuery('  Theme  ');

      expect(controller.searchQuery, 'theme');
      expect(notificationCount, 1);
    });

    test('dispose sets disposed flag and prevents notification', () {
      controller.dispose();

      expect(() => controller.selectCategory(SettingsCategory.physics), throwsFlutterError);
    });

    test('setTheme updates currentThemeName when theme exists', () async {
      await Future.delayed(const Duration(milliseconds: 100));

      final availableThemes = controller.availableThemes;
      if (availableThemes.containsKey('dark')) {
        final currentTheme = controller.currentThemeName;
        final targetTheme = currentTheme == 'dark' ? 'light' : 'dark';

        int notificationCount = 0;
        controller.addListener(() => notificationCount++);

        controller.setTheme(targetTheme);

        expect(controller.currentThemeName, targetTheme);
        expect(notificationCount, 1);
      }
    });

    test('setTheme with non-existent theme does nothing', () {
      int notificationCount = 0;
      controller.addListener(() => notificationCount++);

      controller.setTheme('nonexistent');

      expect(notificationCount, 0);
    });
  });
}
