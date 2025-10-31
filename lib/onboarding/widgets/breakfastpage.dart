import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BreakfastPage extends StatefulWidget {
  final void Function(Duration selectedTime) onContinue;
  const BreakfastPage({super.key, required this.onContinue});

  @override
  State<BreakfastPage> createState() => _BreakfastPageState();
}

class _BreakfastPageState extends State<BreakfastPage> {
  Duration _selectedTime = const Duration(hours: 7, minutes: 0);
  String? email;

  String get formattedTime {
    final hours = _selectedTime.inHours;
    final minutes = _selectedTime.inMinutes % 60;
    final hourStr = hours.toString().padLeft(2, '0');
    final minuteStr = minutes.toString().padLeft(2, '0');
    return '$hourStr:$minuteStr';
  }

  void _handleContinue() {
    widget.onContinue(_selectedTime);
    _loadEmail();
  }

  Future<void> _loadEmail() async {
    final prefs = await SharedPreferences.getInstance();
    email = prefs.getString('user_email');
    print("📧 Email yang diambil di NamePage: $email");
  }

  

  @override
  Widget build(BuildContext context) {
    final isValid = _selectedTime.inMinutes >= 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "When do you usually have breakfast?",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),

          Text(
            formattedTime,
            style: const TextStyle(fontSize: 20),
          ),

          const SizedBox(height: 20),

          SizedBox(
            height: 150,
            child: CupertinoTimerPicker(
              mode: CupertinoTimerPickerMode.hm,
              initialTimerDuration: _selectedTime,
              minuteInterval: 1,
              secondInterval: 1,
              onTimerDurationChanged: (Duration newDuration) {
                setState(() {
                  _selectedTime = newDuration;
                });
              },
            ),
          ),

          const SizedBox(height: 40),

          ElevatedButton(
            onPressed: isValid ? _handleContinue : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF38E08C),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size(200, 50),
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
