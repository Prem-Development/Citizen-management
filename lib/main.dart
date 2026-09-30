import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/citizen_provider.dart';
import 'providers/column_provider.dart';
import 'providers/family_member_provider.dart';
import 'providers/profile_provider.dart';
import 'utils/app_theme.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GSApp());
}

class GSApp extends StatelessWidget {
  const GSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProfileProvider()..loadProfile()),
        ChangeNotifierProvider(create: (_) => CitizenProvider()..loadCitizens()),
        ChangeNotifierProvider(create: (_) => ColumnProvider()..loadColumns()),
        ChangeNotifierProvider(create: (_) => FamilyMemberProvider()),
      ],
      child: MaterialApp(
        title: 'GS Citizen Manager',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
