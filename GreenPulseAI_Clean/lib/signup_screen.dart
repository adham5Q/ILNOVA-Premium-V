import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'auth_service.dart';
import 'email_verification_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  static const Color green = Color(0xFF16865C);
  static const Color darkGreen = Color(0xFF145A3A);
  static const Color background = Color(0xFFF4F8F3);

  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;
  bool _isLoading = false;

  PhoneAuthCredential? _phoneCredential;
  bool _phoneVerified = false;
  bool _sendingPhoneOtp = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _hasMin8Chars(String pwd) => pwd.length >= 8;

  bool _hasLettersAndNumbers(String pwd) =>
      RegExp(r'[a-zA-Z]').hasMatch(pwd) &&
          RegExp(r'[0-9]').hasMatch(pwd);

  bool _hasUpperAndLower(String pwd) =>
      RegExp(r'[A-Z]').hasMatch(pwd) &&
          RegExp(r'[a-z]').hasMatch(pwd);

  bool _hasSpecialChar(String pwd) =>
      RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(pwd);

  int _calculatePasswordStrength(String pwd) {
    if (pwd.isEmpty) return 0;

    int met = 0;

    if (_hasMin8Chars(pwd)) met++;
    if (_hasLettersAndNumbers(pwd)) met++;
    if (_hasUpperAndLower(pwd)) met++;
    if (_hasSpecialChar(pwd)) met++;

    return met;
  }

  // إرسال OTP إلى رقم الهاتف.
  Future<void> _sendSmsOtp() async {
    final messenger = ScaffoldMessenger.of(context);
    final phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('الرجاء إدخال رقم الهاتف أولاً.'),
        ),
      );
      return;
    }

    if (_sendingPhoneOtp) return;

    setState(() => _sendingPhoneOtp = true);

    await AuthService.instance.verifyPhoneSMS(
      phone: phone,

      onCodeSent: (verificationId) {
        if (!mounted || _phoneVerified) return;
        _showOtpInputDialog(verificationId);
      },

      onAutoVerified: (credential) {
        if (!mounted) return;

        setState(() {
          _phoneCredential = credential;
          _phoneVerified = true;
          _sendingPhoneOtp = false;
        });

        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'تم التحقق من رقم الهاتف تلقائياً بنجاح.',
            ),
            backgroundColor: green,
          ),
        );
      },

      onError: (error) {
        if (!mounted) return;

        setState(() => _sendingPhoneOtp = false);

        messenger.showSnackBar(
          SnackBar(
            content: Text('تعذر إرسال رمز SMS: $error'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      },
    );
  }

  // إدخال رمز SMS وإنشاء PhoneAuthCredential.
  Future<void> _showOtpInputDialog(
      String verificationId,
      ) async {
    final messenger = ScaffoldMessenger.of(context);
    final otpController = TextEditingController();

    bool verifying = false;

    if (verificationId.startsWith('mock_')) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('رمز اختبار SMS هاتف هو: 123456'),
          backgroundColor: green,
          duration: Duration(seconds: 5),
        ),
      );
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('رمز التحقق عبر SMS'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'أدخل رمز التحقق المكوّن من 6 أرقام المرسل إلى هاتفك.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 23,
                  letterSpacing: 6,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  counterText: '',
                  hintText: '123456',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: verifying
                  ? null
                  : () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: verifying
                  ? null
                  : () async {
                final code = otpController.text.trim();

                if (code.length != 6) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('أدخل 6 أرقام صحيحة.'),
                    ),
                  );
                  return;
                }

                setDialogState(() => verifying = true);

                try {
                  PhoneAuthCredential credential;
                  if (verificationId.startsWith('mock_')) {
                    credential = PhoneAuthProvider.credential(
                      verificationId: 'mock_verification_id_123456',
                      smsCode: '123456',
                    );
                  } else {
                    credential = PhoneAuthProvider.credential(
                      verificationId: verificationId,
                      smsCode: code,
                    );
                  }

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }

                  if (!mounted) return;

                  setState(() {
                    _phoneCredential = credential;
                    _phoneVerified = true;
                    _sendingPhoneOtp = false;
                  });

                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text(
                        'تم تأكيد رقم الهاتف بنجاح! كمل تسجيل الحساب.',
                      ),
                      backgroundColor: green,
                    ),
                  );
                } catch (e) {
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }

                  if (!mounted) return;

                  setState(() {
                    _phoneVerified = true;
                    _sendingPhoneOtp = false;
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                foregroundColor: Colors.white,
              ),
              child: verifying
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Text('تأكيد الرمز'),
            ),
          ],
        ),
      ),
    );

    otpController.dispose();

    if (mounted) {
      setState(() => _sendingPhoneOtp = false);
    }
  }

  // إنشاء الحساب بعد تجهيز بيانات تحقق الهاتف.
  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate() || _isLoading) {
      return;
    }

    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please accept the Terms of Service & Privacy Policy.',
          ),
        ),
      );
      return;
    }

    if (!_phoneVerified || _phoneCredential == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تحقق من رقم الهاتف باستخدام OTP أولاً.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();

      await AuthService.instance.signUp(
        fullName: _fullNameController.text,
        email: email,
        password: _passwordController.text,
        phone: _phoneController.text,
        phoneCredential: _phoneCredential!,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => EmailVerificationScreen(
            userEmail: email,
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message = 'Sign up info: ${e.message ?? e.code}';

      if (e.code == 'email-already-in-use') {
        message =
        'An account already exists with this email. Please log in.';
      } else if (e.code == 'weak-password') {
        message =
        'Password is too weak. Use 8+ chars with letters & numbers.';
      } else if (e.code == 'invalid-email') {
        message = 'Please enter a valid email address.';
      } else if (e.code == 'invalid-verification-code') {
        message = 'رمز الهاتف غير صحيح. اطلب رمزاً جديداً وحاول مرة أخرى.';
      } else if (e.code == 'credential-already-in-use') {
        message = 'رقم الهاتف مرتبط بحساب آخر بالفعل.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.orange.shade800,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.orange.shade800,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildStrengthProgressBar(int met) {
    double progress = met / 4.0;

    Color barColor;
    String label;

    switch (met) {
      case 1:
        barColor = Colors.red;
        label = 'ضعيفة (Weak)';
        break;

      case 2:
        barColor = Colors.orange;
        label = 'متوسطة (Fair)';
        break;

      case 3:
        barColor = Colors.amber.shade700;
        label = 'جيدة (Good)';
        break;

      case 4:
        barColor = const Color(0xFF16865C);
        label = 'قوية جداً (Strong)';
        break;

      default:
        barColor = Colors.grey.shade400;
        label = 'أدخل كلمة المرور';
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'شريط تقييم قوة كلمة السر:',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF718276),
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: barColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress == 0 ? 0.05 : progress,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final pwd = _passwordController.text;
    final metCount = _calculatePasswordStrength(pwd);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        title: const Text(
          'Create Account',
          style: TextStyle(
            color: darkGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: darkGreen),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 90,
                      height: 90,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCF3E5),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: const Icon(
                        Icons.eco_rounded,
                        size: 54,
                        color: green,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Join GreenPulse AI',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                        color: darkGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Create your account and help build a greener world.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF617267),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // الاسم الكامل.
                    TextFormField(
                      controller: _fullNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: const Icon(
                          Icons.person_outline,
                          color: green,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter your full name';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // البريد الإلكتروني.
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: const Icon(
                          Icons.email_outlined,
                          color: green,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter your email';
                        }

                        if (!RegExp(
                          r'^[^@]+@[^@]+\.[^@]+$',
                        ).hasMatch(val.trim())) {
                          return 'Please enter a valid email';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // رقم الهاتف وإرسال OTP.
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      onChanged: (_) {
                        if (_phoneVerified) {
                          setState(() {
                            _phoneVerified = false;
                            _phoneCredential = null;
                          });
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'Phone Number (SMS / WhatsApp)',
                        prefixIcon: const Icon(
                          Icons.phone_outlined,
                          color: green,
                        ),
                        suffixIcon: TextButton(
                          onPressed:
                          (_sendingPhoneOtp || _phoneVerified)
                              ? null
                              : _sendSmsOtp,
                          child: Text(
                            _phoneVerified
                                ? 'Code entered ✓'
                                : (_sendingPhoneOtp
                                ? 'Sending...'
                                : 'Send OTP'),
                            style: const TextStyle(
                              color: green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // كلمة المرور.
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Password (8+ chars, letters & numbers)',
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: green,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: green,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Please enter a password';
                        }

                        if (val.length < 8) {
                          return 'Password must be at least 8 characters';
                        }

                        if (!_hasLettersAndNumbers(val)) {
                          return 'Password must contain both letters and numbers';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 10),

                    // مؤشر قوة كلمة المرور.
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFE2EAE3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStrengthProgressBar(metCount),
                          const SizedBox(height: 10),
                          const Text(
                            'معايير كلمة المرور التأمينية (Password Strength):',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: darkGreen,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _RuleCheck(
                            label:
                            '8 أحرف على الأقل (At least 8 characters)',
                            isMet: _hasMin8Chars(pwd),
                          ),
                          _RuleCheck(
                            label:
                            'يتضمن حروف وأرقام (Letters and numbers)',
                            isMet: _hasLettersAndNumbers(pwd),
                          ),
                          _RuleCheck(
                            label:
                            'حروف كبيرة وصغيرة (Uppercase & lowercase)',
                            isMet: _hasUpperAndLower(pwd),
                          ),
                          _RuleCheck(
                            label:
                            'رمز خاص اختياري (Special character e.g. @#\$%)',
                            isMet: _hasSpecialChar(pwd),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // تأكيد كلمة المرور.
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: green,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: green,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                              !_obscureConfirmPassword;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      validator: (val) {
                        if (val != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // الموافقة على الشروط.
                    Row(
                      children: [
                        Checkbox(
                          value: _acceptedTerms,
                          activeColor: green,
                          onChanged: (val) {
                            setState(() {
                              _acceptedTerms = val ?? false;
                            });
                          },
                        ),
                        const Expanded(
                          child: Text(
                            'I agree to the Terms of Service & Privacy Policy',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF617267),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // زر إنشاء الحساب.
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSignUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                            : const Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account? ',
                          style: TextStyle(
                            color: Color(0xFF617267),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Log In',
                            style: TextStyle(
                              color: green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RuleCheck extends StatelessWidget {
  const _RuleCheck({
    required this.label,
    required this.isMet,
  });

  final String label;
  final bool isMet;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isMet
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked,
            size: 16,
            color: isMet
                ? const Color(0xFF16865C)
                : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isMet
                    ? const Color(0xFF145A3A)
                    : Colors.grey.shade700,
                fontWeight: isMet
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}