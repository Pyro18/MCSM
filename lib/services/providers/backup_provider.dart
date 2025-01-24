import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:mcsm/services/providers/settings_provider.dart';
import 'package:mcsm/services/providers/servers_provider.dart';
import '../../models/settings_model.dart';
import '../backup_service.dart';

final backupServiceProvider = Provider((ref) {
  final settings = ref.watch(settingsProvider).value;
  return BackupService(
    backupDir: settings?.backupSettings.backupPath ?? '',
    settings: settings?.backupSettings ?? BackupSettings.defaults(),
  );
});

final autoBackupProvider = Provider((ref) {
  Timer? backupTimer;
  final settings = ref.watch(settingsProvider).value;
  final backupService = ref.watch(backupServiceProvider);
  final serversAsync = ref.watch(serversProvider);

  backupTimer?.cancel();

  if (settings?.backupSettings.autoBackup ?? false) {
    backupTimer = Timer.periodic(
      Duration(hours: settings?.backupSettings.frequency ?? 24),
          (_) async {
        final servers = await serversAsync.value ?? [];
        for (final server in servers) {
          try {
            await backupService.createServerBackup(server);
          } catch (e) {
            print('Error backing up server ${server.name}: $e');
          }
        }

        if (settings?.backupSettings.backupConfigs ?? false) {
          try {
            await backupService.createConfigBackup();
          } catch (e) {
            print('Error backing up configurations: $e');
          }
        }
      },
    );
  }

  return backupTimer;
});