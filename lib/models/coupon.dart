import 'package:equatable/equatable.dart';

enum CouponType {
  percentage,
  fixedAmount
}

enum CouponStatus {
  active,
  expired,
  used,
  pending
}

class Coupon extends Equatable {
  final String id;
  final String code;
  final String activityId;
  final String? providerId;
  final CouponType type;
  final double value;
  final DateTime validFrom;
  final DateTime validUntil;
  final int maxUses;
  final int currentUses;
  final CouponStatus status;
  final String? description;
  final bool isNegotiable;
  final bool isApproved;
  final String createdBy; // admin ID
  
  const Coupon({
    required this.id,
    required this.code,
    required this.activityId,
    this.providerId,
    required this.type,
    required this.value,
    required this.validFrom,
    required this.validUntil,
    required this.maxUses,
    this.currentUses = 0,
    this.status = CouponStatus.active,
    this.description,
    this.isNegotiable = false,
    this.isApproved = false,
    required this.createdBy,
  });

  @override
  List<Object?> get props => [
    id, code, activityId, providerId, type, value, validFrom, validUntil,
    maxUses, currentUses, status, description, isNegotiable, isApproved, createdBy
  ];

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      id: json['id'] ?? json['_id'] ?? '',
      code: json['code'] ?? '',
      activityId: json['activityId'] ?? '',
      providerId: json['providerId'],
      type: _parseCouponType(json['type']),
      value: (json['value'] ?? 0).toDouble(),
      validFrom: json['validFrom'] != null ? DateTime.parse(json['validFrom']) : DateTime.now(),
      validUntil: json['validUntil'] != null ? DateTime.parse(json['validUntil']) : DateTime.now().add(const Duration(days: 30)),
      maxUses: json['maxUses'] ?? 0,
      currentUses: json['currentUses'] ?? 0,
      status: _parseCouponStatus(json['status']),
      description: json['description'],
      isNegotiable: json['isNegotiable'] ?? false,
      isApproved: json['isApproved'] ?? false,
      createdBy: json['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'activityId': activityId,
      'providerId': providerId,
      'type': type.toString().split('.').last,
      'value': value,
      'validFrom': validFrom.toIso8601String(),
      'validUntil': validUntil.toIso8601String(),
      'maxUses': maxUses,
      'currentUses': currentUses,
      'status': status.toString().split('.').last,
      'description': description,
      'isNegotiable': isNegotiable,
      'isApproved': isApproved,
      'createdBy': createdBy,
    };
  }

  static CouponType _parseCouponType(String? typeStr) {
    switch (typeStr?.toLowerCase()) {
      case 'percentage':
        return CouponType.percentage;
      case 'fixedamount':
      default:
        return CouponType.fixedAmount;
    }
  }

  static CouponStatus _parseCouponStatus(String? statusStr) {
    switch (statusStr?.toLowerCase()) {
      case 'expired':
        return CouponStatus.expired;
      case 'used':
        return CouponStatus.used;
      case 'pending':
        return CouponStatus.pending;
      case 'active':
      default:
        return CouponStatus.active;
    }
  }

  Coupon copyWith({
    String? id,
    String? code,
    String? activityId,
    String? providerId,
    CouponType? type,
    double? value,
    DateTime? validFrom,
    DateTime? validUntil,
    int? maxUses,
    int? currentUses,
    CouponStatus? status,
    String? description,
    bool? isNegotiable,
    bool? isApproved,
    String? createdBy,
  }) {
    return Coupon(
      id: id ?? this.id,
      code: code ?? this.code,
      activityId: activityId ?? this.activityId,
      providerId: providerId ?? this.providerId,
      type: type ?? this.type,
      value: value ?? this.value,
      validFrom: validFrom ?? this.validFrom,
      validUntil: validUntil ?? this.validUntil,
      maxUses: maxUses ?? this.maxUses,
      currentUses: currentUses ?? this.currentUses,
      status: status ?? this.status,
      description: description ?? this.description,
      isNegotiable: isNegotiable ?? this.isNegotiable,
      isApproved: isApproved ?? this.isApproved,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  bool get isValid {
    final now = DateTime.now();
    return status == CouponStatus.active && 
           now.isAfter(validFrom) && 
           now.isBefore(validUntil) && 
           (maxUses == 0 || currentUses < maxUses) &&
           isApproved;
  }

  double calculateDiscount(double originalPrice) {
    if (!isValid) return 0;
    
    if (type == CouponType.percentage) {
      return originalPrice * (value / 100);
    } else {
      return value > originalPrice ? originalPrice : value;
    }
  }
}

class CouponNegotiation extends Equatable {
  final String id;
  final String couponId;
  final String providerId;
  final String adminId;
  final double proposedValue;
  final String message;
  final DateTime createdAt;
  final bool isProviderProposal;
  final String status; // 'pending', 'accepted', 'rejected'
  
  const CouponNegotiation({
    required this.id,
    required this.couponId,
    required this.providerId,
    required this.adminId,
    required this.proposedValue,
    required this.message,
    required this.createdAt,
    required this.isProviderProposal,
    required this.status,
  });

  @override
  List<Object?> get props => [
    id, couponId, providerId, adminId, proposedValue, message, 
    createdAt, isProviderProposal, status
  ];

  factory CouponNegotiation.fromJson(Map<String, dynamic> json) {
    return CouponNegotiation(
      id: json['id'] ?? json['_id'] ?? '',
      couponId: json['couponId'] ?? '',
      providerId: json['providerId'] ?? '',
      adminId: json['adminId'] ?? '',
      proposedValue: (json['proposedValue'] ?? 0).toDouble(),
      message: json['message'] ?? '',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      isProviderProposal: json['isProviderProposal'] ?? false,
      status: json['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'couponId': couponId,
      'providerId': providerId,
      'adminId': adminId,
      'proposedValue': proposedValue,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'isProviderProposal': isProviderProposal,
      'status': status,
    };
  }
}
