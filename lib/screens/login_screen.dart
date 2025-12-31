import 'package:flutter/material.dart';
import 'signup_screen.dart';
import 'home_screen.dart';
import '../services/auth_service.dart';

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

  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final user = await _authService.login(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );

    setState(() => _isLoading = false);

    if (user == null) {
      setState(() => _error = 'E-posta veya şifre hatalı');
      return;
    }

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
                            onPressed: _isLoading ? null : _login,
                            style: ButtonStyle(
                              backgroundColor: WidgetStatePropertyAll(color),
                              foregroundColor: const WidgetStatePropertyAll(Colors.white),
                              shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              minimumSize: const WidgetStatePropertyAll(Size.fromHeight(50)),
                              elevation: const WidgetStatePropertyAll(2),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                color: Colors.white)
                                : const Text(
                              'GİRİŞ YAP',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
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
                          )
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
