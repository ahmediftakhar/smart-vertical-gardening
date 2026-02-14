import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateAfterDelay();
    });
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(seconds: 2));
    final prefs = await SharedPreferences.getInstance();
    final savedMac = prefs.getString('mac_address');

    if (!mounted) return;

    Navigator.pushReplacementNamed(
      context,
      (savedMac != null && savedMac.isNotEmpty) ? '/home' : '/register',
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF006400), // Dark green
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SplashImage(),
              SizedBox(height: 24),
              Text(
                'Smart Vertical Gardening',
                key: Key('splashTitle'),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SplashImage extends StatelessWidget {
  const _SplashImage();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/splash.png',
      width: 150,
      key: const Key('splashImage'),
      errorBuilder: (context, error, stackTrace) => const Column(
        children: [
          Icon(Icons.image_not_supported, size: 80, color: Colors.white),
          SizedBox(height: 12),
          Text( 
            'Image not found',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}


