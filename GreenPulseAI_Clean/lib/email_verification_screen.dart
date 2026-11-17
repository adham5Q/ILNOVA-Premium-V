import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'home_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({
    super.key,
    required this.userEmail,
  });

  final String userEmail;

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends State<EmailVerificationScreen> {
  static const Color green = Color(0xFF16865C);
  static const Color darkGreen = Color(0xFF145A3A);
  static const Color background = Color(0xFFF4F8F3);

  final _codeController = TextEditingController();
  bool _isChecking = false;
  bool _isSendingEmail = false;

  String _currentVerificationCode = '';
  int _cooldownSecondsRemaining = 10;
  int _codeExpirySecondsRemaining = 120; // 2 minutes expiration
  int _attemptCount = 0; // Max 5 attempts allowed

  Timer? _cooldownTimer;
  Timer? _expiryTimer;

  @override
  void initState() {
    super.initState();
    _sendNewEmailOtpCode();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _cooldownTimer?.cancel();
    _expiryTimer?.cancel();
    super.dispose();
  }

  void _generate4DigitCode() {
    final rng = Random();
    _currentVerificationCode = (1000 + rng.nextInt(9000)).toString();
    _attemptCount = 0;
  }

  void _startCooldownTimer() {
    _cooldownTimer?.cancel();
    setState(() => _cooldownSecondsRemaining = 10);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSecondsRemaining > 0) {
        setState(() => _cooldownSecondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  void _startExpiryTimer() {
    _expiryTimer?.cancel();
    setState(() => _codeExpirySecondsRemaining = 120);
    _expiryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_codeExpirySecondsRemaining > 0) {
        setState(() => _codeExpirySecondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _sendNewEmailOtpCode() async {
    setState(() => _isSendingEmail = true);

    _generate4DigitCode();
    _startCooldownTimer();
    _startExpiryTimer();

    try {
      final profile = await AuthService.instance.getUserProfile();
      final name = profile?.fullName ?? 'GreenPulse User';

      await AuthService.instance.sendGmailSmtpOtp(
        recipientEmail: widget.userEmail,
        code: _currentVerificationCode,
        fullName: name,
      );

      if (!mounted) return;
      setState(() => _isSendingEmail = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إرسال كود التفعيل (رمز التجربة: $_currentVerificationCode) إلى بريدك بنجاح!'),
          backgroundColor: green,
          duration: const Duration(seconds: 6),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSendingEmail = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم توليد الرمز (كود التجربة: $_currentVerificationCode) — ملاحظة SMTP: $e'),
          backgroundColor: Colors.orange.shade800,
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  Future<void> _verifyEmailOtpCode() async {
    final enteredCode = _codeController.text.trim();

    if (_attemptCount >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'تجاوزت الحد الأقصى للمحاولات الخاطئة (5 محاولات). يرجى الضغط على إرسال كود جديد.',
          ),
          backgroundColor: Colors.red.shade800,
        ),
      );
      return;
    }

    if (_codeExpirySecondsRemaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'انتهت صلاحية الرمز الحالي (2 دقيقة). يرجى إرسال كود جديد.',
          ),
          backgroundColor: Colors.orange.shade800,
        ),
      );
      return;
    }

    if (enteredCode.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء كتابة رمز التفعيل المكون من 4 أرقام.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (enteredCode != _currentVerificationCode && enteredCode.length < 4) {
      setState(() => _attemptCount++);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'رمز التفعيل غير صحيح! المحاولة رقم $_attemptCount من 5.',
          ),
          backgroundColor: Colors.red.shade800,
        ),
      );
      return;
    }

    setState(() => _isChecking = true);

    try {
      final user = AuthService.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({'isEmailVerified': true}, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Firestore email activation info: $e');
    }

    if (!mounted) return;
    setState(() => _isChecking = false);

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }

  Future<void> _logout() async {
    await AuthService.instance.logout();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: darkGreen,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Log Out',
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCF3E5),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(
                    Icons.mark_email_read_rounded,
                    size: 58,
                    color: green,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Welcome to GreenPulse AI! 🌿',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: darkGreen,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'التحقق من البريد الإلكتروني (Gmail)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: green,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2EAE3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'أرسلنا كود تفعيل مكون من 4 أرقام عبر Gmail إلى إيميلك:',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade800,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.userEmail,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: darkGreen,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _codeExpirySecondsRemaining > 0
                                ? Icons.timer_outlined
                                : Icons.timer_off_outlined,
                            size: 16,
                            color: _codeExpirySecondsRemaining > 0
                                ? green
                                : Colors.red,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _codeExpirySecondsRemaining > 0
                                ? 'انتهاء الرمز خلال ${_codeExpirySecondsRemaining ~/ 60}:${(_codeExpirySecondsRemaining % 60).toString().padLeft(2, '0')}'
                                : 'انتهت صلاحية الرمز الحالية (2 دقيقة)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _codeExpirySecondsRemaining > 0
                                  ? darkGreen
                                  : Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 6,
                          color: darkGreen,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: '4 أرقام',
                          hintStyle: const TextStyle(
                            fontSize: 14,
                            letterSpacing: 0,
                            color: Colors.grey,
                          ),
                          filled: true,
                          fillColor: background,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: green),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'عدد المحاولات المستخدمة: $_attemptCount من 5',
                        style: TextStyle(
                          fontSize: 12,
                          color: _attemptCount >= 5 ? Colors.red : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: SizedBox(
                    width: 220,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isChecking ? null : _verifyEmailOtpCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isChecking
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'تأكيد الإيميل',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: (_cooldownSecondsRemaining > 0 || _isSendingEmail)
                        ? null
                        : _sendNewEmailOtpCode,
                    icon: _isSendingEmail
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: green,
                            ),
                          )
                        : const Icon(Icons.send_rounded, color: green, size: 18),
                    label: Text(
                      _cooldownSecondsRemaining > 0
                          ? 'إعادة الإرسال بعد $_cooldownSecondsRemaining ثوانٍ'
                          : 'إعادة إرسال كود جديد',
                      style: const TextStyle(
                        color: green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: green),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
