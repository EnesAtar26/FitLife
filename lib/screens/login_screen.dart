import 'package:flutter/material.dart';
import 'package:flutter_application_6/screens/offline_setup_screen.dart';
import 'package:flutter_application_6/services/user_data_service.dart';
import 'signup_screen.dart';
import 'home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_authService.dart';
import '../database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_6/services/session_manager.dart';

class LoginScreen extends StatefulWidget {
  static const routeName = '/login';
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState?.validate() ?? false) {
      // For demo purposes we just go to Home
      submit();
    }
  }

  void _loginGuest() async {
      // Misafir olduğunu kaydet (örneğin ID'yi -1 yapalım)
      await SessionManager.saveUserId(-1); 
      if(mounted) {
         Navigator.pushReplacementNamed(context, HomeScreen.routeName);
      }
  }

  void _loginOffline() async {
    setState(() => loading = true);
    
    // 1. Session Manager'a misafir olduğunu bildir (-1 gibi bir ID ile)
    // Eğer SessionManager kullanıyorsanız:
    await SessionManager.saveUserId(-1); 

    // 2. Profil kontrolü yap
    final userDataService = UserDataService();
    bool hasProfile = await userDataService.hasOfflineProfile();

    if (!mounted) return;
    setState(() => loading = false);

    if (hasProfile) {
      // Profil var, direkt ana ekrana
      Navigator.pushReplacementNamed(context, HomeScreen.routeName);
    } else {
      // Profil yok, kurulum ekranına
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OfflineSetupScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: const Color.fromRGBO(245, 245, 245, 1),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            child: Column(
              children: [
                Text('FitLife', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.grey[900])),
                const SizedBox(height: 8),
                Text('Günlük aktivitelerini kolayca takip et.', textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 20),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _emailCtrl,
                            decoration: InputDecoration(
                              labelText: 'E-posta',
                              labelStyle: const TextStyle(
                              fontSize: 20,
                              color: Colors.grey,
                              ),
                              border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.grey),
                              gapPadding: 0, // kenar boşluğunu azaltır
                              ),
                              enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.grey),
                              gapPadding: 0,
                              ),
                              focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1),
                              gapPadding: 0,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // içeriği kenara yaklaştırır
                            ),
                            validator: (v) => (v == null || v.isEmpty) ? 'E-posta girin' : null,
                          ),
                          const SizedBox(height: 12),
                            TextFormField(
                            controller: _passCtrl,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'Şifre',
                              labelStyle: const TextStyle(
                              fontSize: 20,
                              color: Colors.grey,
                              ),
                              border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.grey),
                              gapPadding: 0,
                              ),
                              enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.grey),
                              gapPadding: 0,
                              ),
                              focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1),
                              gapPadding: 0,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            validator: (v) => (v == null || v.isEmpty) ? 'Şifre girin' : null,
                            ),
                          const SizedBox(height: 18),
                          ElevatedButton(
                            onPressed: _login,
                            style: ButtonStyle(
                              backgroundColor: WidgetStatePropertyAll(color),
                              foregroundColor: const WidgetStatePropertyAll(Colors.white),
                              shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              minimumSize: const WidgetStatePropertyAll(Size.fromHeight(50)),
                              elevation: const WidgetStatePropertyAll(2),
                            ),
                            child: const Text('GİRİŞ YAP', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 8),
                          TextButton(onPressed: () {}, child: Text('Şifremi unuttum', style: TextStyle(color: color))),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Hesabın yok mu?'),
                              TextButton(
                                onPressed: () => Navigator.pushNamed(context, SignupScreen.routeName),
                                child: Text('Kayıt ol', style: TextStyle(color: color, fontWeight: FontWeight.w700)),
                              )
                            ],
                          ),
                          const SizedBox(height: 1),
                          TextButton(
                              onPressed: _loginOffline,
                              child: Text('Çevrimdışı olarak devam et', style: TextStyle(color: color))
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
