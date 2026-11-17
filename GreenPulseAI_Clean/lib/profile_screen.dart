import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service.dart';
import 'database_helper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color green = Color(0xFF16865C);
  static const Color darkGreen = Color(0xFF145A3A);
  static const Color background = Color(0xFFF4F8F3);

  UserProfile? _profile;
  String? _profileImagePath;
  bool _isLoading = true;
  int _reportCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    final profile = await AuthService.instance.getUserProfile();
    final reports = await DatabaseHelper.instance.getReports();

    final uid = profile?.uid ?? AuthService.instance.currentUser?.uid ?? 'user';
    final prefs = await SharedPreferences.getInstance();

    final savedImagePath = prefs.getString('profile_image_$uid');
    final savedName = prefs.getString('profile_name_$uid');
    final savedPhone = prefs.getString('profile_phone_$uid');

    final finalFullName = (savedName != null && savedName.trim().isNotEmpty)
        ? savedName.trim()
        : (profile?.fullName.isNotEmpty == true
            ? profile!.fullName
            : (AuthService.instance.currentUser?.displayName ?? 'GreenPulse User'));

    final finalPhone = (savedPhone != null && savedPhone.trim().isNotEmpty)
        ? savedPhone.trim()
        : (profile?.phone ?? '');

    final finalProfile = UserProfile(
      uid: uid,
      fullName: finalFullName,
      email: profile?.email ?? AuthService.instance.currentUser?.email ?? '',
      phone: finalPhone,
      createdAt: profile?.createdAt ?? DateTime.now(),
    );

    if (!mounted) return;

    setState(() {
      _profile = finalProfile;
      _profileImagePath = savedImagePath;
      _reportCount = reports.length;
      _isLoading = false;
    });
  }

  Future<void> _editProfile() async {
    final currentName = _profile?.fullName.isNotEmpty == true
        ? _profile!.fullName
        : (AuthService.instance.currentUser?.displayName ?? 'GreenPulse User');
    final currentPhone = _profile?.phone ?? '';

    final nameController = TextEditingController(text: currentName);
    final phoneController = TextEditingController(text: currentPhone);
    String? dialogImagePath = _profileImagePath;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> pickImage(ImageSource source) async {
            final picker = ImagePicker();
            final pickedFile = await picker.pickImage(
              source: source,
              maxWidth: 600,
              maxHeight: 600,
              imageQuality: 85,
            );

            if (pickedFile != null) {
              setDialogState(() {
                dialogImagePath = pickedFile.path;
              });
            }
          }

          void showPickerOptions() {
            showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (bottomContext) => SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'اختيار صورة البروفايل',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: darkGreen,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.photo_library_outlined, color: green),
                        title: const Text('اختيار من المعرض (Gallery)'),
                        onTap: () {
                          Navigator.pop(bottomContext);
                          pickImage(ImageSource.gallery);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.camera_alt_outlined, color: green),
                        title: const Text('التقاط صورة بالكاميرا (Camera)'),
                        onTap: () {
                          Navigator.pop(bottomContext);
                          pickImage(ImageSource.camera);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('تعديل الحساب (Edit Profile)', style: TextStyle(color: darkGreen, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: showPickerOptions,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: const Color(0xFFDCF3E5),
                          backgroundImage: dialogImagePath != null && File(dialogImagePath!).existsSync()
                              ? FileImage(File(dialogImagePath!))
                              : null,
                          child: dialogImagePath == null || !File(dialogImagePath!).existsSync()
                              ? Text(
                                  _profile?.fullName.isNotEmpty == true
                                      ? _profile!.fullName[0].toUpperCase()
                                      : 'G',
                                  style: const TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.bold,
                                    color: green,
                                  ),
                                )
                              : null,
                        ),
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: showPickerOptions,
                    icon: const Icon(Icons.photo_camera_outlined, size: 16, color: green),
                    label: const Text(
                      'تغيير صورة البروفايل',
                      style: TextStyle(color: green, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'الاسم الكامل (Full Name)',
                      prefixIcon: const Icon(Icons.person_outline, color: green),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'رقم الهاتف (Phone Number)',
                      prefixIcon: const Icon(Icons.phone_outlined, color: green),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () async {
                  final newName = nameController.text.trim();
                  final newPhone = phoneController.text.trim();
                  if (newName.isEmpty) return;

                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(dialogContext);

                  final uid = _profile?.uid ?? AuthService.instance.currentUser?.uid ?? 'user';

                  // 1. Save locally in SharedPreferences immediately
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('profile_name_$uid', newName);
                  await prefs.setString('profile_phone_$uid', newPhone);
                  if (dialogImagePath != null) {
                    await prefs.setString('profile_image_$uid', dialogImagePath!);
                  }

                  // 2. Optimistically update local profile state immediately
                  setState(() {
                    _profileImagePath = dialogImagePath ?? _profileImagePath;
                    _profile = UserProfile(
                      uid: uid,
                      fullName: newName,
                      email: _profile?.email ?? AuthService.instance.currentUser?.email ?? '',
                      phone: newPhone,
                      createdAt: _profile?.createdAt ?? DateTime.now(),
                    );
                  });

                  // 3. Save to Firestore in background
                  try {
                    await AuthService.instance.updateProfile(
                      fullName: newName,
                      phone: newPhone,
                    );
                  } catch (e) {
                    debugPrint('Firestore update profile info: $e');
                  }

                  if (!mounted) return;
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('✅ تم حفظ تعديلات الحساب والصورة بنجاح!'),
                      backgroundColor: green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('حفظ التعديلات'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', false);
    } catch (_) {}
    await AuthService.instance.logout();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to permanently delete your GreenPulse AI account and data? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await AuthService.instance.deleteAccount();
        if (!mounted) return;
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account deleted.')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete account: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: darkGreen,
        elevation: 0,
        title: const Text(
          'User Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: green))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE0EAE1)),
                      ),
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              GestureDetector(
                                onTap: _editProfile,
                                child: CircleAvatar(
                                  radius: 46,
                                  backgroundColor: const Color(0xFFDCF3E5),
                                  backgroundImage: _profileImagePath != null &&
                                          File(_profileImagePath!).existsSync()
                                      ? FileImage(File(_profileImagePath!))
                                      : null,
                                  child: _profileImagePath == null ||
                                          !File(_profileImagePath!).existsSync()
                                      ? Text(
                                          _profile?.fullName.isNotEmpty == true
                                              ? _profile!.fullName[0].toUpperCase()
                                              : 'G',
                                          style: const TextStyle(
                                            fontSize: 36,
                                            fontWeight: FontWeight.bold,
                                            color: green,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              GestureDetector(
                                onTap: _editProfile,
                                child: Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: green,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _profile?.fullName.isNotEmpty == true
                                ? _profile!.fullName
                                : 'GreenPulse User',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: darkGreen,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _profile?.email ?? '',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF718276),
                            ),
                          ),
                          if (_profile?.phone.isNotEmpty == true) ...[
                            const SizedBox(height: 4),
                            Text(
                              _profile!.phone,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF718276),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: _editProfile,
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('Edit Profile'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: green,
                              side: const BorderSide(color: green),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE0EAE1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Environmental Activity',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: darkGreen,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _StatTile(
                                  label: 'Reports Filed',
                                  value: '$_reportCount',
                                  icon: Icons.report_problem_outlined,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: _StatTile(
                                  label: 'Scans & Guides',
                                  value: 'Active',
                                  icon: Icons.eco_outlined,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Log Out'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _deleteAccount,
                      icon: const Icon(Icons.delete_forever_outlined, color: Colors.red),
                      label: const Text(
                        'Delete Account',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8F3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF16865C), size: 28),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF145A3A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF718276),
            ),
          ),
        ],
      ),
    );
  }
}
