import 'dart:async';
import 'package:flutter/material.dart';
import 'login.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(
      const Duration(seconds: 3),
      () => Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Image(
            image: AssetImage('lib/assets/bg.png'),
            fit: BoxFit.cover,
          ),
          Center(
            child: Hero(
              tag: 'logoHero',
              flightShuttleBuilder: (
                flightContext,
                animation,
                direction,
                fromContext,
                toContext,
              ) {
                final curvedAnimation = CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut, 
                );

                return FadeTransition(
                  opacity: curvedAnimation,
                  child: const Image(
                    image: AssetImage('lib/assets/logo2Bg.png'),
                    height: 300,
                    width: 300,
                    fit: BoxFit.contain,
                  ),
                );
              },
              child: const Image(
                image: AssetImage('lib/assets/logo2Bg.png'),
                height: 350,
                width: 350,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
