import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NamePage extends StatefulWidget {
  final Function(String) onContinue;  
  const NamePage({super.key, required this.onContinue});

  @override
  State<NamePage> createState() => _NamePageState();
}

class _NamePageState extends State<NamePage> {
  late TextEditingController _controller;

  String? email;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    // _loadNama();
    _loadEmail(); 
  }

  Future<void> _loadEmail() async {
  final prefs = await SharedPreferences.getInstance();
  email = prefs.getString('user_email');
  print("📧 Email yang diambil di NamePage: $email");
}

  Future<void> _loadNama() async {
    final prefs = await SharedPreferences.getInstance();
    final savedNama = prefs.getString('nama') ?? '';
    _controller.text = savedNama;
    setState(() {});
  }

  Future<void> _saveNama(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nama', value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleContinue() {
    final nama = _controller.text.trim();
    print('Nama user: $nama');
    widget.onContinue(nama);  
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "What's your name?",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 100),
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'NAME',
              filled: true,
              fillColor: Colors.grey[300],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              _saveNama(value);
              setState(() {});
            },
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _controller.text.trim().isEmpty ? null : _handleContinue,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF38E08C),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: const Size(300, 50),
          ),
          child: const Text('Continue', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
