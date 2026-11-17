import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'partner_models.dart';
import 'partner_service.dart';

class CitizenPartnerRequestsScreen extends StatelessWidget {
  const CitizenPartnerRequestsScreen({super.key});

  static const Color green = Color(0xFF16865C);
  static const Color darkGreen = Color(0xFF145A3A);
  static const Color background = Color(0xFFF4F8F3);

  Color _getStatusColor(RequestStatus status) {
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

  String _getStatusText(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return 'قيد الانتظار (Pending)';
      case RequestStatus.accepted:
        return 'مقبول وفي التنفيذ (Accepted)';
      case RequestStatus.completed:
        return 'تم التسليم واكتمل (Completed)';
      case RequestStatus.cancelled:
        return 'تم الإلغاء (Cancelled)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: darkGreen,
        elevation: 0,
        title: const Text(
          'طلبات التعامل مع الشركات',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: user == null
            ? const Center(
                child: Text('يرجى تسجيل الدخول لمتابعة طلباتك.'),
              )
            : StreamBuilder<List<PartnerRequest>>(
                stream: PartnerService.instance.getCitizenRequestsStream(user.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: green),
                    );
                  }

                  final requests = snapshot.data ?? [];
                  if (requests.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.assignment_outlined,
                              size: 70,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'لا توجد طلبات تعامل أرسلتها حتى الآن.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF617267),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      final req = requests[index];
                      final statusColor = _getStatusColor(req.status);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
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
                                    req.companyName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: darkGreen,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _getStatusText(req.status),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text('الفرع: ${req.branchName}', style: const TextStyle(fontSize: 13)),
                            Text('نوع المخلفات: ${req.wasteType}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                            Text('الكمية: ${req.quantity}', style: const TextStyle(fontSize: 13)),
                            Text('العنوان: ${req.address}', style: const TextStyle(fontSize: 13, color: Color(0xFF617267))),
                            if (req.notes.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text('ملاحظات: ${req.notes}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}
