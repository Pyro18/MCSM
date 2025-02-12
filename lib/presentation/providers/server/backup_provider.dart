import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/settings.dart';
import '../../../data/datasources/remote/backup_service.dart';
import '../settings/settings_provider.dart';
import '../server/servers_provider.dart';

final backupServiceProvider = Provider<BackupService>((ref) {
  final settingsAsync = ref.watch(settingsProvider);

  return settingsAsync.when(
    data: (settings) => BackupService(
      backupDir: settings.backupSettings.backupPath,
      settings: settings.backupSettings,
    ),
    loading: () => BackupService(
      backupDir: '',
      settings: BackupSettings.defaults(),
    ),
    error: (_, __) => BackupService(
      backupDir: '',
      settings: BackupSettings.defaults(),
    ),
  );
});

final autoBackupProvider = Provider<Timer?>((ref) {
  Timer? backupTimer;

  final settingsAsync = ref.watch(settingsProvider);
  final backupService = ref.watch(backupServiceProvider);
  final serversAsync = ref.watch(serversProvider);

  backupTimer?.cancel();

  settingsAsync.whenData((settings) {
    if (settings.backupSettings.autoBackup) {
      backupTimer = Timer.periodic(
        Duration(hours: settings.backupSettings.frequency),
            (_) async {
          serversAsync.whenData((servers) async {
            for (final server in servers) {
              try {
                await backupService.createServerBackup(server);
              } catch (e) {
                print('Error backing up server ${server.name}: $e');
              }
            }

            if (settings.backupSettings.backupConfigs) {
              try {
                await backupService.createConfigBackup();
              } catch (e) {
                print('Error backing up configurations: $e');
              }
            }
          });
        },
      );
    }
  });

  return backupTimer;
});