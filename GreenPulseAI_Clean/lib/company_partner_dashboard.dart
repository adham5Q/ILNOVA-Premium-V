import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'partner_models.dart';
import 'partner_service.dart';

class CompanyPartnerDashboard extends StatefulWidget {
  const CompanyPartnerDashboard({super.key});

  @override
  State<CompanyPartnerDashboard> createState() =>
      _CompanyPartnerDashboardState();
}

class _CompanyPartnerDashboardState extends State<CompanyPartnerDashboard> {
  static const Color green = Color(0xFF16865C);
  static const Color darkGreen = Color(0xFF145A3A);
  static const Color background = Color(0xFFF4F8F3);

  PartnerCompany? _company;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCompanyData();
  }

  Future<void> _loadCompanyData() async {
    setState(() => _isLoading = true);

    final user = AuthService.instance.currentUser;
    if (user != null) {
      final comp = await PartnerService.instance.getCompanyByOwnerUid(user.uid);
      if (mounted) {
        setState(() {
          _company = comp;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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

  String _getStatusText(PartnerStatus status) {
    switch (status) {
      case PartnerStatus.approved:
        return 'معتمدة ومفعلة (Approved)';
      case PartnerStatus.pending:
        return 'قيد المراجعة والإعتماد (Pending)';
      case PartnerStatus.rejected:
        return 'طلب مرفوض (Rejected)';
      case PartnerStatus.suspended:
        return 'حساب معلق (Suspended)';
    }
  }

  Color _getRequestStatusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return Colors.orange.shade800;
      case RequestStatus.accepted:
        return Colors.blue.shade700;
      case RequestStatus.completed:
        return green;
      case RequestStatus.cancelled:
        return Colors.red.shade800;
    }
  }

  String _getRequestStatusText(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return 'جديد (Pending)';
      case RequestStatus.accepted:
        return 'مقبول وفي التنفيذ (Accepted)';
      case RequestStatus.completed:
        return 'مكتمل (Completed)';
      case RequestStatus.cancelled:
        return 'ملغي (Cancelled)';
    }
  }

  void _updateRequestStatus(PartnerRequest req, RequestStatus newStatus) async {
    try {
      await PartnerService.instance.updateRequestStatus(req.requestId, newStatus);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تحديث حالة الطلب إلى: ${_getRequestStatusText(newStatus)}'),
          backgroundColor: green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في التحديث: $e'), backgroundColor: Colors.red),
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
          'لوحة تحكم الشركة الشريكة',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: green))
            : _company == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.business_rounded, size: 70, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text(
                            'لم تقم بتسجيل شركة شريكة بعد.',
                            style: TextStyle(fontSize: 16, color: Color(0xFF617267)),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _loadCompanyData,
                            icon: const Icon(Icons.refresh),
                            label: const Text('إعادة التحديث'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Company Overview Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2EAE3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDCF3E5),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(Icons.business_center_rounded, color: green, size: 28),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _company!.companyName,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: darkGreen,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _company!.email,
                                          style: const TextStyle(fontSize: 13, color: Color(0xFF718276)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(_company!.status).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'الحالة: ${_getStatusText(_company!.status)}',
                                  style: TextStyle(
                                    color: _getStatusColor(_company!.status),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              if (_company!.adminNotes.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'ملاحظات الإدارة: ${_company!.adminNotes}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Incoming Customer Requests Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'طلبات التسليم الواردة من المواطنين',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: darkGreen,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh_rounded, color: green),
                              onPressed: () => setState(() {}),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        StreamBuilder<List<PartnerRequest>>(
                          stream: PartnerService.instance
                              .getCompanyRequestsStream(_company!.companyId),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Padding(
                                padding: EdgeInsets.all(20),
                                child: Center(
                                  child: CircularProgressIndicator(color: green),
                                ),
                              );
                            }

                            final requests = snapshot.data ?? [];
                            if (requests.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Center(
                                  child: Text(
                                    'لا توجد طلبات واردة حالياً من المواطنين.',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              );
                            }

                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: requests.length,
                              itemBuilder: (context, index) {
                                final req = requests[index];
                                final statusColor = _getRequestStatusColor(req.status);

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
                                          Text(
                                            'مواطن: ${req.citizenName}',
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: darkGreen,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: statusColor.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              _getRequestStatusText(req.status),
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: statusColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text('نوع المخلفات: ${req.wasteType}', style: const TextStyle(fontSize: 13)),
                                      Text('الكمية: ${req.quantity}', style: const TextStyle(fontSize: 13)),
                                      Text('العنوان: ${req.address}', style: const TextStyle(fontSize: 13, color: Color(0xFF617267))),
                                      if (req.citizenPhone.isNotEmpty)
                                        Text('الهاتف: ${req.citizenPhone}', style: const TextStyle(fontSize: 13, color: Color(0xFF617267))),
                                      if (req.notes.isNotEmpty)
                                        Text('ملاحظات: ${req.notes}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                      const SizedBox(height: 12),
                                      // Status action buttons
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          if (req.status == RequestStatus.pending) ...[
                                            OutlinedButton(
                                              onPressed: () => _updateRequestStatus(req, RequestStatus.cancelled),
                                              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                              child: const Text('رفض'),
                                            ),
                                            const SizedBox(width: 8),
                                            ElevatedButton(
                                              onPressed: () => _updateRequestStatus(req, RequestStatus.accepted),
                                              style: ElevatedButton.styleFrom(backgroundColor: green, foregroundColor: Colors.white),
                                              child: const Text('قبول الطلب'),
                                            ),
                                          ] else if (req.status == RequestStatus.accepted) ...[
                                            ElevatedButton.icon(
                                              onPressed: () => _updateRequestStatus(req, RequestStatus.completed),
                                              icon: const Icon(Icons.check_circle_rounded, size: 16),
                                              label: const Text('تحديد كمكتمل'),
                                              style: ElevatedButton.styleFrom(backgroundColor: green, foregroundColor: Colors.white),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
