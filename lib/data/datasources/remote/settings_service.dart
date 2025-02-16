import 'dart:convert';
import 'dart:io';

import '../../../domain/entities/settings.dart';
import '../local/storage_config.dart';

class SettingsService {
  String get configPath => StorageConfig.configPath;

  Future<void> init() async {
    try {
      await StorageConfig.ensureDirectoriesExist();

      final file = File(configPath);
      if (!await file.exists()) {
        print('Creating default settings file at: $configPath');
        await saveSettings(Settings.defaults());
      }
    } catch (e) {
      print('Error initializing settings service: $e');
      rethrow;
    }
  }

  Future<Settings> loadSettings() async {
    try {
      final file = File(configPath);
      if (!await file.exists()) {
        print('Settings file not found, returning defaults');
        return Settings.defaults();
      }

      final content = await file.readAsString();
      final json = jsonDecode(content);
      final settings = Settings.fromJson(json);
      print('Loaded settings from file: $configPath');
      print('Java path from loaded settings: ${settings.javaPath}');
      return settings;
    } catch (e, stack) {
      print('Error loading settings: $e');
      print('Stack trace: $stack');
      return Settings.defaults();
    }
  }

  Future<void> saveSettings(Settings settings) async {
    try {
      print('Saving settings to: $configPath');
      print('Java path being saved: ${settings.javaPath}');

      final file = File(configPath);
      final json = settings.toJson();

      await file.writeAsString(
        JsonEncoder.withIndent('  ').convert(json),
        flush: true,
      );

      // Verifica il salvataggio
      if (await file.exists()) {
        final content = await file.readAsString();
        final savedJson = jsonDecode(content);
        print('Verified saved settings: ${savedJson['javaPath']}');
      }

      print('Settings saved successfully');
    } catch (e, stack) {
      print('Error saving settings: $e');
      print('Stack trace: $stack');
      rethrow;
    }
  }
}
