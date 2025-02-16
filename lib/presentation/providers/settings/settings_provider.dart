import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/settings.dart';
import '../../../domain/repositories/settings_repository.dart';
import '../../../data/repositories/settings_repository_impl.dart';
import '../../../data/datasources/remote/settings_service.dart';
import '../java/java_provider.dart'; // Importiamo il provider da qui

final settingsServiceProvider = Provider((ref) => SettingsService());

final settingsRepositoryProvider = Provider<ISettingsRepository>((ref) {
  final service = ref.watch(settingsServiceProvider);
  return SettingsRepositoryImpl(service);
});

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, Settings>(SettingsNotifier.new);

class SettingsNotifier extends AsyncNotifier<Settings> {
  @override
  Future<Settings> build() async {
    try {
      final repository = ref.watch(settingsRepositoryProvider);
      final settings = await repository.getSettings();

      // Se la Java path è vuota, esegui l'auto-rilevamento
      if (settings.javaPath.isEmpty) {
        print('Java path is empty, performing auto-detection...');
        try {
          final javaRepo = ref.read(javaRepositoryProvider);
          final installations = await javaRepo.detectJavaInstallations();

          if (installations.isNotEmpty) {
            final defaultInstallation = installations.firstWhere(
                  (inst) => inst.isDefault,
              orElse: () => installations.first,
            );

            print('Found Java installation: ${defaultInstallation.path}');
            await javaRepo.saveJavaInstallations(installations);

            final updatedSettings = settings.copyWith(
              javaPath: defaultInstallation.path,
            );

            await repository.saveSettings(updatedSettings);
            return updatedSettings;
          }
        } catch (e) {
          print('Error during auto-detection: $e');
          // Ritorna le impostazioni originali se l'auto-rilevamento fallisce
          return settings;
        }
      }

      return settings;
    } catch (e, stack) {
      print('Error in build: $e');
      print('Stack trace: $stack');
      rethrow;
    }
  }

  Future<void> updateSettings(Settings settings) async {
    try {
      final repository = ref.read(settingsRepositoryProvider);
      state = const AsyncValue.loading();

      print('Saving settings with Java path: ${settings.javaPath}');
      await repository.saveSettings(settings);

      final updatedSettings = await repository.getSettings();
      print('Verified saved settings - Java path: ${updatedSettings.javaPath}');

      state = AsyncValue.data(settings);
    } catch (e, stack) {
      print('Error updating settings: $e');
      print('Stack trace: $stack');
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> autoDetectJava() async {
    try {
      print('Starting Java auto-detection in settings...');
      state = const AsyncValue.loading();

      final repository = ref.read(settingsRepositoryProvider);
      final currentSettings = await repository.getSettings();
      final javaRepo = ref.read(javaRepositoryProvider);

      final installations = await javaRepo.detectJavaInstallations();
      print('Found ${installations.length} Java installations');

      if (installations.isNotEmpty) {
        final defaultInstallation = installations.firstWhere(
              (inst) => inst.isDefault,
          orElse: () => installations.first,
        );

        print('Selected Java path: ${defaultInstallation.path}');
        await javaRepo.saveJavaInstallations(installations);

        final updatedSettings = currentSettings.copyWith(
          javaPath: defaultInstallation.path,
        );

        await repository.saveSettings(updatedSettings);
        state = AsyncValue.data(updatedSettings);
      } else {
        print('No Java installations found');
        throw Exception('No Java installations found');
      }
    } catch (e, stack) {
      print('Error auto-detecting Java: $e');
      print('Stack trace: $stack');
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}
