import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BirthdayPage extends StatefulWidget {
  final void Function(DateTime) onContinue; 
  const BirthdayPage({super.key, required this.onContinue});

  @override
  State<BirthdayPage> createState() => _BirthdayPageState();
}

class _BirthdayPageState extends State<BirthdayPage> {
  DateTime? _selectedDate;
  String? email;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year - 18, now.month, now.day);
    _loadEmail();
  }

  Future<void> _loadEmail() async {
    final prefs = await SharedPreferences.getInstance();
    email = prefs.getString('user_email');
    print("📧 Email yang diambil di NamePage: $email");
  }

  void _handleContinue() {
    if (_selectedDate != null) {
      print(
          'Tanggal lahir user: ${DateFormat('dd MMMM yyyy').format(_selectedDate!)}');
      widget.onContinue(_selectedDate!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initialDate = DateTime(now.year - 18, now.month, now.day);
    final dateText = _selectedDate != null
        ? DateFormat('dd MMMM yyyy').format(_selectedDate!)
        : 'When your birthday?';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "When’s your birthday?",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),
          Text(
            dateText,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date,
              initialDateTime: _selectedDate ?? initialDate,
              minimumDate: DateTime(1900),
              maximumDate: today,
              onDateTimeChanged: (DateTime newDate) {
                setState(() {
                  _selectedDate = newDate;
                });
              },
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _selectedDate != null ? _handleContinue : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF38E08C),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size(300, 50),
            ),
            child: const Text(
              'Continue',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
