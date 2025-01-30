import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'screens/home_screen.dart';
import 'services/settings_service.dart';
import 'theme/app_theme.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    final settingsService = SettingsService();
    await settingsService.init();

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
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          debugShowCheckedModeBanner: false,
          home: MCSMApp(navigatorKey: navigatorKey),
        )
      ),
    );
  } catch (e, stack) {
    print('Error in main: $e');
    print('Stack trace: $stack');
    rethrow;
  }
}

class MCSMApp extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const MCSMApp({super.key, required this.navigatorKey});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
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
