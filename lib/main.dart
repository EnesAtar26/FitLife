import 'package:flutter/material.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/water_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitLife',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color.fromRGBO(76, 175, 80, 1)),
        primaryColor: Color.fromRGBO(76, 175, 80, 1),
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: Color.fromRGBO(33, 33, 33, 1),fontFamily: "Roboto"),
          titleMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color.fromRGBO(117, 117, 117, 1), fontFamily: "Roboto"),
          bodyLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Color.fromRGBO(33, 33, 33, 1),fontFamily: "Roboto"),
          bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color.fromRGBO(117, 117, 117, 1), fontFamily: "Roboto"),
          bodySmall: TextStyle(fontFamily: "Roboto"),
        ),
      ),
      initialRoute: OnboardingScreen.routeName,
      routes: {
        OnboardingScreen.routeName: (_) => const OnboardingScreen(),
        LoginScreen.routeName: (_) => const LoginScreen(),
        SignupScreen.routeName: (_) => const SignupScreen(),
        HomeScreen.routeName: (_) => const HomeScreen(),
        WaterScreen.routeName: (_) => const WaterScreen(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
