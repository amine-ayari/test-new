// TODO Implement this library.

import 'package:equatable/equatable.dart';
import 'package:flutter_activity_app/models/verification_document.dart';
import 'package:flutter_activity_app/models/user.dart';

abstract class VerificationState extends Equatable {
  const VerificationState();

  @override
  List<Object?> get props => [];
}

class VerificationInitial extends VerificationState {}

class VerificationLoading extends VerificationState {}

class DocumentsLoaded extends VerificationState {
  final List<VerificationDocument> documents;

  const DocumentsLoaded(this.documents);

  @override
  List<Object> get props => [documents];
}

class DocumentSubmitted extends VerificationState {
  final VerificationDocument document;

  const DocumentSubmitted(this.document);

  @override
  List<Object> get props => [document];
}

class DocumentStatusUpdated extends VerificationState {
  final VerificationDocument document;

  const DocumentStatusUpdated(this.document);

  @override
  List<Object> get props => [document];
}

class DocumentDeleted extends VerificationState {
  final String documentId;

  const DocumentDeleted(this.documentId);

  @override
  List<Object> get props => [documentId];
}

class ProviderVerificationInfoUpdated extends VerificationState {
  final User provider;

  const ProviderVerificationInfoUpdated(this.provider);

  @override
  List<Object> get props => [provider];
}

class ProviderVerificationStatusLoaded extends VerificationState {
  final User provider;

  const ProviderVerificationStatusLoaded(this.provider);

  @override
  List<Object> get props => [provider];
}

class VerificationError extends VerificationState {
  final String message;

  const VerificationError(this.message);

  @override
  List<Object> get props => [message];
}
