import 'package:flutter/material.dart';

import 'mainScreen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E6B4F),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.fitness_center, size: 85, color: Colors.white),

            const SizedBox(height: 20),

            const Text(
              'Student FitTrack',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 188, 234, 201),
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Stay active, even with a busy schedule',
              style: TextStyle(fontSize: 15, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
