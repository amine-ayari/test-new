// TODO Implement this library.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_activity_app/bloc/verification/verification_bloc.dart';
import 'package:flutter_activity_app/bloc/verification/verification_event.dart';
import 'package:flutter_activity_app/bloc/verification/verification_state.dart';
import 'package:flutter_activity_app/di/service_locator.dart';
import 'package:flutter_activity_app/models/user.dart';
import 'package:flutter_activity_app/models/verification_document.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class ProviderVerificationScreen extends StatefulWidget {
  final User user;

  const ProviderVerificationScreen({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  State<ProviderVerificationScreen> createState() => _ProviderVerificationScreenState();
}

class _ProviderVerificationScreenState extends State<ProviderVerificationScreen> {
  late VerificationBloc _verificationBloc;
  
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _nationalIdController = TextEditingController();
  
  final _documentTypeController = TextEditingController();
  final _documentNumberController = TextEditingController();
  
  File? _selectedDocumentFile;
  final ImagePicker _picker = ImagePicker();
  
  @override
  void initState() {
    super.initState();
    _verificationBloc = getIt<VerificationBloc>();
    
    // Initialize controllers with existing data if available
    _businessNameController.text = widget.user.businessName ?? '';
    _taxIdController.text = widget.user.taxId ?? '';
    _nationalIdController.text = widget.user.nationalId ?? '';
    
    // Load provider documents
    _verificationBloc.add(LoadProviderDocuments(widget.user.id));
  }
  
  @override
  void dispose() {
    _businessNameController.dispose();
    _taxIdController.dispose();
    _nationalIdController.dispose();
    _documentTypeController.dispose();
    _documentNumberController.dispose();
    super.dispose();
  }
  
  Future<void> _pickDocument() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (pickedFile != null) {
        setState(() {
          _selectedDocumentFile = File(pickedFile.path);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document selected successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting document: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _submitVerificationInfo() {
    if (_formKey.currentState!.validate()) {
      _verificationBloc.add(
        UpdateProviderVerificationInfo(
          providerId: widget.user.id,
          businessName: _businessNameController.text,
          taxId: _taxIdController.text,
          nationalId: _nationalIdController.text,
        ),
      );
    }
  }
  
  void _submitDocument() {
    if (_formKey.currentState!.validate() && _selectedDocumentFile != null) {
      _verificationBloc.add(
        SubmitDocument(
          providerId: widget.user.id,
          documentType: _documentTypeController.text,
          documentNumber: _documentNumberController.text,
          documentFile: _selectedDocumentFile!,
        ),
      );
      
      // Clear form after submission
      _documentTypeController.clear();
      _documentNumberController.clear();
      setState(() {
        _selectedDocumentFile = null;
      });
    } else if (_selectedDocumentFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a document file'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  String _getStatusText(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.pending:
        return 'Pending Review';
      case VerificationStatus.approved:
        return 'Approved';
      case VerificationStatus.rejected:
        return 'Rejected';
      default:
        return 'Unknown';
    }
  }
  
  Color _getStatusColor(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.pending:
        return Colors.orange;
      case VerificationStatus.approved:
        return Colors.green;
      case VerificationStatus.rejected:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _verificationBloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Provider Verification'),
          elevation: 0,
        ),
        body: BlocConsumer<VerificationBloc, VerificationState>(
          listener: (context, state) {
            if (state is VerificationError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state is ProviderVerificationInfoUpdated) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Verification information updated successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (state is DocumentSubmitted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Document submitted successfully'),
                  backgroundColor: Colors.green,
                ),
              );
              
              // Reload documents after submission
              _verificationBloc.add(LoadProviderDocuments(widget.user.id));
            }
          },
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildVerificationStatusCard(),
                    const SizedBox(height: 24),
                    _buildBusinessInfoSection(),
                    const SizedBox(height: 24),
                    _buildDocumentUploadSection(),
                    const SizedBox(height: 24),
                    _buildDocumentsList(state),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildVerificationStatusCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  widget.user.verificationStatus == VerificationStatus.approved
                      ? Icons.verified
                      : Icons.pending,
                  color: _getStatusColor(widget.user.verificationStatus),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Verification Status',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(widget.user.verificationStatus).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _getStatusColor(widget.user.verificationStatus),
                ),
              ),
              child: Text(
                _getStatusText(widget.user.verificationStatus),
                style: TextStyle(
                  color: _getStatusColor(widget.user.verificationStatus),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.user.verificationStatus == VerificationStatus.approved
                  ? 'Your account is verified. You can now create and manage activities.'
                  : widget.user.verificationStatus == VerificationStatus.pending
                      ? 'Your verification is pending review. This usually takes 1-2 business days.'
                      : widget.user.verificationStatus == VerificationStatus.rejected
                          ? 'Your verification was rejected. Please update your information and try again.'
                          : 'Please complete the verification process to create activities.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBusinessInfoSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Business Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _businessNameController,
              decoration: const InputDecoration(
                labelText: 'Business Name *',
                hintText: 'Enter your business name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your business name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _taxIdController,
              decoration: const InputDecoration(
                labelText: 'Tax ID (Matricule Fiscal) *',
                hintText: 'Enter your tax registration number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.receipt_long),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your tax ID';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nationalIdController,
              decoration: const InputDecoration(
                labelText: 'National ID (CIN) *',
                hintText: 'Enter your national ID number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.badge),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your national ID';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitVerificationInfo,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Save Business Information'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDocumentUploadSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload Verification Documents',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _documentTypeController,
              decoration: const InputDecoration(
                labelText: 'Document Type *',
                hintText: 'E.g., National ID, Tax Certificate, Business License',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the document type';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _documentNumberController,
              decoration: const InputDecoration(
                labelText: 'Document Number *',
                hintText: 'Enter the document reference number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the document number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickDocument,
              child: Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _selectedDocumentFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _selectedDocumentFile!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.upload_file, size: 40, color: Colors.grey),
                          SizedBox(height: 8),
                          Text(
                            'Tap to select a document',
                            style: TextStyle(color: Colors.grey),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'JPG, PNG or PDF',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitDocument,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Upload Document'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDocumentsList(VerificationState state) {
    if (state is DocumentsLoaded) {
      if (state.documents.isEmpty) {
        return const Card(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: Text('No documents submitted yet'),
            ),
          ),
        );
      }
      
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Submitted Documents',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.documents.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final document = state.documents[index];
                  return ListTile(
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: document.documentUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                document.documentUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.description, color: Colors.grey);
                                },
                              ),
                            )
                          : const Icon(Icons.description, color: Colors.grey),
                    ),
                    title: Text(document.documentType),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Number: ${document.documentNumber}'),
                        Text(
                          'Submitted: ${DateFormat('MMM d, yyyy').format(document.submittedAt)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(document.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _getStatusColor(document.status),
                        ),
                      ),
                      child: Text(
                        _getStatusText(document.status),
                        style: TextStyle(
                          color: _getStatusColor(document.status),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    onTap: () {
                      if (document.documentUrl != null) {
                        // Open document viewer
                      }
                    },
                  );
                },
              ),
            ],
          ),
        ),
      );
    } else if (state is VerificationLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}
