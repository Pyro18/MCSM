import 'package:flutter/material.dart';
import 'package:mcsm/services/providers/settings_provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'services/settings_service.dart';


void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Inizializza il servizio delle impostazioni
    final settingsService = SettingsService();
    await settingsService.init();

    // Debug log delle impostazioni iniziali
    final settings = await settingsService.loadSettings();
    print('Settings loaded:');
    print('Server path: ${settings.serverPath}');
    print('Java path: ${settings.javaPath}');
    print('Backup path: ${settings.backupSettings.backupPath}');

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
          // Override del provider del servizio impostazioni
          settingsServiceProvider.overrideWithValue(settingsService),
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
      locale: const Locale('en'),
      localizationsDelegates: const [
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
    );
  }
}