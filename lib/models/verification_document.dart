// TODO Implement this library.

import 'package:equatable/equatable.dart';
import 'package:flutter_activity_app/models/user.dart';



class VerificationDocument extends Equatable {
  final String id;
  final String providerId;
  final String documentType;
  final String documentNumber;
  final String? documentUrl;
  final VerificationStatus status;
  final String? rejectionReason;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;

  const VerificationDocument({
    required this.id,
    required this.providerId,
    required this.documentType,
    required this.documentNumber,
    this.documentUrl,
    required this.status,
    this.rejectionReason,
    required this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
  });

  factory VerificationDocument.fromJson(Map<String, dynamic> json) {
    return VerificationDocument(
      id: json['_id'] ?? json['id'] ?? '',
      providerId: json['providerId'] ?? '',
      documentType: json['documentType'] ?? '',
      documentNumber: json['documentNumber'] ?? '',
      documentUrl: json['documentUrl'],
      status: _parseStatus(json['status']),
      rejectionReason: json['rejectionReason'],
      submittedAt: json['submittedAt'] != null
          ? DateTime.parse(json['submittedAt'])
          : DateTime.now(),
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.parse(json['reviewedAt'])
          : null,
      reviewedBy: json['reviewedBy'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'providerId': providerId,
      'documentType': documentType,
      'documentNumber': documentNumber,
      'documentUrl': documentUrl,
      'status': status.toString().split('.').last,
      'rejectionReason': rejectionReason,
      'submittedAt': submittedAt.toIso8601String(),
      'reviewedAt': reviewedAt?.toIso8601String(),
      'reviewedBy': reviewedBy,
    };
  }

  static VerificationStatus _parseStatus(String? status) {
    if (status == null) return VerificationStatus.pending;
    
    switch (status.toLowerCase()) {
      case 'approved':
        return VerificationStatus.approved;
      case 'rejected':
        return VerificationStatus.rejected;
      default:
        return VerificationStatus.pending;
    }
  }

  @override
  List<Object?> get props => [
    id,
    providerId,
    documentType,
    documentNumber,
    documentUrl,
    status,
    rejectionReason,
    submittedAt,
    reviewedAt,
    reviewedBy,
  ];

  VerificationDocument copyWith({
    String? id,
    String? providerId,
    String? documentType,
    String? documentNumber,
    String? documentUrl,
    VerificationStatus? status,
    String? rejectionReason,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
  }) {
    return VerificationDocument(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      documentType: documentType ?? this.documentType,
      documentNumber: documentNumber ?? this.documentNumber,
      documentUrl: documentUrl ?? this.documentUrl,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
    );
  }
}
