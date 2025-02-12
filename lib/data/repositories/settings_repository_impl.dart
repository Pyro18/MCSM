import '../../domain/repositories/settings_repository.dart';
import '../../domain/entities/settings.dart';
import '../datasources/remote/settings_service.dart';

class SettingsRepositoryImpl implements ISettingsRepository {
  final SettingsService _settingsService;

  SettingsRepositoryImpl(this._settingsService);

  @override
  Future<void> init() => _settingsService.init();

  @override
  Future<Settings> getSettings() => _settingsService.loadSettings();

  @override
  Future<void> saveSettings(Settings settings) =>
      _settingsService.saveSettings(settings);

  @override
  Future<Settings> loadDefaults() => Future.value(Settings.defaults());

  @override
  Future<String> get configPath => Future.value(_settingsService.configPath);
}