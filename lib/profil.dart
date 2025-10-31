import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:elegant_notification/elegant_notification.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int? userId;

  final _formKey = GlobalKey<FormState>();

  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _beratBadanController = TextEditingController();
  final _tinggiBadanController = TextEditingController();
  final _sarapanController = TextEditingController();
  final _makanMalamController = TextEditingController();

  String? gender;
  String? tglLahir;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final storedUserId = prefs.getInt('user_id');
    if (storedUserId != null) {
      setState(() {
        userId = storedUserId;
      });
      _fetchUserProfile();
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User ID tidak ditemukan. Silakan login ulang.'),
        ),
      );
    }
  }

  Future<void> _fetchUserProfile() async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:3000/api/user-profile/$userId'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body)['data'];

      setState(() {
        _namaController.text = data['nama'] ?? '';
        _emailController.text = data['email'] ?? '';
        gender = data['gender'] ?? '-';
        tglLahir = data['tgl_lahir'] ?? '-';
        _beratBadanController.text = data['berat_badan']?.toString() ?? '';
        _tinggiBadanController.text = data['tinggi_badan']?.toString() ?? '';
        _sarapanController.text = data['sarapan'] ?? '';
        _makanMalamController.text = data['makan_malam'] ?? '';
        isLoading = false;
      });
      print('DATA USER ===> $data');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memuat profil user')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _selectTime(TextEditingController controller) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) {
      final hh = pickedTime.hour.toString().padLeft(2, '0');
      final mm = pickedTime.minute.toString().padLeft(2, '0');
      controller.text = '$hh:$mm:00';
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      final Map<String, dynamic> body = {
        'nama': _namaController.text,
        'email': _emailController.text,
        'berat_badan': double.tryParse(_beratBadanController.text) ?? 0,
        'tinggi_badan': double.tryParse(_tinggiBadanController.text) ?? 0,
        'sarapan': _sarapanController.text,
        'makan_malam': _makanMalamController.text,
      };

      if (_passwordController.text.isNotEmpty) {
        body['password'] = _passwordController.text;
      }

      final response = await http.put(
        Uri.parse('http://10.0.2.2:3000/api/users/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
        const  SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Profil berhasil diperbarui!')),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration:  Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        );
        // ignore: use_build_context_synchronously
        Navigator.pop(context, true);
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Gagal memperbarui profil: ${response.body}',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 20.0),
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 24),
                  _buildInfoCard(
                    title: 'Informasi Akun',
                    children: [
                      _buildTextField(
                        controller: _namaController,
                        label: 'Nama',
                        icon: Icons.person_outline,
                        validator: (value) =>
                            value!.isEmpty ? 'Nama tidak boleh kosong' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) =>
                            value!.isEmpty ? 'Email tidak boleh kosong' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _passwordController,
                        label: 'Password Baru (opsional)',
                        icon: Icons.lock_outline,
                        obscureText: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildInfoCard(
                    title: 'Data Kesehatan',
                    children: [
                      _buildDisplayField(
                          icon: Icons.wc_outlined,
                          label: 'Gender',
                          value: gender ?? '-'),
                      // const Divider(height: 32),
                      // _buildDisplayField(
                      //     icon: Icons.cake_outlined,
                      //     label: 'Tanggal Lahir',
                      //     value: tglLahir ?? '-'),
                      const Divider(height: 32),
                      _buildTextField(
                        controller: _beratBadanController,
                        label: 'Berat Badan (kg)',
                        icon: Icons.fitness_center_outlined,
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            value!.isEmpty ? 'Berat badan wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _tinggiBadanController,
                        label: 'Tinggi Badan (cm)',
                        icon: Icons.height_outlined,
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            value!.isEmpty ? 'Tinggi badan wajib diisi' : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildInfoCard(
                    title: 'Preferensi Jam Makan',
                    children: [
                      _buildTimeField(
                        controller: _sarapanController,
                        label: 'Jam Sarapan',
                      ),
                      const SizedBox(height: 16),
                      _buildTimeField(
                        controller: _makanMalamController,
                        label: 'Jam Makan Malam',
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Simpan Perubahan',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.green.shade100,
          child: Icon(
            Icons.person,
            size: 60,
            color: Colors.green.shade800,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _namaController.text,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          _emailController.text,
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildInfoCard(
      {required String title, required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey.shade600),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.green, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      ),
      validator: validator,
    );
  }

  Widget _buildDisplayField(
      {required IconData icon, required String label, required String value}) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade600),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            const SizedBox(height: 4),
            Text(value,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        )
      ],
    );
  }

  Widget _buildTimeField(
      {required TextEditingController controller, required String label}) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(Icons.access_time, color: Colors.grey.shade600),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.green, width: 2),
        ),
      ),
      onTap: () => _selectTime(controller),
      validator: (value) {
        if (value == null || value.isEmpty) return '$label wajib diisi';
        return null;
      },
    );
  }
}
