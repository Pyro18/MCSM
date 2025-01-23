// lib/main.dart
import 'package:flutter/material.dart';
import 'package:mcsm/services/storage/storage_config.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'services/storage/app_storage.dart';
import 'services/providers/storage_provider.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Inizializza lo storage prima di tutto
    print('Initializing storage...'); // Debug log
    final storage = AppStorage();
    await storage.init();

    print('Storage paths:'); // Debug log
    print('Root path: ${StorageConfig.rootPath}');
    print('Data path: ${StorageConfig.dataPath}');
    print('Server path: ${StorageConfig.defaultServerPath}');
    print('Config path: ${StorageConfig.configPath}');
    print('Servers file: ${StorageConfig.serversPath}');

    // Inizializza window manager
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1200, 800),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      title: 'MCSM - Minecraft Server Manager',
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });

    runApp(
      ProviderScope(
        overrides: [
          appStorageProvider.overrideWithValue(storage),
        ],
        child: const MCSMApp(),
      ),
    );
  } catch (e, stack) {
    print('Error in main: $e');
    print('Stack trace: $stack');
    rethrow;
  }
}

class MCSMApp extends StatelessWidget {
  const MCSMApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MCSM',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
      // Aggiungiamo una direzione esplicita per il testo
      locale: const Locale('en'),
      localizationsDelegates: const [
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
    );
  }
}