import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WeightPage extends StatefulWidget {
  final void Function(double weight) onContinue;
  const WeightPage({super.key, required this.onContinue});

  @override
  State<WeightPage> createState() => _WeightPageState();
}

class _WeightPageState extends State<WeightPage> {
  final TextEditingController _weightController = TextEditingController();
  bool _isValid = false;
  String? email;

  void _onChanged(String value) {
    final parsed = double.tryParse(value);
    setState(() {
      _isValid = parsed != null && parsed > 0;
      _loadEmail();
    });
  }

   Future<void> _loadEmail() async {
    final prefs = await SharedPreferences.getInstance();
    email = prefs.getString('user_email');
    print("📧 Email yang diambil di NamePage: $email");
  }

  void _handleContinue() {
    final text = _weightController.text.trim();
    final weight = double.tryParse(text);
    if (weight != null && weight > 0) {
      widget.onContinue(weight);
    } else {
      print('Weight input invalid saat Continue');
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "What’s your weight?",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 40),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: TextField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            onChanged: _onChanged,
            decoration: InputDecoration(
              labelText: 'Weight (kg)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixText: 'kg',
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
