import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _javaPath = '';
  String _defaultServerPath = '';
  bool _startMinimized = false;
  bool _closeToTray = true;
  bool _checkUpdatesAutomatically = true;
  String _backupLocation = '';
  bool _autoBackup = true;
  int _backupFrequency = 24; // hours
  bool _isLoading = false;

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
    String? result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select Default Server Location',
    );

    if (result != null) {
      setState(() {
        _defaultServerPath = result;
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
      // TODO: Implementare il salvataggio delle impostazioni
      await Future.delayed(const Duration(seconds: 1)); // Simulazione
      
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

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                  _buildSection(
                    'Java Settings',
                    [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Java Path',
                              ),
                              readOnly: true,
                              controller: TextEditingController(text: _javaPath),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _selectJavaPath,
                            icon: const Icon(Icons.folder_open),
                          ),
                        ],
                      ),
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
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Application Settings
                  _buildSection(
                    'Application Settings',
                    [
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
                    ],
                  ),

                  // Backup Settings
                  _buildSection(
                    'Backup Settings',
                    [
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}