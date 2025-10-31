import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DinnerPage extends StatefulWidget {
  final void Function(Duration selectedTime, String email) onContinue;

  const DinnerPage({super.key, required this.onContinue});

  @override
  State<DinnerPage> createState() => _DinnerPageState();
}

class _DinnerPageState extends State<DinnerPage> {
  Duration _selectedTime = const Duration(hours: 19, minutes: 0);

  String? email;

  @override
  void initState() {
    super.initState();
    _loadEmail();
  }

  Future<void> _loadEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('user_email');
    print('Loaded email: $savedEmail');
    setState(() {
      email = savedEmail ?? '';
    });
  }

  String get formattedTime {
    final hours = _selectedTime.inHours;
    final minutes = _selectedTime.inMinutes % 60;
    final hourStr = hours.toString().padLeft(2, '0');
    final minuteStr = minutes.toString().padLeft(2, '0');
    return '$hourStr:$minuteStr';
  }

  void _handleContinue() {
    if (email == null || email!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email belum tersedia!')),
      );
      return;
    }
    widget.onContinue(_selectedTime, email!);
  }

  @override
  Widget build(BuildContext context) {
    if (email == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "When do you usually have Dinner?",
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
            onPressed: _handleContinue,
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
