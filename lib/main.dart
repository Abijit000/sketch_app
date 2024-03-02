import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sketch_app/screens/sketch_page.dart';
import 'package:sketch_app/screens/splash_screen.dart';

void main() {
  runApp(const MyApp());
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeRight,
    DeviceOrientation.landscapeLeft,
  ]);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sketch App',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: false),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
