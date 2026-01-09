import 'package:flutter/material.dart';
import 'signup_screen.dart';
import 'home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Services/auth.dart';
import 'Services/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  final _auth = AuthService();

  bool loading = false;
  bool hidePassword = true;

  // ---------- Layer 1: Local Validation ----------

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Email is required";
    }

    final regex =
    RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    if (!regex.hasMatch(value.trim())) {
      return "Enter a valid email address";
    }

    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Password is required";
    }

    if (value.length < 6) {
      return "Password must be at least 6 characters";
    }

    return null;
  }

  // ---------- Submit (Layer 1 + Layer 2) ----------

  Future<void> submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );
      final user = credential.user;
      if (user != null && !user.emailVerified) {
        await FirebaseAuth.instance.signOut();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'E-postanızı doğrulamadan giriş yapamazsınız',
            ),
          ),
        );
      }
      else
      {
        /*
        final uid = FirebaseAuth.instance.currentUser!.uid;

        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();

        if (doc.exists) {
          // ✅ Kullanıcının datası var
        } else {
          // ❌ Henüz kayıtlı değil
        }
        */
        Navigator.pushReplacementNamed(context, HomeScreen.routeName);
      }
    } on FirebaseAuthException catch (e) {
      final message = switch (e.code) {
        'user-not-found' ||
        'wrong-password' ||
        'invalid-credential' ||
        'invalid_login_credentials' =>
        'E-posta veya şifre hatalı',

        'email-already-in-use' =>
        'Bu e-posta zaten kayıtlı',

        'invalid-email' =>
        'Geçersiz e-posta formatı',

        'weak-password' =>
        'Şifre çok zayıf',

        'too-many-requests' =>
        'Çok fazla deneme yapıldı. Lütfen bekleyin.',

        _ =>
        'Giriş başarısız. Lütfen tekrar deneyin.'
      };

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Beklenmeyen bir hata oluştu!")),
      );
    }

    setState(() => loading = false);
  }


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

  void _loginGuest() {
      Navigator.pushReplacementNamed(context, HomeScreen.routeName);
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
                      autovalidateMode: AutovalidateMode.onUserInteraction,
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
                            validator: validateEmail
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
                            validator: validatePassword
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
                          const SizedBox(height: 1),
                          TextButton(onPressed: () {}, child: Text('Şifremi unuttum', style: TextStyle(color: color))),
                          const SizedBox(height: 1),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Hesabın yok mu?'),
                              TextButton(
                                onPressed: () async {
                                  final result = await Navigator.pushNamed(
                                    context,
                                    SignupScreen.routeName,
                                  );

                                  if (result == 'verify') {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Doğrulama maili gönderildi. Lütfen e-postanızı kontrol edin.'),
                                      ),
                                    );
                                  }
                                },
                                child: Text('Kayıt ol', style: TextStyle(color: color, fontWeight: FontWeight.w700)),
                              )
                            ],
                          ),
                          const SizedBox(height: 1),
                          TextButton(
                              onPressed: _loginGuest,
                              child: Text('Misafir olarak devam et', style: TextStyle(color: color))
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
