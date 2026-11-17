import 'package:cloud_firestore/cloud_firestore.dart';

enum PartnerStatus {
  pending,
  approved,
  rejected,
  suspended,
}

enum RequestStatus {
  pending,
  accepted,
  completed,
  cancelled,
}

class CompanyBranch {
  final String branchId;
  final String branchName;
  final String address;
  final double latitude;
  final double longitude;
  final String phone;
  final String workingHours;

  CompanyBranch({
    required this.branchId,
    required this.branchName,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.phone,
    required this.workingHours,
  });

  factory CompanyBranch.fromMap(Map<String, dynamic> map) {
    return CompanyBranch(
      branchId: map['branchId']?.toString() ?? '',
      branchName: map['branchName']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 30.0444,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 31.2357,
      phone: map['phone']?.toString() ?? '',
      workingHours: map['workingHours']?.toString() ?? '9:00 AM - 5:00 PM',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'branchId': branchId,
      'branchName': branchName,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone,
      'workingHours': workingHours,
    };
  }
}

class PartnerCompany {
  final String companyId;
  final String ownerUid;
  final String companyName;
  final String activityDescription;
  final String email;
  final String phone;
  final String whatsapp;
  final String licenseNumber;
  final List<String> acceptedWasteTypes;
  final List<CompanyBranch> branches;
  final PartnerStatus status;
  final String adminNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  PartnerCompany({
    required this.companyId,
    required this.ownerUid,
    required this.companyName,
    required this.activityDescription,
    required this.email,
    required this.phone,
    required this.whatsapp,
    required this.licenseNumber,
    required this.acceptedWasteTypes,
    required this.branches,
    required this.status,
    this.adminNotes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  factory PartnerCompany.fromFirestore(Map<String, dynamic> data, String id) {
    List<CompanyBranch> parsedBranches = [];
    if (data['branches'] != null && data['branches'] is List) {
      parsedBranches = (data['branches'] as List)
          .map((b) => CompanyBranch.fromMap(Map<String, dynamic>.from(b as Map)))
          .toList();
    }

    List<String> wasteTypes = [];
    if (data['acceptedWasteTypes'] != null && data['acceptedWasteTypes'] is List) {
      wasteTypes = (data['acceptedWasteTypes'] as List)
          .map((e) => e.toString())
          .toList();
    }

    PartnerStatus statusEnum = PartnerStatus.pending;
    final statusStr = data['status']?.toString().toLowerCase() ?? 'pending';
    if (statusStr == 'approved') {
      statusEnum = PartnerStatus.approved;
    } else if (statusStr == 'rejected') {
      statusEnum = PartnerStatus.rejected;
    } else if (statusStr == 'suspended') {
      statusEnum = PartnerStatus.suspended;
    }

    return PartnerCompany(
      companyId: id,
      ownerUid: data['ownerUid']?.toString() ?? '',
      companyName: data['companyName']?.toString() ?? '',
      activityDescription: data['activityDescription']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      whatsapp: data['whatsapp']?.toString() ?? '',
      licenseNumber: data['licenseNumber']?.toString() ?? '',
      acceptedWasteTypes: wasteTypes,
      branches: parsedBranches,
      status: statusEnum,
      adminNotes: data['adminNotes']?.toString() ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ownerUid': ownerUid,
      'companyName': companyName,
      'activityDescription': activityDescription,
      'email': email,
      'phone': phone,
      'whatsapp': whatsapp,
      'licenseNumber': licenseNumber,
      'acceptedWasteTypes': acceptedWasteTypes,
      'branches': branches.map((b) => b.toMap()).toList(),
      'status': status.name,
      'adminNotes': adminNotes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

class PartnerRequest {
  final String requestId;
  final String citizenUid;
  final String citizenName;
  final String citizenPhone;
  final String companyId;
  final String companyName;
  final String branchId;
  final String branchName;
  final String wasteType;
  final String quantity;
  final String address;
  final String notes;
  final RequestStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  PartnerRequest({
    required this.requestId,
    required this.citizenUid,
    required this.citizenName,
    required this.citizenPhone,
    required this.companyId,
    required this.companyName,
    required this.branchId,
    required this.branchName,
    required this.wasteType,
    required this.quantity,
    required this.address,
    required this.notes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PartnerRequest.fromFirestore(Map<String, dynamic> data, String id) {
    RequestStatus statusEnum = RequestStatus.pending;
    final statusStr = data['status']?.toString().toLowerCase() ?? 'pending';
    if (statusStr == 'accepted') {
      statusEnum = RequestStatus.accepted;
    } else if (statusStr == 'completed') {
      statusEnum = RequestStatus.completed;
    } else if (statusStr == 'cancelled') {
      statusEnum = RequestStatus.cancelled;
    }

    return PartnerRequest(
      requestId: id,
      citizenUid: data['citizenUid']?.toString() ?? '',
      citizenName: data['citizenName']?.toString() ?? '',
      citizenPhone: data['citizenPhone']?.toString() ?? '',
      companyId: data['companyId']?.toString() ?? '',
      companyName: data['companyName']?.toString() ?? '',
      branchId: data['branchId']?.toString() ?? '',
      branchName: data['branchName']?.toString() ?? '',
      wasteType: data['wasteType']?.toString() ?? '',
      quantity: data['quantity']?.toString() ?? '',
      address: data['address']?.toString() ?? '',
      notes: data['notes']?.toString() ?? '',
      status: statusEnum,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'citizenUid': citizenUid,
      'citizenName': citizenName,
      'citizenPhone': citizenPhone,
      'companyId': companyId,
      'companyName': companyName,
      'branchId': branchId,
      'branchName': branchName,
      'wasteType': wasteType,
      'quantity': quantity,
      'address': address,
      'notes': notes,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
