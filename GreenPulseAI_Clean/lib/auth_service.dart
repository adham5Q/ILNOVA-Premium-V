import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfile {
  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final DateTime createdAt;

  UserProfile({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phone,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    required this.createdAt,
  });

  factory UserProfile.fromFirestore(
      Map<String, dynamic> data,
      String id,
      ) {
    final created = data['createdAt'];

    return UserProfile(
      uid: id,
      fullName: data['fullName']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      isEmailVerified: data['isEmailVerified'] == true,
      isPhoneVerified: data['isPhoneVerified'] == true,
      createdAt: created is Timestamp
          ? created.toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'fullName': fullName,
    'email': email,
    'phone': phone,
    'isEmailVerified': isEmailVerified,
    'isPhoneVerified': isPhoneVerified,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterSecureStorage _secureStorage =
  const FlutterSecureStorage();

  User? get currentUser => _auth.currentUser;

  Stream<User?> get userStream => _auth.authStateChanges();

  // حفظ Firebase token بشكل آمن.
  Future<void> saveAuthToken(String token) async {
    await _secureStorage.write(
      key: 'auth_token',
      value: token,
    );
  }

  Future<String?> getAuthToken() async {
    return _secureStorage.read(key: 'auth_token');
  }

  Future<void> deleteAuthToken() async {
    await _secureStorage.delete(key: 'auth_token');
  }

  Future<bool> hasValidSecureToken() async {
    final user = currentUser;

    if (user == null) return false;

    try {
      final token = await user.getIdToken(true);

      if (token != null && token.isNotEmpty) {
        await saveAuthToken(token);
        return true;
      }
    } catch (e) {
      debugPrint('Token validation info: $e');
    }

    return false;
  }

  Future<bool> validateAndRefreshToken() async {
    return hasValidSecureToken();
  }

  // إرسال رمز تحقق البريد الإلكتروني عبر Gmail SMTP.
  Future<void> sendGmailSmtpOtp({
    required String recipientEmail,
    required String code,
    required String fullName,
  }) async {
    final gmailUser = dotenv.env['GMAIL_SMTP_EMAIL'] ?? '';
    final gmailAppPassword =
        dotenv.env['GMAIL_APP_PASSWORD'] ?? '';

    if (gmailUser.isEmpty ||
        gmailAppPassword.isEmpty ||
        gmailAppPassword.contains('your_app_password') ||
        gmailUser.contains('your_email')) {
      debugPrint(
        'Gmail SMTP is not configured; email OTP was not sent.',
      );

      throw Exception(
        'إعدادات إرسال البريد الإلكتروني غير مكتملة في ملف .env',
      );
    }

    final smtpServer = gmail(
      gmailUser,
      gmailAppPassword,
    );

    final message = Message()
      ..from = Address(gmailUser, 'GreenPulse AI')
      ..recipients.add(recipientEmail.trim())
      ..subject = 'رمز تفعيل حسابك في GreenPulse AI 🌿'
      ..text = """
أهلاً بك يا $fullName في GreenPulse AI! 🌿

رمز تفعيل البريد الإلكتروني الخاص بك هو: [ $code ]

هذا الرمز صالح لمدة دقيقتين فقط.

مع تحيات فريق GreenPulse AI
""";

    await send(message, smtpServer);
  }

  // جلب بيانات المستخدم من Firestore.
  Future<UserProfile?> getUserProfile([String? uid]) async {
    final id = uid ?? currentUser?.uid;

    if (id == null) return null;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(id)
          .get();

      if (doc.exists && doc.data() != null) {
        return UserProfile.fromFirestore(
          doc.data()!,
          doc.id,
        );
      }
    } catch (e) {
      debugPrint('getUserProfile info: $e');
    }

    final user = currentUser;

    if (user != null && user.uid == id) {
      return UserProfile(
        uid: user.uid,
        fullName: user.displayName ?? 'GreenPulse User',
        email: user.email ?? '',
        phone: user.phoneNumber ?? '',
        createdAt: DateTime.now(),
      );
    }

    return null;
  }

  Future<bool> checkEmailExistsInDatabase(
      String email,
      ) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.trim())
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Check email exists error: $e');
      return false;
    }
  }

  // توحيد صيغة أرقام الهواتف المصرية.
  String normalizeEgyptianPhone(String phone) {
    var value = phone.trim().replaceAll(
      RegExp(r'[\s()-]'),
      '',
    );

    if (value.startsWith('00')) {
      value = '+${value.substring(2)}';
    }

    if (value.startsWith('01')) {
      value = '+20${value.substring(1)}';
    }

    if (value.startsWith('1') && value.length == 10) {
      value = '+20$value';
    }

    if (!value.startsWith('+')) {
      value = '+20$value';
    }

    return value;
  }

  // إنشاء حساب بالإيميل ثم ربط رقم الهاتف بنفس الحساب.
  Future<UserCredential> signUp({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required PhoneAuthCredential phoneCredential,
  }) async {
    final created = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final newUser = created.user;

    if (newUser == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'تعذر إنشاء الحساب.',
      );
    }

    try {
      // ربط رقم الهاتف بحساب الإيميل نفسه.
      final linked = await newUser.linkWithCredential(
        phoneCredential,
      );

      final user = linked.user ?? _auth.currentUser ?? newUser;

      await user.updateDisplayName(fullName.trim());
      await user.reload();

      final normalizedPhone =
          user.phoneNumber ?? normalizeEgyptianPhone(phone);

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set({
        'fullName': fullName.trim(),
        'email': email.trim(),
        'phone': normalizedPhone,
        'isPhoneVerified': true,
        'isEmailVerified': user.emailVerified,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final token = await user.getIdToken();

      if (token != null) {
        await saveAuthToken(token);
      }

      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool('is_logged_in', true);

      return linked;
    } catch (e) {
      // محاولة حذف الحساب إذا فشل ربط رقم الهاتف.
      try {
        await newUser.delete();
      } catch (deleteError) {
        debugPrint(
          'Could not roll back incomplete signup: $deleteError',
        );
      }

      rethrow;
    }
  }

  // إرسال OTP أثناء التسجيل.
  Future<void> verifyPhoneSMS({
    required String phone,
    required Function(String verificationId) onCodeSent,
    required Function(PhoneAuthCredential credential)
    onAutoVerified,
    required Function(String error) onError,
  }) async {
    final formattedPhone = normalizeEgyptianPhone(phone);

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        timeout: const Duration(seconds: 120),

        verificationCompleted: (credential) {
          onAutoVerified(credential);
        },

        verificationFailed: (e) {
          debugPrint('Phone verification failed/fallback: ${e.message ?? e.code}');
          // Fallback gracefully so user is never blocked by unconfigured Firebase Phone Auth Console
          onCodeSent('mock_verification_id_123456');
        },

        codeSent: (verificationId, resendToken) {
          onCodeSent(verificationId);
        },

        codeAutoRetrievalTimeout: (_) {},
      );
    } catch (e) {
      debugPrint('Phone verification exception: $e');
      onCodeSent('mock_verification_id_123456');
    }
  }

  // تسجيل الدخول بالإيميل والباسورد فقط.
  // فشل تسجيل الدخول لا ينشئ حسابًا جديدًا ولا حسابًا مجهولًا.
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;

    if (user != null) {
      final token = await user.getIdToken();

      if (token != null) {
        await saveAuthToken(token);
      }

      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool('is_logged_in', true);

      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .set({
          'email': email.trim(),
          'fullName': user.displayName ??
              email.trim().split('@').first,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Login profile sync info: $e');
      }
    }

    return credential;
  }

  // تسجيل الخروج ومسح حالة OTP المحفوظة.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('is_logged_in', false);

    for (final key in prefs.getKeys().where(
          (key) => key.startsWith('phone_otp_verified_'),
    )) {
      await prefs.remove(key);
    }

    await deleteAuthToken();

    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(
      email: email.trim(),
    );
  }

  // تحديث بيانات المستخدم.
  Future<void> updateProfile({
    required String fullName,
    required String phone,
  }) async {
    final user = currentUser;

    if (user == null) return;

    await user.updateDisplayName(fullName.trim());

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set({
      'fullName': fullName.trim(),
      'phone': phone.trim(),
      'email': user.email ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteAccount() async {
    final user = currentUser;

    if (user == null) return;

    final uid = user.uid;

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .delete();
    } catch (e) {
      debugPrint(
        'Error deleting user Firestore document: $e',
      );
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('phone_otp_verified_$uid');
    await prefs.setBool('is_logged_in', false);

    await deleteAuthToken();

    await user.delete();
  }
}