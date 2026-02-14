import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';

class MacRegistrationScreen extends StatefulWidget {
  const MacRegistrationScreen({super.key});

  @override
  State<MacRegistrationScreen> createState() => _MacRegistrationScreenState();
}

class _MacRegistrationScreenState extends State<MacRegistrationScreen> {
  final TextEditingController _controller = TextEditingController();
  late DatabaseReference _dbRef; // Root reference for "users"

  bool isChecking = true;
  bool isSubmitting = false;
  String? errorText;
  String? registeredMac;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (errorText != null) {
        setState(() {
          errorText = null; // Clear error on input change
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAndCheckMac();
    });
  }

  Future<void> _initializeAndCheckMac() async {
    try {
      final app = Firebase.apps.isEmpty
          ? await Firebase.initializeApp()
          : Firebase.app();
      final db = FirebaseDatabase.instanceFor(
        app: app,
        databaseURL:
            'https://smart-vertical-gardening-default-rtdb.asia-southeast1.firebasedatabase.app',
      );
      _dbRef = db.ref("users");

      final prefs = await SharedPreferences.getInstance();
      final savedMac = prefs.getString('mac_address');

      if (!mounted) return;

      if (savedMac != null && savedMac.isNotEmpty) {
        final snapshot = await _dbRef.child(savedMac).get();
        if (!mounted) return;

        if (snapshot.exists) {
          debugPrint("✅ Verified registered MAC: $savedMac");
          registeredMac = savedMac;
          Navigator.pushReplacementNamed(context, '/home');
          return;
        } else {
          // MAC removed from Firebase, clear saved pref
          await prefs.remove('mac_address');
        }
      }

      if (mounted) {
        setState(() => isChecking = false);
      }
    } catch (e) {
      debugPrint("❌ Firebase initialization error: $e");
      if (mounted) {
        setState(() {
          isChecking = false;
          errorText = "Error initializing Firebase.";
        });
      }
    }
  }

  bool _validateMacFormat(String mac) {
    final normalized =
        mac.replaceAll(RegExp(r'[^A-Fa-f0-9]'), '').toUpperCase();
    return RegExp(r'^[A-F0-9]{12}$').hasMatch(normalized);
  }

  Future<void> _submitMac() async {
    if (isSubmitting) return; // prevent multiple submits

    final rawMac = _controller.text.trim();

    if (!_validateMacFormat(rawMac)) {
      setState(() =>
          errorText = "Please enter a valid 12-digit hexadecimal MAC address.");
      return;
    }

    final normalizedMac =
        rawMac.replaceAll(RegExp(r'[^A-Fa-f0-9]'), '').toUpperCase();

    setState(() {
      isSubmitting = true;
      errorText = null;
    });

    try {
      final snapshot = await _dbRef.child(normalizedMac).get();
      if (!mounted) return;

      if (!snapshot.exists) {
        setState(() =>
            errorText = "❌ This MAC address is not registered in the system.");
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('mac_address', normalizedMac);

      if (!mounted) return;

      registeredMac = normalizedMac;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Registration successful!'),
          duration: Duration(seconds: 2),
        ),
      );

      // Delay navigation to allow snackbar to show
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      debugPrint("❌ MAC verification error: $e");
      if (mounted) {
        setState(() =>
            errorText = "Error verifying the MAC address. Please try again.");
      }
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isChecking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Access Account'),
        backgroundColor: Colors.green[800],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const Text(
                "Enter the MAC address of your IoT device",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                key: const ValueKey('mac_input'),
                controller: _controller,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  hintText: "e.g. 3C:71:BF:4A:8C:32",
                  errorText: errorText,
                  border: const OutlineInputBorder(),
                ),
                enabled: !isSubmitting,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  key: const ValueKey('register_button'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[800],
                  ),
                  onPressed: isSubmitting ? null : _submitMac,
                  child: isSubmitting
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        )
                      : const Text(
                          "Register",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
