// TODO Implement this library.


import 'package:equatable/equatable.dart';
import 'package:flutter_activity_app/models/user.dart';

import 'dart:io';

abstract class VerificationEvent extends Equatable {
  const VerificationEvent();

  @override
  List<Object?> get props => [];
}

class LoadProviderDocuments extends VerificationEvent {
  final String providerId;

  const LoadProviderDocuments(this.providerId);

  @override
  List<Object> get props => [providerId];
}

class SubmitDocument extends VerificationEvent {
  final String providerId;
  final String documentType;
  final String documentNumber;
  final File documentFile;

  const SubmitDocument({
    required this.providerId,
    required this.documentType,
    required this.documentNumber,
    required this.documentFile,
  });

  @override
  List<Object> get props => [providerId, documentType, documentNumber, documentFile];
}

class UpdateDocumentStatus extends VerificationEvent {
  final String documentId;
  final VerificationStatus status;
  final String? rejectionReason;

  const UpdateDocumentStatus({
    required this.documentId,
    required this.status,
    this.rejectionReason,
  });

  @override
  List<Object?> get props => [documentId, status, rejectionReason];
}

class DeleteDocument extends VerificationEvent {
  final String documentId;

  const DeleteDocument(this.documentId);

  @override
  List<Object> get props => [documentId];
}

class UpdateProviderVerificationInfo extends VerificationEvent {
  final String providerId;
  final String? businessName;
  final String? taxId;
  final String? nationalId;

  const UpdateProviderVerificationInfo({
    required this.providerId,
    this.businessName,
    this.taxId,
    this.nationalId,
  });

  @override
  List<Object?> get props => [providerId, businessName, taxId, nationalId];
}

class GetProviderVerificationStatus extends VerificationEvent {
  final String providerId;

  const GetProviderVerificationStatus(this.providerId);

  @override
  List<Object> get props => [providerId];
}
