import 'package:aplikasi_makanan/onboarding/onboarding.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:aplikasi_makanan/login.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool _isPasswordVisible = false;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _showAutoDismissDialog(String title, String message,
      IconData icon, Color iconColor, bool isSuccess) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 10),
            Text(title),
          ],
        ),
        content: Text(message),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );

    await Future.delayed(const Duration(seconds: 1));

    if (context.mounted) {
      Navigator.of(context).pop();
      if (isSuccess) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingPage()),
        );
      }
    }
  }

  Future<void> _saveUserDataToPrefs(String email, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', email);
      await prefs.setString('user_password', password);
      print("✅ Data user berhasil disimpan ke SharedPreferences: email=$email");
    } catch (e) {
      print("⚠️ Gagal menyimpan data ke SharedPreferences: $e");
    }
  }

  Future<void> _registerUser() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse('http://10.0.2.2:3000/api/register');
    final body = {
      'email': _emailController.text.trim(),
      'password': _passwordController.text.trim(),
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final statusCode = response.statusCode;
      final responseData = jsonDecode(response.body);

      if (statusCode == 200 || statusCode == 201) {
        print("✅ Registrasi berhasil: ${response.body}");

        String email = _emailController.text.trim();
        String password = _passwordController.text.trim();

        print("Debug: email=$email, password='$password'");

        await _saveUserDataToPrefs(email, password);

        await _showAutoDismissDialog(
          "Berhasil",
          "Registrasi berhasil!",
          Icons.check_circle,
          Colors.green,
          true,
        );
      } else {
        String errorMsg = 'Gagal registrasi';

        if (responseData['message'] != null) {
          errorMsg = responseData['message'];
        } else if (responseData['errors'] != null) {
          errorMsg = responseData['errors'].toString();
        }

        print("❌ Registrasi gagal: $responseData");

        await _showAutoDismissDialog(
          "Gagal",
          errorMsg,
          Icons.error,
          Colors.red,
          false,
        );
      }
    } catch (e) {
      print("❌ Terjadi kesalahan saat registrasi: $e");

      await _showAutoDismissDialog(
        "Kesalahan",
        "Terjadi kesalahan: $e",
        Icons.warning,
        Colors.orange,
        false,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF38E08C),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                height: 250,
                color: const Color(0xFF38E08C),
                child: Center(
                  child: Image.asset(
                    'lib/assets/logo2Bg.png',
                    height: 350,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                height: 550,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 30),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const Text(
                        'Hallo !',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF38E08C),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          prefixIcon:
                              const Icon(Icons.email, color: Colors.black),
                          hintText: 'Email',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Masukkan email';
                          } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                              .hasMatch(value)) {
                            return 'Email tidak valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          prefixIcon:
                              const Icon(Icons.lock, color: Colors.black),
                          hintText: 'Password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Masukkan password';
                          } else if (value.length < 6) {
                            return 'Password minimal 6 karakter';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => const LoginPage(),
                              ),
                            );
                          },
                          child: const Text(
                            'Sudah punya akun?',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  if (_formKey.currentState!.validate()) {
                                    _registerUser();
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF38E08C),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text(
                                  'DAFTAR',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
