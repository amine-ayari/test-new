// TODO Implement this library.

import 'package:flutter_activity_app/models/user.dart';
import 'package:flutter_activity_app/models/verification_document.dart';
import 'dart:io';

abstract class VerificationRepository {
  Future<List<VerificationDocument>> getProviderDocuments(String providerId);
  Future<VerificationDocument> submitDocument({
    required String providerId,
    required String documentType,
    required String documentNumber,
    required File documentFile,
  });
  Future<VerificationDocument> updateDocumentStatus({
    required String documentId,
    required VerificationStatus status,
    String? rejectionReason,
  });
  Future<bool> deleteDocument(String documentId);
}
