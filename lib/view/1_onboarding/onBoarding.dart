import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnBoardingScreen extends StatefulWidget {
  const OnBoardingScreen({super.key});
  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> {
  final _controller = PageController();
  int _index = 0;

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', true);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/userHome');
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildPage('assets/images/onBoarding/shop.jpg', 'سجّل محلك في برونزيني وخلي اسمك ينتشر بين الناس السوق تغير \n خليك في المقدمة.'),
      _buildPage('assets/images/onBoarding/mech.jpg', 'حلقة وصل بينك و بين التاجر'),
      _buildPage('assets/images/onBoarding/user.jpg', 'راحتكم .. هدفنا'),
    ];


    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E3), // بيج
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _index = i),
                itemCount: pages.length,
                itemBuilder: (_, i) => pages[i],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages.length,
                    (i) => Container(
                  margin: const EdgeInsets.all(4),
                  width : 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _index
                        ? const Color(0xFF795548) // بني غامق
                        : Colors.grey.shade400,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFF795548),
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 12),
              ),
              onPressed: _index == pages.length - 1
                  ? _finish
                  : () => _controller.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
              child: Text(_index == pages.length - 1 ? 'ابدأ' : 'التالي'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(String asset, String text) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Image.asset(asset, height: 260),
      const SizedBox(height: 40),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4E342E), // بني داكن
          ),
        ),
      ),
    ],
  );
}
