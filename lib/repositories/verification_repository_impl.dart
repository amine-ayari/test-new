

import 'dart:io';
import 'package:flutter_activity_app/models/user.dart';
import 'package:flutter_activity_app/models/verification_document.dart';
import 'package:flutter_activity_app/repositories/verification_repository.dart';
import 'package:flutter_activity_app/services/api_service.dart';
import 'package:flutter_activity_app/services/exceptions.dart';
import 'dart:convert';

class VerificationRepositoryImpl implements VerificationRepository {
  final ApiService _apiService;

  VerificationRepositoryImpl({required ApiService apiService})
      : _apiService = apiService;

  @override
  Future<List<VerificationDocument>> getProviderDocuments(String providerId) async {
    try {
      final response = await _apiService.getWithAuth('/verification/provider/$providerId');
      
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> documentsJson = response['data'];
        return documentsJson
            .map((json) => VerificationDocument.fromJson(json))
            .toList();
      } else {
        throw ApiException(
          message: 'Failed to get provider documents: ${response['message'] ?? 'Unknown error'}',
          statusCode: 400,
          responseBody: json.encode(response),
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Error getting provider documents: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<VerificationDocument> submitDocument({
    required String providerId,
    required String documentType,
    required String documentNumber,
    required File documentFile,
  }) async {
    try {
      // First, upload the document file
      final List<String> uploadedUrls = await _apiService.uploadImages([documentFile]);
      
      if (uploadedUrls.isEmpty) {
        throw ApiException(
          message: 'Failed to upload document file',
          statusCode: 400,
        );
      }
      
      // Then, create the document record with the uploaded URL
      final documentData = {
        'providerId': providerId,
        'documentType': documentType,
        'documentNumber': documentNumber,
        'documentUrl': uploadedUrls.first,
      };
      
      final response = await _apiService.postWithAuth('/verification/documents', documentData);
      
      if (response['success'] == true && response['data'] != null) {
        return VerificationDocument.fromJson(response['data']);
      } else {
        throw ApiException(
          message: 'Failed to submit document: ${response['message'] ?? 'Unknown error'}',
          statusCode: 400,
          responseBody: json.encode(response),
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Error submitting document: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<VerificationDocument> updateDocumentStatus({
    required String documentId,
    required VerificationStatus status,
    String? rejectionReason,
  }) async {
    try {
      final updateData = {
        'status': status.toString().split('.').last,
        if (rejectionReason != null) 'rejectionReason': rejectionReason,
      };
      
      final response = await _apiService.put(
        '/verification/documents/$documentId',
        updateData,
      );
      
      if (response['success'] == true && response['data'] != null) {
        return VerificationDocument.fromJson(response['data']);
      } else {
        throw ApiException(
          message: 'Failed to update document status: ${response['message'] ?? 'Unknown error'}',
          statusCode: 400,
          responseBody: json.encode(response),
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Error updating document status: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<bool> deleteDocument(String documentId) async {
    try {
      final response = await _apiService.delete('/verification/documents/$documentId');
      return response == true;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Error deleting document: $e',
        statusCode: 500,
      );
    }
  }
}
