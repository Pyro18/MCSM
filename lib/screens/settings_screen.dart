import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../services/java_service.dart';
import '../services/providers/settings_notifier.dart';
import '../models/config_model.dart';
import '../models/backup_config.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _javaPath = '';
  String _defaultServerPath = '';
  bool _startMinimized = false;
  bool _closeToTray = true;
  bool _checkUpdatesAutomatically = true;
  String _backupLocation = '';
  bool _autoBackup = true;
  int _backupFrequency = 24;
  bool _isLoading = false;
  bool _isSearchingJava = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
    _detectJavaPath();
  }

  void _loadCurrentSettings() {
    final settingsAsync = ref.read(settingsProvider);
    settingsAsync.whenData((settings) {
      setState(() {
        _javaPath = settings.javaPath;
        _defaultServerPath = settings.serverInstallPath.isNotEmpty
            ? settings.serverInstallPath
            : Platform.isWindows
            ? '${Platform.environment['USERPROFILE']}\\AppData\\Roaming\\MCSM\\servers'
            : '${Platform.environment['HOME']}/.mcsm/servers';
        _backupLocation = settings.backupConfig.backupPath.isNotEmpty
            ? settings.backupConfig.backupPath
            : Platform.isWindows
            ? '${Platform.environment['USERPROFILE']}\\AppData\\Roaming\\MCSM\\backups'
            : '${Platform.environment['HOME']}/.mcsm/backups';
        _autoBackup = settings.backupConfig.autoBackup;
        _backupFrequency = settings.backupConfig.backupFrequency;
        _startMinimized = settings.autoStart;
      });
    });
  }

  void _setDefaultServerPath() {
    final defaultPath = Platform.isWindows
        ? '${Platform.environment['USERPROFILE']}\\AppData\\Roaming\\MCSM\\servers'
        : '${Platform.environment['HOME']}/.mcsm/servers';
    setState(() {
      _defaultServerPath = defaultPath;
    });
    // _saveSettings();
  }

  Future<void> _detectJavaPath() async {
    setState(() => _isSearchingJava = true);
    try {
      final javaService = JavaService();
      final installations = await javaService.detectJavaInstallations();
      if (installations.isNotEmpty) {
        setState(() {
          _javaPath = installations.first.path;
        });
      }
    } finally {
      setState(() => _isSearchingJava = false);
    }
  }

  Future<void> _selectJavaPath() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select Java Executable',
      type: FileType.custom,
      allowedExtensions: ['exe'],
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _javaPath = result.files.first.path ?? '';
      });
    }
  }

  Future<void> _selectDefaultServerPath() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select Default Server Location',
    );

    if (selectedDirectory != null) {
      setState(() {
        _defaultServerPath = selectedDirectory;
      });
    }
  }

  Future<void> _selectBackupLocation() async {
    String? result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select Backup Location',
    );

    if (result != null) {
      setState(() {
        _backupLocation = result;
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);

    try {
      final newConfig = ConfigModel(
        serverInstallPath: _defaultServerPath,
        javaPath: _javaPath,
        autoStart: _startMinimized,
        backupConfig: BackupConfig(
          backupPath: _backupLocation,
          autoBackup: _autoBackup,
          backupFrequency: _backupFrequency,
        ),
      );

      await ref.read(settingsProvider.notifier).updateSettings(newConfig);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);

    return settingsAsync.when(
      data: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with save button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveSettings,
                  child: _isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text('Save Changes'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Settings content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Java Settings
                    const Text(
                      'Java Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Java Path',
                              suffixIcon: _isSearchingJava
                                  ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                                  : null,
                            ),
                            readOnly: true,
                            controller: TextEditingController(text: _javaPath),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _selectJavaPath,
                          icon: const Icon(Icons.folder_open),
                          tooltip: 'Select Java Path',
                        ),
                        IconButton(
                          onPressed: _detectJavaPath,
                          icon: const Icon(Icons.refresh),
                          tooltip: 'Auto Detect Java',
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Server Location
                    const Text(
                      'Server Location',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Default Server Location',
                            ),
                            readOnly: true,
                            controller: TextEditingController(text: _defaultServerPath),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _selectDefaultServerPath,
                          icon: const Icon(Icons.folder_open),
                          tooltip: 'Select Server Path',
                        ),
                        IconButton(
                          onPressed: _setDefaultServerPath,
                          icon: const Icon(Icons.refresh),
                          tooltip: 'Reset to Default',
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Application Settings
                    const Text(
                      'Application Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Start Minimized'),
                      subtitle: const Text('Start the application minimized to system tray'),
                      value: _startMinimized,
                      onChanged: (value) => setState(() => _startMinimized = value),
                    ),
                    SwitchListTile(
                      title: const Text('Close to Tray'),
                      subtitle: const Text('Minimize to system tray when closing the window'),
                      value: _closeToTray,
                      onChanged: (value) => setState(() => _closeToTray = value),
                    ),
                    SwitchListTile(
                      title: const Text('Check Updates Automatically'),
                      subtitle: const Text('Automatically check for application updates'),
                      value: _checkUpdatesAutomatically,
                      onChanged: (value) => setState(() => _checkUpdatesAutomatically = value),
                    ),
                    const SizedBox(height: 32),

                    // Backup Settings
                    const Text(
                      'Backup Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Backup Location',
                            ),
                            readOnly: true,
                            controller: TextEditingController(text: _backupLocation),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _selectBackupLocation,
                          icon: const Icon(Icons.folder_open),
                          tooltip: 'Select Backup Location',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Automatic Backups'),
                      subtitle: const Text('Enable automatic server backups'),
                      value: _autoBackup,
                      onChanged: (value) => setState(() => _autoBackup = value),
                    ),
                    if (_autoBackup) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Backup Frequency (hours)',
                                suffixText: 'hours',
                              ),
                              keyboardType: TextInputType.number,
                              initialValue: _backupFrequency.toString(),
                              onChanged: (value) {
                                setState(() {
                                  _backupFrequency = int.tryParse(value) ?? 24;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}