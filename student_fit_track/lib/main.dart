import 'package:flutter/material.dart';

import 'splashScreen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StudentFitTrack());
}

class StudentFitTrack extends StatelessWidget {
  const StudentFitTrack({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Student FitTrack',

      theme: ThemeData(
        scaffoldBackgroundColor: const Color.fromARGB(255, 251, 255, 254),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 4, 81, 27),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(255, 195, 241, 202),
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        useMaterial3: true,
      ),

      home: const SplashScreen(),
    );
  }
}
