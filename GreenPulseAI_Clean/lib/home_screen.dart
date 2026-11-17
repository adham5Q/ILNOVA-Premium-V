import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'ai_waste_scan_screen.dart';
import 'auth_service.dart';
import 'citizen_partner_requests_screen.dart';
import 'collection_points_screen.dart';
import 'company_partner_dashboard.dart';
import 'database_helper.dart';
import 'partner_admin_screen.dart';
import 'partner_register_screen.dart';
import 'profile_screen.dart';
import 'recycling_screen.dart';
import 'waste_report_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color green = Color(0xFF16865C);
  static const Color darkGreen = Color(0xFF145A3A);
  static const Color background = Color(0xFFF4F8F3);

  UserProfile? _userProfile;
  int _reportCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final profile = await AuthService.instance.getUserProfile();
    final reports = await DatabaseHelper.instance.getReports();

    if (!mounted) return;

    setState(() {
      _userProfile = profile;
      _reportCount = reports.length;
    });
  }

  Future<void> _handleLogout() async {
    await AuthService.instance.logout();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
          (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header.
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDDF3E5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.eco_rounded,
                      color: green,
                      size: 29,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _userProfile?.fullName.isNotEmpty == true
                              ? _userProfile!.fullName
                              : 'GreenPulse AI',
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: darkGreen,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Text(
                          'A greener world starts with you',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF718276),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Logout button.
                  IconButton(
                    tooltip: 'Log out',
                    onPressed: _handleLogout,
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: green,
                    ),
                  ),

                  // Profile button.
                  IconButton(
                    tooltip: 'User Profile',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(),
                        ),
                      ).then((_) => _loadData());
                    },
                    icon: CircleAvatar(
                      radius: 18,
                      backgroundColor: green,
                      child: Text(
                        _userProfile?.fullName.isNotEmpty == true
                            ? _userProfile!.fullName[0].toUpperCase()
                            : 'G',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              Text(
                _userProfile?.fullName.isNotEmpty == true
                    ? 'Hello, ${_userProfile!.fullName.split(' ').first}!'
                    : 'Hello, Changemaker!',
                style: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                  color: darkGreen,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'What would you like to do for the planet today?',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Color(0xFF617267),
                ),
              ),

              const SizedBox(height: 24),

              // Main banner.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF16865C),
                      Color(0xFF0D6948),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.public_rounded,
                      color: Colors.white,
                      size: 35,
                    ),
                    SizedBox(height: 18),
                    Text(
                      'Small actions.\nBig impact.',
                      style: TextStyle(
                        fontSize: 25,
                        height: 1.25,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Identify waste, report problems, and help '
                          'build a cleaner community.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'Explore GreenPulse',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: darkGreen,
                ),
              ),

              const SizedBox(height: 16),

              // AI Waste Scan and Report Issue.
              Row(
                children: [
                  Expanded(
                    child: _FeatureCard(
                      icon: Icons.document_scanner_rounded,
                      title: 'AI Waste Scan',
                      subtitle: 'Identify waste',
                      color: const Color(0xFFE1F2E7),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                            const AiWasteScanScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _FeatureCard(
                      icon: Icons.report_problem_outlined,
                      title: 'Report Issue',
                      subtitle: 'Help your area',
                      color: const Color(0xFFFFEAD5),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                            const WasteReportScreen(),
                          ),
                        ).then((_) => _loadData());
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Recycling and Collection Points.
              Row(
                children: [
                  Expanded(
                    child: _FeatureCard(
                      icon: Icons.recycling_rounded,
                      title: 'Recycling',
                      subtitle: 'Recycle smarter',
                      color: const Color(0xFFDDEFFC),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                            const RecyclingScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _FeatureCard(
                      icon: Icons.location_on_outlined,
                      title: 'Collection Points',
                      subtitle: 'Find nearby points',
                      color: const Color(0xFFF0E5FC),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                            const CollectionPointsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              const Text(
                'شراكة الشركات وإعادة التدوير',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: darkGreen,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'تواصل مع الشركات الشريكة المعتمدة لتسليم مخلفاتك ومتابعة طلباتك.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: Color(0xFF718276),
                ),
              ),

              const SizedBox(height: 14),

              // Partner registration and company dashboard.
              Row(
                children: [
                  Expanded(
                    child: _FeatureCard(
                      icon: Icons.handshake_rounded,
                      title: 'تسجيل شركة',
                      subtitle: 'كن شريكاً رسمياً',
                      color: const Color(0xFFDCF3E5),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                            const PartnerRegisterScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _FeatureCard(
                      icon: Icons.business_center_rounded,
                      title: 'بوابة الشركات',
                      subtitle: 'إدارة طلبات المواطنين',
                      color: const Color(0xFFFFF0D9),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                            const CompanyPartnerDashboard(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Citizen requests and partner administration.
              Row(
                children: [
                  Expanded(
                    child: _FeatureCard(
                      icon: Icons.assignment_outlined,
                      title: 'طلباتي للشركات',
                      subtitle: 'متابعة حالة التسليم',
                      color: const Color(0xFFDDEFFC),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                            const CitizenPartnerRequestsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _FeatureCard(
                      icon: Icons.admin_panel_settings_outlined,
                      title: 'إدارة الشراكات',
                      subtitle: 'اعتماد ومراجعة الشركات',
                      color: const Color(0xFFFFE5E5),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                            const PartnerAdminScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              const Text(
                'Your Environmental Impact',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: darkGreen,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Your verified impact appears here as you use GreenPulse AI.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: Color(0xFF718276),
                ),
              ),

              const SizedBox(height: 16),

              // Reports count.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFE4ECE5),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.eco_outlined,
                      size: 35,
                      color: green,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$_reportCount Verified Report'
                                '${_reportCount == 1 ? '' : 's'} Filed',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: darkGreen,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Every report submitted helps local communities '
                                'stay clean and sustainable.',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.5,
                              color: Color(0xFF617267),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFE4ECE5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF16865C),
                  size: 27,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF145A3A),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF718276),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}