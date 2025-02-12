import '../entities/settings.dart';

abstract class ISettingsRepository {
  Future<void> init();

  Future<Settings> getSettings();

  Future<void> saveSettings(Settings settings);

  Future<Settings> loadDefaults();

  Future<String> get configPath;
}
