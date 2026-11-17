import 'package:flutter/material.dart';
import 'partner_models.dart';
import 'partner_service.dart';

class PartnerAdminScreen extends StatefulWidget {
  const PartnerAdminScreen({super.key});

  @override
  State<PartnerAdminScreen> createState() => _PartnerAdminScreenState();
}

class _PartnerAdminScreenState extends State<PartnerAdminScreen> {
  static const Color green = Color(0xFF16865C);
  static const Color darkGreen = Color(0xFF145A3A);
  static const Color background = Color(0xFFF4F8F3);

  PartnerStatus? _selectedFilter;
  List<PartnerCompany> _companies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  Future<void> _loadCompanies() async {
    setState(() => _isLoading = true);
    final list = await PartnerService.instance.getCompaniesByStatus(_selectedFilter);
    if (mounted) {
      setState(() {
        _companies = list;
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(PartnerStatus status) {
    switch (status) {
      case PartnerStatus.approved:
        return green;
      case PartnerStatus.pending:
        return Colors.orange.shade800;
      case PartnerStatus.rejected:
        return Colors.red.shade800;
      case PartnerStatus.suspended:
        return Colors.grey.shade700;
    }
  }

  void _showUpdateStatusDialog(PartnerCompany comp) {
    PartnerStatus newStatus = comp.status;
    final notesController = TextEditingController(text: comp.adminNotes);

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('إدارة اعتماد: ${comp.companyName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('تغيير حالة الشراكة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              DropdownButtonFormField<PartnerStatus>(
                initialValue: newStatus,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: PartnerStatus.values
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s.name.toUpperCase()),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => newStatus = val);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: InputDecoration(
                  labelText: 'ملاحظات الإدارة للشركة',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(dialogContext);
                try {
                  await PartnerService.instance.updateCompanyStatus(
                    comp.companyId,
                    newStatus,
                    adminNotes: notesController.text.trim(),
                  );
                  await _loadCompanies();
                  if (!mounted) return;
                  messenger.showSnackBar(
                    const SnackBar(content: Text('تم تحديث حالة الشركة بنجاح!'), backgroundColor: green),
                  );
                } catch (e) {
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(content: Text('خطأ في التحديث: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                foregroundColor: Colors.white,
              ),
              child: const Text('حفظ القرار'),
            ),
          ],
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
        title: const Text(
          'إدارة الشركاء واعتماد الشركات',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filters
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('الكل'),
                      selected: _selectedFilter == null,
                      onSelected: (_) {
                        setState(() => _selectedFilter = null);
                        _loadCompanies();
                      },
                    ),
                    const SizedBox(width: 8),
                    ...PartnerStatus.values.map((status) {
                      final isSelected = _selectedFilter == status;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(status.name.toUpperCase()),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() => _selectedFilter = status);
                            _loadCompanies();
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: green))
                    : _companies.isEmpty
                        ? const Center(child: Text('لا توجد شركات مطابقة للفلتر.'))
                        : ListView.builder(
                            itemCount: _companies.length,
                            itemBuilder: (context, index) {
                              final comp = _companies[index];
                              final color = _getStatusColor(comp.status);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: const Color(0xFFE2EAE3)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            comp.companyName,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: darkGreen,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: color.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            comp.status.name.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: color,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text('الوصف: ${comp.activityDescription}', style: const TextStyle(fontSize: 13, color: Color(0xFF617267))),
                                    Text('السجل التجاري: ${comp.licenseNumber}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    Text('البريد: ${comp.email} | الهاتف: ${comp.phone}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    const SizedBox(height: 10),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: ElevatedButton.icon(
                                        onPressed: () => _showUpdateStatusDialog(comp),
                                        icon: const Icon(Icons.admin_panel_settings_outlined, size: 16),
                                        label: const Text('مراجعة وتغيير الحالة'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: green,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
