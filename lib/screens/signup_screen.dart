import 'package:flutter/material.dart';
import 'Services/firebase_dataBase.dart';
import 'home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Services/firebase_authService.dart';

class SignupScreen extends StatefulWidget {
  static const routeName = '/signup';
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
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
      final userCredential =
      await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _pass.text.trim(),
      );

      final user = userCredential.user;

      if (user != null && !user.emailVerified) {
        final user_id = FirebaseAuth.instance.currentUser!.uid;
        await FirebaseDatabaseService(uid: user_id).updateUserData(_firstName.text, 18, true);
        await user.sendEmailVerification();
        Navigator.pop(context, "verify");
      }
      else
      {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Beklenmeyen bir hata oluştu!")));
      }

      // kullanıcıyı çıkart
      await FirebaseAuth.instance.signOut();

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



  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  void signUp() {
    if (_formKey.currentState?.validate() ?? false) {
      submit();
    }

    Navigator.pushReplacementNamed(context, HomeScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(title: const Text('Kayıt ol'), backgroundColor: color),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _firstName,
                      decoration: InputDecoration(
                        labelText: 'Ad',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Ad girin' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _lastName,
                      decoration: InputDecoration(
                        labelText: 'Soyad',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Soyad girin' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _email,
                      decoration: InputDecoration(
                        labelText: 'E-posta',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: validateEmail
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _pass,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Şifre',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: validatePassword
                    ),
                    const SizedBox(height: 12),

                    if (_error != null) ...[
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 10),
                    ],

                    const SizedBox(height: 6),
                    ElevatedButton(
                      onPressed: _isLoading ? null : submit,
                      style: ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(color),
                        foregroundColor: const WidgetStatePropertyAll(Colors.white),
                        minimumSize: const WidgetStatePropertyAll(Size.fromHeight(48)),
                        shape: WidgetStatePropertyAll(
                          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Kayıt ol'),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
