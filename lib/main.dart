import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Eklendi
import "package:flutter_dotenv/flutter_dotenv.dart";

// Ekranlar
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/water_screen.dart';
import 'screens/activity_detail_screen.dart';
import 'screens/sleep_tracker_screen.dart';
import 'screens/profile_screen.dart';
import 'services/session_manager.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await dotenv.load(fileName:".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // --- BAŞLANGIÇ EKRANINI SEÇEN FONKSİYON ---
  Future<Widget> _getStartScreen() async {
    // 1. Firebase (Online) Giriş Kontrolü
    if (FirebaseAuth.instance.currentUser != null) {
      return const HomeScreen(isOffline: false);
    }

    // 2. Onboarding Tamamlanmış mı? (Offline)
    // SessionManager'a eklediğimiz fonksiyonu burada kullanıyoruz
    bool onboardingDone = await SessionManager.isOnboardingComplete();
    if (onboardingDone) {
      return const HomeScreen(isOffline: true);
    }

    // 3. Hiçbiri yoksa Onboarding'i aç
    return const OnboardingScreen();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitLife',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromRGBO(76, 175, 80, 1)),
        primaryColor: const Color.fromRGBO(76, 175, 80, 1),
        shadowColor: const Color.fromRGBO(132, 173, 133, 1),
        scaffoldBackgroundColor: const Color.fromRGBO(248, 248, 248, 1),
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: Color.fromRGBO(33, 33, 33, 1), fontFamily: "Roboto"),
          titleMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color.fromRGBO(117, 117, 117, 1), fontFamily: "Roboto"),
          bodyLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Color.fromRGBO(33, 33, 33, 1), fontFamily: "Roboto"),
          bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color.fromRGBO(117, 117, 117, 1), fontFamily: "Roboto"),
          bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color.fromRGBO(117, 117, 117, 1), fontFamily: "Roboto"),
        ),
      ),
      // FutureBuilder ile karar veriyoruz
      home: FutureBuilder<Widget>(
        future: _getStartScreen(),
        builder: (context, snapshot) {
          // Veri gelene kadar loading göster
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          // Veri gelince (Widget) ekrana bas
          return snapshot.data ?? const OnboardingScreen();
        },
      ),
      routes: {
        LoginScreen.routeName: (_) => const LoginScreen(),
        SignupScreen.routeName: (_) => const SignupScreen(),
        HomeScreen.routeName: (_) => const HomeScreen(),
        WaterScreen.routeName: (_) => const WaterScreen(),
        ActivityDetailScreen.routeName: (_) => const ActivityDetailScreen(),
        SleepTrackerScreen.routeName: (_) => const SleepTrackerScreen(),
        ProfileScreen.routeName: (_) => const ProfileScreen(),
      },
    );
  }
}