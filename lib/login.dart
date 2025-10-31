import 'package:aplikasi_makanan/login2.dart';
import 'package:aplikasi_makanan/register.dart';
import 'package:flutter/material.dart';
import 'homepage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Hero(
                    tag: 'logoHero',
                    flightShuttleBuilder:
                        (flightContext, animation, direction, fromContext, toContext) {
                      return FadeTransition(
                        opacity: animation,
                        child: const Image(
                          image: AssetImage('lib/assets/logo2Bg.png'),
                          width: 300,
                          height: 300,
                          fit: BoxFit.contain,
                        ),
                      );
                    },
                    child: const Image(
                      image: AssetImage('lib/assets/logo2Bg.png'),
                      width: 300,
                      height: 300,
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 5,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginUserPage()),
                        );
                      },
                      child: const Text(
                        'Saya sudah memiliki akun',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(height: 1, width: 100, color: Colors.white),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text('ATAU', style: TextStyle(color: Colors.white)),
                      ),
                      Container(height: 1, width: 100, color: Colors.white),
                    ],
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 5,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegisterPage()),
                        );
                      },
                      child: const Text(
                        'Saya adalah pengguna baru',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
