// TODO Implement this library.


import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_activity_app/bloc/verification/verification_event.dart';
import 'package:flutter_activity_app/bloc/verification/verification_state.dart';
import 'package:flutter_activity_app/repositories/verification_repository.dart';
import 'package:flutter_activity_app/repositories/provider_repository.dart';
import 'package:flutter_activity_app/services/exceptions.dart';

class VerificationBloc extends Bloc<VerificationEvent, VerificationState> {
  final VerificationRepository _verificationRepository;
  final ProviderRepository _providerRepository;

  VerificationBloc({
    required VerificationRepository verificationRepository,
    required ProviderRepository providerRepository,
  })  : _verificationRepository = verificationRepository,
        _providerRepository = providerRepository,
        super(VerificationInitial()) {
    on<LoadProviderDocuments>(_onLoadProviderDocuments);
    on<SubmitDocument>(_onSubmitDocument);
    on<UpdateDocumentStatus>(_onUpdateDocumentStatus);
    on<DeleteDocument>(_onDeleteDocument);
    on<UpdateProviderVerificationInfo>(_onUpdateProviderVerificationInfo);
    on<GetProviderVerificationStatus>(_onGetProviderVerificationStatus);
  }

  Future<void> _onLoadProviderDocuments(
    LoadProviderDocuments event,
    Emitter<VerificationState> emit,
  ) async {
    emit(VerificationLoading());
    try {
      final documents = await _verificationRepository.getProviderDocuments(event.providerId);
      emit(DocumentsLoaded(documents));
    } catch (e) {
      emit(VerificationError(e is ApiException ? e.message : e.toString()));
    }
  }

  Future<void> _onSubmitDocument(
    SubmitDocument event,
    Emitter<VerificationState> emit,
  ) async {
    emit(VerificationLoading());
    try {
      final document = await _verificationRepository.submitDocument(
        providerId: event.providerId,
        documentType: event.documentType,
        documentNumber: event.documentNumber,
        documentFile: event.documentFile,
      );
      emit(DocumentSubmitted(document));
    } catch (e) {
      emit(VerificationError(e is ApiException ? e.message : e.toString()));
    }
  }

  Future<void> _onUpdateDocumentStatus(
    UpdateDocumentStatus event,
    Emitter<VerificationState> emit,
  ) async {
    emit(VerificationLoading());
    try {
      final document = await _verificationRepository.updateDocumentStatus(
        documentId: event.documentId,
        status: event.status,
        rejectionReason: event.rejectionReason,
      );
      emit(DocumentStatusUpdated(document));
    } catch (e) {
      emit(VerificationError(e is ApiException ? e.message : e.toString()));
    }
  }

  Future<void> _onDeleteDocument(
    DeleteDocument event,
    Emitter<VerificationState> emit,
  ) async {
    emit(VerificationLoading());
    try {
      final success = await _verificationRepository.deleteDocument(event.documentId);
      if (success) {
        emit(DocumentDeleted(event.documentId));
      } else {
        emit(const VerificationError('Failed to delete document'));
      }
    } catch (e) {
      emit(VerificationError(e is ApiException ? e.message : e.toString()));
    }
  }

  Future<void> _onUpdateProviderVerificationInfo(
    UpdateProviderVerificationInfo event,
    Emitter<VerificationState> emit,
  ) async {
    emit(VerificationLoading());
    try {
      final provider = await _providerRepository.updateProviderVerificationInfo(
        providerId: event.providerId,
        businessName: event.businessName,
        taxId: event.taxId,
        nationalId: event.nationalId,
      );
      emit(ProviderVerificationInfoUpdated(provider));
    } catch (e) {
      emit(VerificationError(e is ApiException ? e.message : e.toString()));
    }
  }

  Future<void> _onGetProviderVerificationStatus(
    GetProviderVerificationStatus event,
    Emitter<VerificationState> emit,
  ) async {
    emit(VerificationLoading());
    try {
      final provider = await _providerRepository.getProviderVerificationStatus(event.providerId);
      emit(ProviderVerificationStatusLoaded(provider));
    } catch (e) {
      emit(VerificationError(e is ApiException ? e.message : e.toString()));
    }
  }
}
