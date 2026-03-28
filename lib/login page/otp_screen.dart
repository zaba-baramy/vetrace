import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../driver/driver_dashboard.dart';
import '../parent/parent_dashboard.dart';
import '../admin_tabs/admin_dashboard.dart';

class OTPScreen extends StatefulWidget {
  final int initialOTP;
  final String email;
  final String role;

  const OTPScreen({
    super.key,
    required this.initialOTP,
    required this.email,
    required this.role
  });

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final TextEditingController _otpController = TextEditingController();
  late int _currentOTP;

  int _resendSeconds = 30;
  int _expirySeconds = 180;
  Timer? _timer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _currentOTP = widget.initialOTP;
    _startTimers();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startTimers() {
    if (!mounted) return;
    setState(() {
      _resendSeconds = 30;
      _expirySeconds = 180;
      _canResend = false;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_resendSeconds > 0) _resendSeconds--;
        if (_resendSeconds == 0) _canResend = true;

        if (_expirySeconds > 0) {
          _expirySeconds--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _handleResend() async {
    if (!_canResend) return;

    int newGeneratedOTP = Random().nextInt(900000) + 100000;
    const serviceId = 'service_e3n19vk';
    const templateId = 'template_z6ezsia';
    const publicKey = 'F_eGeTRULn6MP0_RL';

    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

    try {
      final response = await http.post(
        url,
        headers: const {'Content-Type': 'application/json'},
        body: json.encode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': publicKey,
          'template_params': {
            'to_email': widget.email,
            'otp_code': newGeneratedOTP.toString(),
          },
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          _currentOTP = newGeneratedOTP;
          _otpController.clear();
        });
        _startTimers();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("A new code has been sent!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to resend. Try again later.")),
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint("Resend Error: $e");
    }
  }

  void _verifyOTP() {
    if (_expirySeconds <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("OTP Expired! Please request a new code."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_otpController.text.trim() == _currentOTP.toString()) {
      Widget nextScreen;
      if (widget.role == "admin") {
        nextScreen = const AdminDashboard();
      } else if (widget.role == "parent") {
        nextScreen = const ParentDashboard();
      } else if (widget.role == "driver") {
        nextScreen = const DriverDashboard();
      } else {
        nextScreen = const Placeholder();
      }
      _showSuccessAndNavigate(nextScreen);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid Code. Try again.")),
      );
    }
  }

  void _showSuccessAndNavigate(Widget nextScreen) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: const Padding(
          padding: EdgeInsets.all(30.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 80),
              SizedBox(height: 20),
              Text("Access Granted", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text("Verification successful.", textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop();
        // This clears the entire stack so they can't go back to OTP/Login
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => nextScreen),
                (route) => false
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // NEW: PopScope prevents back-button navigation on mobile
    return PopScope(
      canPop: false, // Disables system back button
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
          automaticallyImplyLeading: false, // Removes the back arrow
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            children: [
              const Icon(Icons.shield_outlined, size: 70, color: Colors.blue),
              const SizedBox(height: 20),
              const Text("Verification", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text("Enter the code sent to\n${widget.email}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey)),

              const SizedBox(height: 30),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                style: const TextStyle(fontSize: 28, letterSpacing: 8, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(counterText: "", border: OutlineInputBorder()),
              ),

              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timer_outlined,
                      size: 16,
                      color: _expirySeconds < 30 ? Colors.red : Colors.grey),
                  const SizedBox(width: 5),
                  Text(
                    _expirySeconds > 0 ? "Code expires in ${_formatDuration(_expirySeconds)}" : "Code expired",
                    style: TextStyle(
                      color: _expirySeconds < 30 ? Colors.red : Colors.grey,
                      fontWeight: _expirySeconds < 30 ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[900],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _verifyOTP,
                  child: const Text("VERIFY & LOGIN", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: _canResend ? _handleResend : null,
                child: Text(
                  _canResend ? "Resend New Code" : "Resend available in $_resendSeconds s",
                  style: TextStyle(
                      color: _canResend ? Colors.blue[900] : Colors.grey,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}