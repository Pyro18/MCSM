import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/config_model.dart';
import '../../storage/app_storage.dart';
import 'storage_provider.dart';

class SettingsNotifier extends StateNotifier<AsyncValue<ConfigModel>> {
  final AppStorage _storage;
  
  SettingsNotifier(this._storage) : super(const AsyncValue.loading()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    state = const AsyncValue.loading();
    try {
      final settings = await _storage.loadConfig();
      state = AsyncValue.data(settings);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateSettings(ConfigModel settings) async {
    try {
      await _storage.saveConfig(settings);
      state = AsyncValue.data(settings);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AsyncValue<ConfigModel>>((ref) {
  final storage = ref.watch(appStorageProvider);
  return SettingsNotifier(storage);
});
