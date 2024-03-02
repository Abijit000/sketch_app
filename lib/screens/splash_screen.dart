import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:sketch_app/screens/sketch_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {

    const colorizeColors = [
      Colors.purple,
      Colors.purpleAccent,
      Colors.blue,
      Colors.lightBlueAccent,
    ];

    return Scaffold(
      body: Container(
          height: double.maxFinite,
          width: double.maxFinite,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            image: DecorationImage(
                image: AssetImage("assets/image/splash_screen_background.jpg"),
                fit: BoxFit.fill),
          ),
          child: SizedBox(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AnimatedTextKit(
                  animatedTexts: [
                    TyperAnimatedText('    ',speed: const Duration(milliseconds: 100),textStyle: const TextStyle(
                      fontSize: 70.0,
                      fontFamily: "Agne",
                    )),TyperAnimatedText('Sketch App',speed: const Duration(milliseconds: 100),textStyle: const TextStyle(
                      fontSize: 70.0,
                      fontFamily: "Agne",
                    )),
                  ],
                  isRepeatingAnimation: false,
                  onFinished: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SketchPage(),
                      ),
                    );
                  },
                ),
                AnimatedTextKit(
                  animatedTexts: [
                    ColorizeAnimatedText(
                      'Unleash Your Creativity, One Stroke at a Time',
                      textStyle: const TextStyle(
                        fontSize: 30.0,
                        fontFamily: 'Horizon',
                      ),
                      colors: colorizeColors,
                    ),
                  ],
                  isRepeatingAnimation: false,
                ),
              ],
            ),
          )
      ),
    );
  }
}
