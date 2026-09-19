import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/services/storage_service.dart';
import 'core/providers/app_state_provider.dart';
import 'features/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation de la persistance locale ultra-rapide Hive
  await StorageService.init();

  runApp(const SawkiEnglishApp());
}

class SawkiEnglishApp extends StatelessWidget {
  const SawkiEnglishApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AppStateProvider()..init(),
        ),
      ],
      child: Consumer<AppStateProvider>(
        builder: (context, provider, _) {
          return MaterialApp(
            title: 'Sawki English',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: provider.themeMode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
