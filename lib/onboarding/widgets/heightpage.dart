import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HeightPage extends StatefulWidget {
  final void Function(double) onContinue; // terima nilai tinggi
  const HeightPage({super.key, required this.onContinue});

  @override
  State<HeightPage> createState() => _HeightPageState();
}

class _HeightPageState extends State<HeightPage> {
  final TextEditingController _heightController = TextEditingController();
  bool _isValid = false;
  String? email;

  void _onChanged(String value) {
    setState(() {
      _isValid = double.tryParse(value) != null && double.parse(value) > 0;
      _loadEmail();
    });
  }

  Future<void> _loadEmail() async {
    final prefs = await SharedPreferences.getInstance();
    email = prefs.getString('user_email');
    print("📧 Email yang diambil di NamePage: $email");
  }

  void _handleContinue() {
  final text = _heightController.text.trim();
  print('Input height controller: "$text"');
  if (_isValid && text.isNotEmpty) {
    final height = double.tryParse(text);
    if (height != null && height > 0) {
      print('Tinggi user: $height cm');
      widget.onContinue(height);
    } else {
      print('Input tidak valid saat Continue');
    }
  }
}


  @override
  void dispose() {
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "What’s your height?",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 40),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: TextField(
            controller: _heightController,
            keyboardType: TextInputType.number,
            onChanged: _onChanged,
            decoration: InputDecoration(
              labelText: 'Height (Cm)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixText: 'cm',
            ),
          ),
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: _isValid ? _handleContinue : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF38E08C),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
}
