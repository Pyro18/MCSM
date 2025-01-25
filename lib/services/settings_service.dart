import 'dart:convert';
import 'dart:io';

import '../models/settings_model.dart';
import 'storage/storage_config.dart';

class SettingsService {
  String get configPath => StorageConfig.configPath;

  Future<void> init() async {
    await StorageConfig.ensureDirectoriesExist();

    final file = File(configPath);
    if (!await file.exists()) {
      await saveSettings(Settings.defaults());
    }
  }

  Future<Settings> loadSettings() async {
    try {
      final file = File(configPath);
      if (!await file.exists()) {
        return Settings.defaults();
      }

      final content = await file.readAsString();
      return Settings.fromJson(jsonDecode(content));
    } catch (e, stack) {
      print('Error loading settings: $e\n$stack');
      return Settings.defaults();
    }
  }

  Future<void> saveSettings(Settings settings) async {
    try {
      final file = File(configPath);
      await file.writeAsString(
          JsonEncoder.withIndent('  ').convert(settings.toJson()));
    } catch (e, stack) {
      print('Error saving settings: $e\n$stack');
      rethrow;
    }
  }
}
