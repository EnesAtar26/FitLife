import 'package:flutter/material.dart';
import 'package:flutter_application_6/services/session_manager.dart';
import 'login_screen.dart';
import "package:lottie/lottie.dart";

class OnboardingScreen extends StatefulWidget {
  static const routeName = '/onboarding';
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  final List<Map<String, String>> _pages = [
    {
      'title': 'Aktivitelerini takip et',
      'subtitle':
          'Adımlarını, koşularını ve günlük hareketlerini tek yerden kontrol et',
    },
    {
      'title': 'Sağlığını kontrol altında tut',
      'subtitle':
          'Adım, su ve uyku hedefleri belirle, ilerlemeni her gün takip et',
    },
    {
      'title': 'Hedef koy, ilerlemeyi gör',
      'subtitle':
          'İstatistikleri ve hatırlatıcıları kullanarak sağlıklı bir rutin oluştur',
    },
  ];

  void _next() async {
    if (_page < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      await SessionManager.setOnboardingComplete();
      Navigator.pushReplacementNamed(context, LoginScreen.routeName);
    }
  }

  void _skip() async {
    await SessionManager.setOnboardingComplete();
    Navigator.pushReplacementNamed(context, LoginScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).primaryColor;
    return Scaffold(
      backgroundColor: const Color.fromRGBO(245, 245, 245, 1),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, index) {
                  final p = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 36),
                        Text(
                          'FitLife',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: Center(
                            child: Container(
                              width: 350,
                              height: 448,
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: const Color.fromRGBO(224, 224, 224, 1),
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color.fromRGBO(0, 0, 0, 0.25),
                                    blurRadius: 4,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(26.0),
                                child: Center(
                                  child: ListView(
                                    children: [
                                      _page == 0 ? Lottie.asset("assets/jogging_women.json") :
                                      _page == 1 ? Lottie.asset("assets/glasswater.json") :
                                      Lottie.asset("assets/growthChart.json")
                                    ]
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          p['title']!,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28.0),
                          child: Text(
                            p['subtitle']!,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _pages.length,
                            (i) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            width: 15,
                            height: 15,
                            decoration: BoxDecoration(
                              color: _page == i ? color : color.withValues(alpha:0.18),
                              shape: BoxShape.circle,
                            ),
                            ),
                          ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Column(
                children: [
                  SizedBox(
                    width: 278,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(
                          Theme.of(context).primaryColor,
                        ),
                        foregroundColor: WidgetStateProperty.all(Colors.white),
                        shape: WidgetStatePropertyAll(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        padding: WidgetStatePropertyAll(EdgeInsets.zero),
                      ),
                      child: Text(
                        _page == _pages.length - 1 ? 'BAŞLA' : 'İLERİ',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _skip,
                    child: Text(
                      'ATLA',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
