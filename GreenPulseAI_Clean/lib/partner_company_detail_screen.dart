import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'auth_service.dart';
import 'partner_models.dart';
import 'partner_service.dart';

class PartnerCompanyDetailScreen extends StatefulWidget {
  const PartnerCompanyDetailScreen({
    super.key,
    required this.company,
  });

  final PartnerCompany company;

  @override
  State<PartnerCompanyDetailScreen> createState() =>
      _PartnerCompanyDetailScreenState();
}

class _PartnerCompanyDetailScreenState
    extends State<PartnerCompanyDetailScreen> {
  static const Color green = Color(0xFF16865C);
  static const Color darkGreen = Color(0xFF145A3A);
  static const Color background = Color(0xFFF4F8F3);

  late CompanyBranch _selectedBranch;

  @override
  void initState() {
    super.initState();
    _selectedBranch = widget.company.branches.isNotEmpty
        ? widget.company.branches.first
        : CompanyBranch(
            branchId: 'b1',
            branchName: 'الفرع الرئيسي',
            address: 'العنوان غير محدد',
            latitude: 30.0444,
            longitude: 31.2357,
            phone: widget.company.phone,
            workingHours: '9:00 ص - 5:00 م',
          );
  }

  Future<void> _makePhoneCall(String phone) async {
    final Uri uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsapp(String phone) async {
    var formatted = phone.replaceAll(RegExp(r'\D'), '');
    if (formatted.startsWith('01')) formatted = '2$formatted';
    final Uri uri = Uri.parse('https://wa.me/$formatted');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showCreateDealDialog() async {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تسجيل الدخول أولاً لإرسال طلب تعامل.')),
      );
      return;
    }

    final profile = await AuthService.instance.getUserProfile();
    final citizenName = profile?.fullName ?? 'مواطن GreenPulse';
    final citizenPhone = profile?.phone ?? '';

    final wasteTypeController = TextEditingController(
      text: widget.company.acceptedWasteTypes.isNotEmpty
          ? widget.company.acceptedWasteTypes.first
          : 'بلاستيك',
    );
    final quantityController = TextEditingController(text: '10 كجم');
    final addressController = TextEditingController();
    final notesController = TextEditingController();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'طلب تسليم مخلفات لـ ${widget.company.companyName}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: darkGreen,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(sheetContext),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: widget.company.acceptedWasteTypes.contains(wasteTypeController.text)
                    ? wasteTypeController.text
                    : (widget.company.acceptedWasteTypes.isNotEmpty
                        ? widget.company.acceptedWasteTypes.first
                        : null),
                decoration: InputDecoration(
                  labelText: 'نوع المخلفات',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: widget.company.acceptedWasteTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) wasteTypeController.text = val;
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: quantityController,
                decoration: InputDecoration(
                  labelText: 'الكمية التقديرية (كجم / عدد القطع)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: InputDecoration(
                  labelText: 'عنوان الاستلام / التسليم التفصيلي',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'ملاحظات إضافية للشركة',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    if (addressController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(sheetContext).showSnackBar(
                        const SnackBar(content: Text('يرجى إدخال العنوان')),
                      );
                      return;
                    }

                    final req = PartnerRequest(
                      requestId: '',
                      citizenUid: user.uid,
                      citizenName: citizenName,
                      citizenPhone: citizenPhone,
                      companyId: widget.company.companyId,
                      companyName: widget.company.companyName,
                      branchId: _selectedBranch.branchId,
                      branchName: _selectedBranch.branchName,
                      wasteType: wasteTypeController.text,
                      quantity: quantityController.text.trim(),
                      address: addressController.text.trim(),
                      notes: notesController.text.trim(),
                      status: RequestStatus.pending,
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    );

                    Navigator.pop(sheetContext);

                    try {
                      await PartnerService.instance.createPartnerRequest(req);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم إرسال طلب التعامل للشركة بنجاح! يمكنك متابعته من قسم الطلبات.'),
                          backgroundColor: green,
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('خطأ أثناء إرسال الطلب: $e')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('إرسال طلب التعامل الآن', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: darkGreen,
        elevation: 0,
        title: Text(
          widget.company.companyName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2EAE3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCF3E5),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.business_rounded, color: green, size: 32),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.company.companyName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: darkGreen,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.verified_rounded, color: green, size: 16),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'شركة معتمدة رسمياً',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.company.activityDescription,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF617267), height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Accepted Waste Types
              const Text(
                'أنواع المخلفات التي تستقبلها الشركة',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkGreen),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.company.acceptedWasteTypes.map((type) {
                  return Chip(
                    backgroundColor: const Color(0xFFDCF3E5),
                    avatar: const Icon(Icons.recycling_rounded, color: green, size: 18),
                    label: Text(
                      type,
                      style: const TextStyle(color: darkGreen, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              // Contact options
              const Text(
                'التواصل المباشر مع الشركة',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkGreen),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _makePhoneCall(widget.company.phone),
                      icon: const Icon(Icons.phone_rounded, color: green),
                      label: const Text('اتصال', style: TextStyle(color: green)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: green),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  if (widget.company.whatsapp.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openWhatsapp(widget.company.whatsapp),
                        icon: const Icon(Icons.chat_rounded, color: Colors.white),
                        label: const Text('واتساب'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),
              // Branches
              const Text(
                'فروع ومواقع الاستقبال',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkGreen),
              ),
              const SizedBox(height: 10),
              ...widget.company.branches.map((branch) {
                final isSelected = branch.branchId == _selectedBranch.branchId;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedBranch = branch);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFDCF3E5) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? green : const Color(0xFFE2EAE3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded, color: isSelected ? green : Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              branch.branchName,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? darkGreen : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('العنوان: ${branch.address}', style: const TextStyle(fontSize: 13, color: Color(0xFF617267))),
                        Text('ساعات العمل: ${branch.workingHours}', style: const TextStyle(fontSize: 12, color: Color(0xFF617267))),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 28),
              // Action Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _showCreateDealDialog,
                  icon: const Icon(Icons.handshake_rounded),
                  label: const Text(
                    'تقديم طلب تسليم / تعامل مع هذه الشركة',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
