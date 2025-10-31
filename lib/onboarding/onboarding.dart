import 'dart:convert';
import 'package:aplikasi_makanan/homepage.dart';
import 'package:aplikasi_makanan/homescreen.dart';
import 'package:aplikasi_makanan/model/user_data.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:aplikasi_makanan/onboarding/widgets/namepage.dart';
import 'package:aplikasi_makanan/onboarding/widgets/genderpage.dart';
import 'package:aplikasi_makanan/onboarding/widgets/birthdaypage.dart';
import 'package:aplikasi_makanan/onboarding/widgets/heightpage.dart';
import 'package:aplikasi_makanan/onboarding/widgets/weightpage.dart';
import 'package:aplikasi_makanan/onboarding/widgets/breakfastpage.dart';
import 'package:aplikasi_makanan/onboarding/widgets/dinner.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _currentPage = 0;
  final int _totalPages = 7;

  UserData userData = UserData(
    name: '',
    gender: '',
    birthday: DateTime.now(),
    height: 0,
    weight: 0,
    breakfastTime: const Duration(hours: 7),
    dinnerTime: const Duration(hours: 19),
  );

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _currentPage = _controller.page?.round() ?? 0;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void nextPage() {
    if (_currentPage < _totalPages - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  String _durationToString(Duration? duration) {
    if (duration == null) return '';
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  Future<void> registerUserAndNavigate() async {
    final url = Uri.parse('http://10.0.2.2:3000/api/register');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nama': userData.name,
          'email': userData.email,
          'password': userData.password,
          'gender': userData.gender,
          'tgl_lahir': userData.birthday?.toIso8601String(),
          'berat_badan': userData.weight,
          'tinggi_badan': userData.height,
          'sarapan': _durationToString(userData.breakfastTime),
          'makan_malam': _durationToString(userData.dinnerTime),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_registered', true);
        await prefs.setString('user_email', userData.email);
        await prefs.setString('user_name', userData.name ?? '');

        if (context.mounted) {
          await showDialog(
            context: context,
            builder: (context) {
              Future.delayed(const Duration(seconds: 2), () {
                if (Navigator.canPop(context)) {
                  Navigator.of(context).pop();
                }
              });

              return const AlertDialog(
                title: Text('Berhasil'),
                content: Text('✅ Pendaftaran berhasil!'),
              );
            },
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Gagal menyimpan data: ${response.body}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Terjadi kesalahan jaringan!'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> updateUserData() async {
    final url = Uri.parse('http://10.0.2.2:3000/api/updateUserdata');

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nama': userData.name,
          'email': userData.email,
          'gender': userData.gender,
          'tgl_lahir': userData.birthday?.toIso8601String(),
          'berat_badan': userData.weight,
          'tinggi_badan': userData.height,
          'sarapan': _durationToString(userData.breakfastTime),
          'makan_malam': _durationToString(userData.dinnerTime),
        }),
      );

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_name', userData.name ?? '');
        await prefs.setString('user_email', userData.email);

        if (context.mounted) {
          await showGeneralDialog(
            context: context,
            // barrierDismissible: false,
            barrierLabel: 'Success',
            transitionDuration: const Duration(milliseconds: 300),
            pageBuilder: (context, animation, secondaryAnimation) {
              Future.delayed(const Duration(seconds: 2), () {
                if (Navigator.canPop(context)) {
                  Navigator.of(context).pop();
                }
              });

              return Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      )
                    ],
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 48),
                      SizedBox(height: 10),
                      Text(
                        'Berhasil!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Data berhasil diperbarui.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              );
            },
            transitionBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutBack,
                  ),
                  child: child,
                ),
              );
            },
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomescreenPage()),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal update data: ${response.body}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Terjadi kesalahan jaringan saat update'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: _currentPage == 0
                        ? null
                        : () {
                            _controller.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                  ),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (_currentPage + 1) / _totalPages,
                      backgroundColor: Colors.grey[300],
                      valueColor:
                          const AlwaysStoppedAnimation(Color(0xFF38E08C)),
                      minHeight: 5,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Text(
                    '${_currentPage + 1}/$_totalPages',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  NamePage(onContinue: (name) {
                    userData.name = name;
                    nextPage();
                  }),
                  GenderPage(onContinue: (gender) async {
                    if (gender.toLowerCase() == 'laki-laki' ||
                        gender.toLowerCase() == 'laki') {
                      userData.gender = 'Laki-laki';
                    } else if (gender.toLowerCase() == 'perempuan') {
                      userData.gender = 'Perempuan';
                    } else {
                      userData.gender = gender;
                    }

                    print('📌 Gender disimpan ke userData: ${userData.gender}');

                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('user_gender', userData.gender ?? '');

                    nextPage();
                  }),
                  BirthdayPage(onContinue: (selectedDate) {
                    userData.birthday = selectedDate;
                    nextPage();
                  }),
                  HeightPage(onContinue: (height) {
                    userData.height = height;
                    nextPage();
                  }),
                  WeightPage(onContinue: (weight) {
                    userData.weight = weight;
                    nextPage();
                  }),
                  BreakfastPage(onContinue: (Duration selectedTime) {
                    userData.breakfastTime = selectedTime;
                    nextPage();
                  }),
                  DinnerPage(
                    onContinue: (Duration selectedTime, String email) async {
                      userData.dinnerTime = selectedTime;
                      userData.email = email;

                      final prefs = await SharedPreferences.getInstance();
                      userData.password =
                          prefs.getString('user_password') ?? '';

                      final isNewUser = !(prefs.containsKey('user_email'));

                      if (isNewUser) {
                        await registerUserAndNavigate();
                        await prefs.setString(
                            'user_email', userData.email ?? '');
                        await prefs.setString('user_name', userData.name ?? '');
                      } else {
                        await updateUserData();
                      }
                    },
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
