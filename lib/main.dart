import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'theme/theme.dart';
import 'screens/main_screen.dart';
import 'services/incident_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables (.env) — API keys are stored here
  await dotenv.load(fileName: '.env');
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => IncidentProvider()),
      ],
      child: MaterialApp(
        title: 'RouteGuardian',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: AppTheme.neonGreen,
          scaffoldBackgroundColor: AppTheme.backgroundDark,
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.neonGreen,
            secondary: AppTheme.accentBlue,
          ),
          textTheme: GoogleFonts.robotoTextTheme(ThemeData.dark().textTheme),
          useMaterial3: true,
        ),
        // Skip auth - go straight to main screen for testing
        home: const MainScreen(),
      ),
    );
  }
}
