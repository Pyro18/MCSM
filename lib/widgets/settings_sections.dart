import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/java_service.dart';

class JavaSettingsSection extends ConsumerStatefulWidget {
  const JavaSettingsSection({super.key});

  @override
  ConsumerState<JavaSettingsSection> createState() => _JavaSettingsState();
}

class _JavaSettingsState extends ConsumerState<JavaSettingsSection> {
  String _javaPath = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _detectJavaPath();
  }

  Future<void> _detectJavaPath() async {
    setState(() => _isSearching = true);
    
    try {
      final javaService = JavaService();
      final installations = await javaService.detectJavaInstallations();
      
      if (installations.isNotEmpty) {
        setState(() {
          _javaPath = installations.first.path;
        });
      }
    } finally {
      setState(() => _isSearching = false);
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                  suffixIcon: _isSearching 
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
      ],
    );
  }
}

class ServerLocationSection extends ConsumerStatefulWidget {
  const ServerLocationSection({super.key});

  @override
  ConsumerState<ServerLocationSection> createState() => _ServerLocationState();
}

class _ServerLocationState extends ConsumerState<ServerLocationSection> {
  String _serverPath = '';

  @override
  void initState() {
    super.initState();
    _setDefaultPath();
  }

  void _setDefaultPath() {
    // Imposta il percorso predefinito basato sul sistema operativo
    final defaultPath = Platform.isWindows
        ? '${Platform.environment['USERPROFILE']}\\AppData\\Roaming\\MCSM\\servers'
        : '${Platform.environment['HOME']}/.mcsm/servers';
    
    setState(() {
      _serverPath = defaultPath;
    });
  }

  Future<void> _selectServerPath() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select Default Server Location',
    );
    
    if (selectedDirectory != null) {
      setState(() {
        _serverPath = selectedDirectory;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                controller: TextEditingController(text: _serverPath),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _selectServerPath,
              icon: const Icon(Icons.folder_open),
              tooltip: 'Select Server Path',
            ),
            IconButton(
              onPressed: _setDefaultPath,
              icon: const Icon(Icons.refresh),
              tooltip: 'Reset to Default',
            ),
          ],
        ),
      ],
    );
  }
}