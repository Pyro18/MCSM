import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../models/settings_model.dart';

class SettingsService {
  final String configPath;

  SettingsService(): configPath = Platform.isWindows
      ? path.join(Platform.environment['APPDATA']!, 'MCSM', 'config.json')
      : path.join(Platform.environment['HOME']!, '.mcsm', 'config.json');

  Future<void> init() async {
    final dir = Directory(path.dirname(configPath));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

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
          JsonEncoder.withIndent('  ').convert(settings.toJson())
      );
    } catch (e, stack) {
      print('Error saving settings: $e\n$stack');
      rethrow;
    }
  }
}