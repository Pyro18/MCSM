import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/config_model.dart';
import '../models/backup_config.dart';

class BackupSettingsSection extends ConsumerStatefulWidget {
  final BackupConfig initialConfig;
  final Function(BackupConfig) onConfigChanged;

  const BackupSettingsSection({
    super.key,
    required this.initialConfig,
    required this.onConfigChanged,
  });

  @override
  ConsumerState<BackupSettingsSection> createState() => _BackupSettingsSectionState();
}

class _BackupSettingsSectionState extends ConsumerState<BackupSettingsSection> {
  late String _backupPath;
  late bool _autoBackup;
  late int _backupFrequency;
  late int _maxBackups;

  @override
  void initState() {
    super.initState();
    _backupPath = widget.initialConfig.backupPath;
    _autoBackup = widget.initialConfig.autoBackup;
    _backupFrequency = widget.initialConfig.backupFrequency;
    _maxBackups = widget.initialConfig.maxBackups;
  }

  Future<void> _selectBackupPath() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select Backup Location',
    );

    if (selectedDirectory != null) {
      setState(() {
        _backupPath = selectedDirectory;
      });
      _updateConfig();
    }
  }

  void _updateConfig() {
    widget.onConfigChanged(BackupConfig(
      backupPath: _backupPath,
      autoBackup: _autoBackup,
      backupFrequency: _backupFrequency,
      maxBackups: _maxBackups,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                controller: TextEditingController(text: _backupPath),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _selectBackupPath,
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
          onChanged: (value) {
            setState(() {
              _autoBackup = value;
            });
            _updateConfig();
          },
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
                    _updateConfig();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Max Backups',
                    suffixText: 'backups',
                  ),
                  keyboardType: TextInputType.number,
                  initialValue: _maxBackups.toString(),
                  onChanged: (value) {
                    setState(() {
                      _maxBackups = int.tryParse(value) ?? 5;
                    });
                    _updateConfig();
                  },
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}