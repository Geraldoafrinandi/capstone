import 'dart:convert';
import 'package:aplikasi_makanan/login.dart';
import 'package:aplikasi_makanan/profil.dart';
import 'package:aplikasi_makanan/resep.dart';
import 'package:flutter/material.dart';
import 'package:aplikasi_makanan/calories.dart';
import 'package:aplikasi_makanan/history.dart';
import 'package:aplikasi_makanan/homepage.dart';
import 'package:aplikasi_makanan/nutdiary.dart';
import 'package:aplikasi_makanan/nutprogress.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class HomescreenPage extends StatefulWidget {
  const HomescreenPage({super.key});

  @override
  State<HomescreenPage> createState() => _HomescreenPageState();
}

class _HomescreenPageState extends State<HomescreenPage> {
  int currentPageIndex = 0;
  final GlobalKey<HomepageState> homepageKey = GlobalKey<HomepageState>();
  bool isLoading = false;
  bool isUserLoading = true;
  String _userName = '';
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      setState(() {
        isUserLoading = true;
      });

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      print('🔍 Mencoba mengambil data untuk User ID: $userId');

      if (userId == null) {
        throw Exception("User tidak ditemukan di SharedPreferences.");
      }

      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/api/user/$userId'),
      );

      print('📡 Status Respon Server: ${response.statusCode}');
      print('📦 Body Respon Server: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final data = jsonResponse['data'];

          if (mounted) {
            setState(() {
              _userName = data['nama'] ?? 'Tanpa Nama';
              _userEmail = data['email'] ?? 'Tanpa Email';
              isUserLoading = false;
            });
          }
        } else {
          throw Exception('Data user tidak valid dari server.');
        }
      } else {
        throw Exception(
            'Gagal mengambil data user (status ${response.statusCode})');
      }
    } catch (e) {
      print('❌ Terjadi error: $e');
      if (mounted) {
        setState(() {
          _userName = 'Gagal memuat';
          _userEmail = '';
          isUserLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await _showLogoutDialog();

    if (confirm != true) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (Route<dynamic> route) => false,
      );
    }
  }

  Future<bool?> _showLogoutDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Konfirmasi Logout'),
          content: const Text('Anda yakin ingin keluar dari akun ini?'),
          actions: [
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.pop(context, false); 
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Logout'),
              onPressed: () {
                Navigator.pop(context, true); 
              },
            ),
          ],
        );
      },
    );
  }

  void _onCameraPressed() {
    setState(() {
      currentPageIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      Homepage(key: homepageKey),
      const HistoryPage(),
      const NutritionDiaryPage(),
      const CaloriesPage(),
      const NutritionProgressPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "NutriVision",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.green.shade400,
        foregroundColor: Colors.white,
      ),
      drawer: _buildAppDrawer(),
      body: pages[currentPageIndex],
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: currentPageIndex == 0 ? Colors.green : Colors.transparent,
            width: 3,
          ),
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.white,
          onPressed: isLoading ? null : _onCameraPressed,
          shape: const CircleBorder(),
          elevation: 6,
          child: const Icon(
            Icons.camera_alt,
            color: Colors.green,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Colors.green.shade400,
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTabIcon(Icons.food_bank_rounded, "Calories", 3),
              _buildTabIcon(Icons.history, "History", 1),
              const SizedBox(width: 40),
              _buildTabIcon(Icons.book, "Diary", 2),
              _buildTabIcon(Icons.query_stats, "Progress", 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.green.shade400,
            ),
            child: isUserLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child:
                            Icon(Icons.person, size: 40, color: Colors.green),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _userName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _userEmail,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
          ),
          _buildDrawerItem(
            icon: Icons.person_outline,
            title: 'Profil',
            onTap: () async {
              Navigator.pop(context); 

             
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfilePage(),
                ),
              );

              
              if (result == true) {
                _fetchUserData();
              }
            },
          ),
          _buildDrawerItem(
            icon: Icons.menu_book_outlined,
            title: 'Resep Makanan',
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const ResepPage()));
            },
          ),
          const Divider(),
          _buildDrawerItem(
            icon: Icons.logout,
            title: 'Logout',
            onTap: _logout,
          ),
        ],
      ),
    );
  }

  ListTile _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade700),
      title: Text(title),
      onTap: onTap,
    );
  }

  Widget _buildTabIcon(IconData icon, String label, int index) {
    final isSelected = index == currentPageIndex;
    return GestureDetector(
      onTap: () {
        setState(() {
          currentPageIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? Colors.black : Colors.white),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
