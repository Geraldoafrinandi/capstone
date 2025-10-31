// import 'package:aplikasi_makanan/homepage.dart';
// import 'package:aplikasi_makanan/homescreen.dart';
// import 'package:flutter/material.dart';
// import 'package:aplikasi_makanan/utils/shared_prefs.dart';

// class LoginUserPage extends StatefulWidget {
//   const LoginUserPage({super.key});

//   @override
//   State<LoginUserPage> createState() => _LoginUserPageState();
// }

// class _LoginUserPageState extends State<LoginUserPage> {
//   bool _isPasswordVisible = false;
//   final _formKey = GlobalKey<FormState>();
//   final _usernameController = TextEditingController();
//   final _passwordController = TextEditingController();

//   @override
//   void dispose() {
//     _usernameController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }

//   Future<void> _showLoginDialog() async {
//     showDialog<void>(
//       context: context,
//       barrierDismissible: false,
//       builder: (_) => AlertDialog(
//         title: const Row(
//           children:  [
//             Icon(Icons.check_circle, color: Colors.green),
//             SizedBox(width: 10),
//             Text('Berhasil'),
//           ],
//         ),
//         content: const Text('Login berhasil!'),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//       ),
//     );

//     await Future.delayed(const Duration(seconds: 1));

//     if (context.mounted) {
//      Navigator.of(context).pushReplacement(
//         MaterialPageRoute(builder: (context) => const HomescreenPage()),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF38E08C),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           child: Column(
//             children: [
//               Container(
//                 width: double.infinity,
//                 height: 250,
//                 color: const Color(0xFF38E08C),
//                 child: Center(
//                   child: Image.asset(
//                     'lib/assets/logo2Bg.png',
//                     height: 350,
//                     fit: BoxFit.contain,
//                   ),
//                 ),
//               ),
//               Container(
//                 width: double.infinity,
//                 height: 550,
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
//                 decoration: const BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
//                 ),
//                 child: Form(
//                   key: _formKey,
//                   child: Column(
//                     children: [
//                       const Text(
//                         'Hallo !',
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                             fontSize: 32,
//                             fontWeight: FontWeight.bold,
//                             color: Color(0xFF38E08C)),
//                       ),
//                       const SizedBox(height: 40),
//                       TextFormField(
//                         controller: _usernameController,
//                         decoration: InputDecoration(
//                           prefixIcon:
//                               const Icon(Icons.person, color: Colors.black),
//                           hintText: 'Nama atau Email',
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                         validator: (value) {
//                           if (value == null || value.isEmpty) {
//                             return 'Masukkan nama atau email';
//                           }
//                           return null;
//                         },
//                       ),
//                       const SizedBox(height: 20),
//                       TextFormField(
//                         controller: _passwordController,
//                         obscureText: !_isPasswordVisible,
//                         decoration: InputDecoration(
//                           prefixIcon:
//                               const Icon(Icons.lock, color: Colors.black),
//                           hintText: 'Password',
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           suffixIcon: IconButton(
//                             icon: Icon(
//                               _isPasswordVisible
//                                   ? Icons.visibility
//                                   : Icons.visibility_off,
//                               color: Colors.grey,
//                             ),
//                             onPressed: () {
//                               setState(() {
//                                 _isPasswordVisible = !_isPasswordVisible;
//                               });
//                             },
//                           ),
//                         ),
//                         validator: (value) {
//                           if (value == null || value.isEmpty) {
//                             return 'Masukkan password';
//                           } else if (value.length < 6) {
//                             return 'Password minimal 6 karakter';
//                           }
//                           return null;
//                         },
//                       ),
//                       const SizedBox(height: 10),
//                       Align(
//                         alignment: Alignment.centerRight,
//                         child: TextButton(
//                           onPressed: () {},
//                           child: const Text(
//                             'Lupa password?',
//                             style: TextStyle(color: Colors.grey),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 30),
//                       SizedBox(
//                         width: double.infinity,
//                         height: 50,
//                         child: ElevatedButton(
//                           onPressed: () {
//                             if (_formKey.currentState!.validate()) {
//                               _showLoginDialog();
//                             }
//                           },
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Color(0xFF38E08C),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(15),
//                             ),
//                           ),
//                           child: const Text(
//                             'MASUK',
//                             style: TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.white,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:aplikasi_makanan/homescreen.dart';
import 'package:aplikasi_makanan/utils/shared_prefs.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LoginUserPage extends StatefulWidget {
  const LoginUserPage({super.key});

  @override
  State<LoginUserPage> createState() => _LoginUserPageState();
}

class _LoginUserPageState extends State<LoginUserPage> {
  bool _isPasswordVisible = false;
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> loginUser() async {
    final email = _usernameController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['user'] != null) {
        final user = data['user'];
        final userId = user['id'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('user_id', userId);
        print("✅ user_id berhasil disimpan: $userId");

        _showSuccessDialog('Login berhasil!');
      } else {
        final errorMessage = data['message'] ?? 'Email atau password salah.';
        _showErrorDialog(errorMessage);
      }
    } catch (e) {
      _showErrorDialog('Tidak dapat terhubung ke server.');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Login Gagal'),
          ],
        ),
        content: Text(message),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) Navigator.of(context).pop();
    });
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Berhasil'),
          ],
        ),
        content: Text(message),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) {
        Navigator.of(context).pop(); // Tutup dialog
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomescreenPage()),
        );
      }
    });
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
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
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
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF38E08C),
                        ),
                      ),
                      const SizedBox(height: 40),
                      TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          prefixIcon:
                              const Icon(Icons.person, color: Colors.black),
                          hintText: 'Email',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Masukkan email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
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
                          onPressed: () {},
                          child: const Text(
                            'Lupa password?',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              loginUser();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF38E08C),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: const Text(
                            'MASUK',
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
