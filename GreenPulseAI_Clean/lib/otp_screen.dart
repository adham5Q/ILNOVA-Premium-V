import 'package:flutter/material.dart';

import 'auth_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'phone_otp_service.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
  });

  final String verificationId;
  final String phoneNumber;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const green = Color(0xFF16865C);
  static const darkGreen = Color(0xFF145A3A);

  final _codeController = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final code = _codeController.text.trim();

    if (code.length != 6) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('اكتب رمز التحقق المكوّن من 6 أرقام.'),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await PhoneOtpService.instance.verifyOtp(
        verificationId: widget.verificationId,
        smsCode: code,
      );

      nav.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('خطأ في التحقق: $e'),
          backgroundColor: Colors.red.shade800,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _cancel() async {
    final nav = Navigator.of(context);
    await AuthService.instance.logout();

    if (!mounted) return;

    nav.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F8F3),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: darkGreen,
          ),
          onPressed: _cancel,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCF3E5),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Icon(
                      Icons.sms_outlined,
                      color: green,
                      size: 52,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Verify your phone',
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                      color: darkGreen,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'أدخل رمز التحقق المكوّن من 6 أرقام المرسل إلى (كود التجربة: 123456):',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF617267),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.phoneNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: darkGreen,
                    ),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 25,
                      letterSpacing: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      hintText: '123456',
                      counterText: '',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _verify,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _loading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                              'Verify & Continue',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _loading ? null : _cancel,
                    child: const Text(
                      'إلغاء وتسجيل الخروج',
                      style: TextStyle(color: green),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
