import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'partner_models.dart';
import 'partner_service.dart';

class PartnerRegisterScreen extends StatefulWidget {
  const PartnerRegisterScreen({super.key});

  @override
  State<PartnerRegisterScreen> createState() => _PartnerRegisterScreenState();
}

class _PartnerRegisterScreenState extends State<PartnerRegisterScreen> {
  static const Color green = Color(0xFF16865C);
  static const Color darkGreen = Color(0xFF145A3A);
  static const Color background = Color(0xFFF4F8F3);

  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _licenseController = TextEditingController();

  // Branch Controllers
  final _branchNameController = TextEditingController(text: 'الفرع الرئيسي');
  final _branchAddressController = TextEditingController();
  final _branchPhoneController = TextEditingController();
  final _branchHoursController = TextEditingController(text: '9:00 ص - 6:00 م');
  final _latController = TextEditingController(text: '30.0444');
  final _lngController = TextEditingController(text: '31.2357');

  bool _isSubmitting = false;

  final List<String> _allWasteTypes = [
    'بلاستيك',
    'نفايات إلكترونية',
    'معادن وألومنيوم',
    'ورق وكرتون',
    'زجاج وعبوات',
    'نفايات عضوية',
    'أدوات منزلية قديمة',
  ];

  final List<String> _selectedWasteTypes = ['بلاستيك'];

  @override
  void initState() {
    super.initState();
    final user = AuthService.instance.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? '';
    }
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _descriptionController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _licenseController.dispose();
    _branchNameController.dispose();
    _branchAddressController.dispose();
    _branchPhoneController.dispose();
    _branchHoursController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;

    if (_selectedWasteTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار نوع واحد على الأقل من المخلفات القابلة للاستلام.')),
      );
      return;
    }

    final user = AuthService.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تسجيل الدخول أولاً لتسجيل الشركة.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final mainBranch = CompanyBranch(
        branchId: 'branch_1',
        branchName: _branchNameController.text.trim(),
        address: _branchAddressController.text.trim(),
        latitude: double.tryParse(_latController.text.trim()) ?? 30.0444,
        longitude: double.tryParse(_lngController.text.trim()) ?? 31.2357,
        phone: _branchPhoneController.text.trim().isNotEmpty
            ? _branchPhoneController.text.trim()
            : _phoneController.text.trim(),
        workingHours: _branchHoursController.text.trim(),
      );

      final company = PartnerCompany(
        companyId: '',
        ownerUid: user.uid,
        companyName: _companyNameController.text.trim(),
        activityDescription: _descriptionController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        whatsapp: _whatsappController.text.trim(),
        licenseNumber: _licenseController.text.trim(),
        acceptedWasteTypes: _selectedWasteTypes,
        branches: [mainBranch],
        status: PartnerStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await PartnerService.instance.registerPartnerCompany(company);

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تقديم طلب الشراكة بنجاح! طلبك قيد مراجعة الإدارة (Pending).'),
          backgroundColor: green,
          duration: Duration(seconds: 4),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل تقديم الطلب: $e'), backgroundColor: Colors.red),
      );
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
          'تسجيل شركة شريكة (Partner)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2EAE3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCF3E5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.handshake_rounded, color: green, size: 28),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'انضم كشريك رسمي لـ GreenPulse AI',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: darkGreen,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'سيتم مراجعة طلبك من الإدارة واعتماده لظهور فروعكم ومستلماتكم للمواطنين.',
                              style: TextStyle(fontSize: 12, color: Color(0xFF718276)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'بيانات الشركة الأساسية',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkGreen),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _companyNameController,
                  decoration: InputDecoration(
                    labelText: 'اسم الشركة / المؤسسة',
                    prefixIcon: const Icon(Icons.business_rounded, color: green),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'يرجى إدخال اسم الشركة' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'وصف نشاط الشركة والمخلفات المستهدفة',
                    prefixIcon: const Icon(Icons.description_outlined, color: green),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'يرجى إدخال وصف نشاط الشركة' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'البريد الإلكتروني للشركة',
                    prefixIcon: const Icon(Icons.email_outlined, color: green),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'يرجى إدخال البريد الإلكتروني' : null,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'رقم الهاتف',
                          prefixIcon: const Icon(Icons.phone_outlined, color: green),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'يرجى إدخال رقم الهاتف' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _whatsappController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'واتساب التواصل',
                          prefixIcon: const Icon(Icons.chat_outlined, color: green),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _licenseController,
                  decoration: InputDecoration(
                    labelText: 'رقم السجل التجاري / الترخيص البيئي',
                    prefixIcon: const Icon(Icons.verified_user_outlined, color: green),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'يرجى إدخال رقم السجل/الترخيص' : null,
                ),
                const SizedBox(height: 20),
                const Text(
                  'أنواع المخلفات المقبولة بالشركة',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkGreen),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _allWasteTypes.map((type) {
                    final isSelected = _selectedWasteTypes.contains(type);
                    return FilterChip(
                      selected: isSelected,
                      label: Text(type),
                      selectedColor: const Color(0xFFDCF3E5),
                      checkmarkColor: green,
                      labelStyle: TextStyle(
                        color: isSelected ? darkGreen : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            _selectedWasteTypes.add(type);
                          } else {
                            _selectedWasteTypes.remove(type);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                const Text(
                  'بيانات الفرع الرئيسي للشركة',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkGreen),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _branchNameController,
                  decoration: InputDecoration(
                    labelText: 'اسم الفرع',
                    prefixIcon: const Icon(Icons.location_city_outlined, color: green),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _branchAddressController,
                  decoration: InputDecoration(
                    labelText: 'عنوان الفرع التفصيلي',
                    prefixIcon: const Icon(Icons.place_outlined, color: green),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'يرجى إدخال عنوان الفرع' : null,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'خط العرض (Latitude)',
                          prefixIcon: const Icon(Icons.map_outlined, color: green),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _lngController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'خط الطول (Longitude)',
                          prefixIcon: const Icon(Icons.map_outlined, color: green),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _branchHoursController,
                  decoration: InputDecoration(
                    labelText: 'مواعيد العمل (مثلاً: 9:00 ص - 5:00 م)',
                    prefixIcon: const Icon(Icons.access_time_rounded, color: green),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitApplication,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'تقديم طلب الشراكة',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
