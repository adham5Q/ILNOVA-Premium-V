import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'partner_models.dart';

class PartnerService {
  PartnerService._();
  static final PartnerService instance = PartnerService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection References
  CollectionReference get _companiesRef =>
      _firestore.collection('partner_companies');
  CollectionReference get _requestsRef =>
      _firestore.collection('partner_requests');

  // Register or apply for partner company
  Future<String> registerPartnerCompany(PartnerCompany company) async {
    try {
      final docRef = await _companiesRef.add(company.toFirestore());
      return docRef.id;
    } catch (e) {
      debugPrint('Error registering partner company: $e');
      rethrow;
    }
  }

  // Update company profile
  Future<void> updatePartnerCompany(
      String companyId, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _companiesRef.doc(companyId).set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating partner company: $e');
      rethrow;
    }
  }

  // Fetch company associated with user UID
  Future<PartnerCompany?> getCompanyByOwnerUid(String ownerUid) async {
    try {
      final query = await _companiesRef
          .where('ownerUid', isEqualTo: ownerUid)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        return PartnerCompany.fromFirestore(
          Map<String, dynamic>.from(doc.data() as Map),
          doc.id,
        );
      }
    } catch (e) {
      debugPrint('Error getting company by owner uid: $e');
    }
    return null;
  }

  // Fetch approved companies that accept specific waste type
  Future<List<PartnerCompany>> getApprovedCompaniesForWasteType(
      String wasteType) async {
    try {
      final query = await _companiesRef
          .where('status', isEqualTo: 'approved')
          .get();

      final list = query.docs
          .map((doc) => PartnerCompany.fromFirestore(
                Map<String, dynamic>.from(doc.data() as Map),
                doc.id,
              ))
          .where((company) {
        if (wasteType.isEmpty) return true;
        return company.acceptedWasteTypes.any((type) =>
            type.toLowerCase().contains(wasteType.toLowerCase()) ||
            wasteType.toLowerCase().contains(type.toLowerCase()));
      }).toList();

      return list;
    } catch (e) {
      debugPrint('Error getting approved companies for waste type: $e');
      return [];
    }
  }

  // Fetch all approved companies (e.g. for map rendering)
  Future<List<PartnerCompany>> getAllApprovedCompanies() async {
    try {
      final query = await _companiesRef
          .where('status', isEqualTo: 'approved')
          .get();

      return query.docs
          .map((doc) => PartnerCompany.fromFirestore(
                Map<String, dynamic>.from(doc.data() as Map),
                doc.id,
              ))
          .toList();
    } catch (e) {
      debugPrint('Error getting all approved companies: $e');
      return [];
    }
  }

  // Admin: Fetch companies by status (pending, approved, rejected, suspended, or all)
  Future<List<PartnerCompany>> getCompaniesByStatus(
      PartnerStatus? status) async {
    try {
      Query query = _companiesRef;
      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => PartnerCompany.fromFirestore(
                Map<String, dynamic>.from(doc.data() as Map),
                doc.id,
              ))
          .toList();
    } catch (e) {
      debugPrint('Error getting companies by status: $e');
      return [];
    }
  }

  // Admin: Update company status (approve, reject, suspend)
  Future<void> updateCompanyStatus(
    String companyId,
    PartnerStatus status, {
    String adminNotes = '',
  }) async {
    try {
      await _companiesRef.doc(companyId).update({
        'status': status.name,
        'adminNotes': adminNotes,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating company status: $e');
      rethrow;
    }
  }

  // Citizen: Create a recycling deal request to a company branch
  Future<String> createPartnerRequest(PartnerRequest request) async {
    try {
      final docRef = await _requestsRef.add(request.toFirestore());
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating partner request: $e');
      rethrow;
    }
  }

  // Stream citizen's requests live
  Stream<List<PartnerRequest>> getCitizenRequestsStream(String citizenUid) {
    return _requestsRef
        .where('citizenUid', isEqualTo: citizenUid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PartnerRequest.fromFirestore(
                  Map<String, dynamic>.from(doc.data() as Map),
                  doc.id,
                ))
            .toList());
  }

  // Stream company's incoming requests live
  Stream<List<PartnerRequest>> getCompanyRequestsStream(String companyId) {
    return _requestsRef
        .where('companyId', isEqualTo: companyId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PartnerRequest.fromFirestore(
                  Map<String, dynamic>.from(doc.data() as Map),
                  doc.id,
                ))
            .toList());
  }

  // Update request status (Pending -> Accepted -> Completed / Cancelled)
  Future<void> updateRequestStatus(
      String requestId, RequestStatus status) async {
    try {
      await _requestsRef.doc(requestId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating request status: $e');
      rethrow;
    }
  }
}
