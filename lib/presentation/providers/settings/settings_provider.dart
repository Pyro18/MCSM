import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/settings.dart';
import '../../../data/datasources/remote/settings_service.dart';

final settingsServiceProvider = Provider((ref) => SettingsService());

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, Settings>(SettingsNotifier.new);

class SettingsNotifier extends AsyncNotifier<Settings> {
  @override
  Future<Settings> build() async {
    final service = ref.watch(settingsServiceProvider);
    return service.loadSettings();
  }

  Future<void> updateSettings(Settings settings) async {
    final service = ref.read(settingsServiceProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await service.saveSettings(settings);
      return settings;
    });
  }
}
