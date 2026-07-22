import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/theme/nebah_theme.dart';
import 'screens/main_screen.dart';
import 'services/incident_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables (.env)
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('⚠️ Could not load .env file: $e');
  }
  
  runApp(
    const ProviderScope(
      child: NebahApp(),
    ),
  );
}

class NebahApp extends StatelessWidget {
  const NebahApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return legacy_provider.MultiProvider(
      providers: [
        legacy_provider.ChangeNotifierProvider(create: (_) => IncidentProvider()),
      ],
      child: MaterialApp(
        title: 'Nebah',
        debugShowCheckedModeBanner: false,
        theme: NebahTheme.lightTheme,
        darkTheme: NebahTheme.darkTheme,
        themeMode: ThemeMode.dark, // Default to dark mode for security-tech look
        home: const MainScreen(),
      ),
    );
  }
}
