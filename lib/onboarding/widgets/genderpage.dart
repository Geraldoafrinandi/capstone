import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GenderPage extends StatefulWidget {
  final void Function(String) onContinue;
  const GenderPage({super.key, required this.onContinue});

  @override
  State<GenderPage> createState() => _GenderPageState();
}

class _GenderPageState extends State<GenderPage> {
  String? _selectedGender;
  String? email;

  @override
  void initState() {
    super.initState();
    _loadEmail();
  }

  Future<void> _loadEmail() async {
    final prefs = await SharedPreferences.getInstance();
    email = prefs.getString('user_email');
    print("📧 Email yang diambil di GenderPage: $email");
  }

 Future<void> _handleContinue() async {
  if (_selectedGender != null) {
    print('✅ Gender yang dipilih: $_selectedGender');

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_gender', _selectedGender!);

    widget.onContinue(_selectedGender!);
  } else {
    await showDialog(
      context: context,
      builder: (context) => const AlertDialog(
        title: Text('Peringatan'),
        content: Text('Silakan pilih jenis kelamin terlebih dahulu.'),
      ),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "What’s your gender?",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _genderOption("Laki-laki", Icons.male),
            const SizedBox(width: 20),
            _genderOption("Perempuan", Icons.female),
          ],
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: _selectedGender != null ? _handleContinue : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF38E08C),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            minimumSize: const Size(300, 50),
          ),
          child: const Text(
            'Continue',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _genderOption(String label, IconData icon) {
    final bool isSelected = _selectedGender == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGender = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF38E08C) : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF38E08C) : Colors.grey,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 40, color: isSelected ? Colors.white : Colors.black),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
