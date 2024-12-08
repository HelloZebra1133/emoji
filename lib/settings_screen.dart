import 'dart:async'; // Import for Timer
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'font_size_provider.dart'; // Import your provider

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Timer _timer; // Timer for inactivity
  int _timerDuration = 10; // Duration in seconds for inactivity timeout

  // Start the timer
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timerDuration -= 1;
      });

      if (_timerDuration <= 0) {
        _exitScreen(); // Exit screen when timer reaches 0
      }
    });
  }

  // Reset the timer when any button is pressed
  void _resetTimer() {
    setState(() {
      _timerDuration = 10; // Reset to 10 seconds
    });
  }

  // Exit the screen back to EmojiCategoriesScreen
  void _exitScreen() {
    if (mounted) {
      _timer.cancel(); // Cancel the timer
      Navigator.of(context).pop(); // Exit the screen
    }
  }

  @override
  void initState() {
    super.initState();
    _startTimer(); // Start the timer on screen load
  }

  @override
  void dispose() {
    _timer.cancel(); // Cancel the timer to avoid memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space between items
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Font Size'),
                RadioListTile<double>(
                  title: const Text('Normal'),
                  value: 22.0,
                  groupValue: fontSizeProvider.fontSize,
                  onChanged: (size) {
                    fontSizeProvider.setFontSize(size!);
                    _resetTimer(); // Reset the timer
                  },
                ),
                RadioListTile<double>(
                  title: const Text('Large'),
                  value: 28.0,
                  groupValue: fontSizeProvider.fontSize,
                  onChanged: (size) {
                    fontSizeProvider.setFontSize(size!);
                    _resetTimer(); // Reset the timer
                  },
                ),
                RadioListTile<double>(
                  title: const Text('Extra Large'),
                  value: 34.0,
                  groupValue: fontSizeProvider.fontSize,
                  onChanged: (size) {
                    fontSizeProvider.setFontSize(size!);
                    _resetTimer(); // Reset the timer
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  'Preview text with current font size',
                  style: TextStyle(fontSize: fontSizeProvider.fontSize),
                ),
              ],
            ),
            Column(
              children: [
                ElevatedButton(
                  onPressed: _exitScreen, // Exit the screen
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, // Red for emphasis
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 20), // Big button style
                    textStyle: const TextStyle(fontSize: 24),
                  ),
                  child: const Text('Exit', style: TextStyle(color: Colors.white),),
                ),
                const SizedBox(height: 10),
                Text(
                  'Returning in $_timerDuration seconds...',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
