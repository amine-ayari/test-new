import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_activity_app/config/app_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_activity_app/bloc/user/user_bloc.dart';
import 'package:flutter_activity_app/bloc/user/user_event.dart';
import 'package:flutter_activity_app/bloc/user/user_state.dart';
import 'package:flutter_activity_app/di/service_locator.dart';
import 'package:flutter_activity_app/models/user.dart';
import 'package:flutter_activity_app/models/user_profile.dart';

import 'package:flutter_activity_app/widgets/custom_text_field.dart';
import 'package:flutter_activity_app/widgets/loading_indicator.dart';
import 'package:flutter_activity_app/widgets/snackbar_helper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

class EditProfileScreen extends StatefulWidget {
  final User user;

  const EditProfileScreen({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late UserBloc _userBloc;
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _bioController = TextEditingController();
  
  DateTime? _birthDate;
  File? _imageFile;
  String? _currentImagePath;
  bool _isLoading = false;
  bool _hasChanges = false;
  List<String> _selectedInterests = [];
  
  final List<String> _availableInterests = [
    'Sports', 'Hiking', 'Swimming', 'Cycling', 'Yoga', 
    'Dancing', 'Cooking', 'Photography', 'Music', 'Art',
    'Reading', 'Travel', 'Gaming', 'Movies', 'Technology'
  ];
  
  @override
  void initState() {
    super.initState();
    _userBloc = getIt<UserBloc>();
    _userBloc.add(LoadUserProfile(widget.user.id));
    
    // Initialize controllers with user data
    _nameController.text = widget.user.name;
    _emailController.text = widget.user.email;
    _phoneController.text = widget.user.phoneNumber ?? '';
    _addressController.text = widget.user.address ?? '';
    _bioController.text = widget.user.bio ?? '';
    _currentImagePath = widget.user.profileImage;
     _birthDate = widget.user.birthDate; 

    // Initialize interests if available
    if (widget.user.preferences != null && 
        widget.user.preferences!.containsKey('interests') && 
        widget.user.preferences!['interests'] is List) {
      _selectedInterests = List<String>.from(widget.user.preferences!['interests']);
    }
    
    // Add listeners to detect changes
    _nameController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
    _addressController.addListener(_onFieldChanged);
    _bioController.addListener(_onFieldChanged);
  }
  
  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _hasChanges = true;
        });
      }
    } catch (e) {
      showSnackBar(context, 'Error picking image: $e', isError: true);
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select Image Source',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageSourceOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                  color: AppTheme.primaryColor,
                ),
                _buildImageSourceOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                  color: AppTheme.accentColor,
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: Theme.of(context).textTheme.bodyLarge!.color!,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _birthDate) {
      setState(() {
        _birthDate = picked;
        _hasChanges = true;
      });
    }
  }

  void _toggleInterest(String interest) {
    setState(() {
      if (_selectedInterests.contains(interest)) {
        _selectedInterests.remove(interest);
      } else {
        _selectedInterests.add(interest);
      }
      _hasChanges = true;
    });
  }

 Future<void> _saveProfile() async {
  if (!_formKey.currentState!.validate()) {
    return;
  }

  setState(() {
    _isLoading = true;
  });

  try {
    // Create a map for preferences with interests
    Map<String, dynamic> preferences = {}; // Ensure preferences is a Map
    if (_selectedInterests.isNotEmpty) {
      preferences['interests'] = _selectedInterests;
    }

    // Create updated profile
    final updatedProfile = UserProfile(
      id: widget.user.id,
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      profileImage: _currentImagePath,
      phoneNumber: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      bio: _bioController.text.trim(),
      birthDate: _birthDate,
      preferences: [preferences], // Convert Map to List to match parameter type
    );

    // Update profile with image if provided
    _userBloc.add(UpdateUserProfile(updatedProfile, profileImage: _imageFile));

  } catch (e) {
    setState(() {
      _isLoading = false;
    });
    showSnackBar(context, 'Error updating profile: $e', isError: true);
  }
}

  void _showDiscardChangesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning, color: AppTheme.warningColor),
            SizedBox(width: 8),
            Text('Discard Changes?'),
          ],
        ),
        content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warningColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return WillPopScope(
      onWillPop: () async {
        if (_hasChanges) {
          _showDiscardChangesDialog();
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Profile'),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (_hasChanges) {
                _showDiscardChangesDialog();
              } else {
                Navigator.pop(context);
              }
            },
          ),
          actions: [
            if (_hasChanges)
              TextButton.icon(
                onPressed: _isLoading ? null : _saveProfile,
                icon: const Icon(Icons.save),
                label: const Text('Save'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
        body: BlocConsumer<UserBloc, UserState>(
          bloc: _userBloc,
          listener: (context, state) {
            if (state is UserProfileUpdated) {
              setState(() {
                _isLoading = false;
                _hasChanges = false;
              });
              showSnackBar(context, 'Profile updated successfully!');
              Navigator.pop(context);
            } else if (state is ProfileImageUpdated) {
              setState(() {
                _currentImagePath = state.imagePath;
              });
            } else if (state is UserError) {
              setState(() {
                _isLoading = false;
              });
              showSnackBar(context, state.message, isError: true);
            }
          },
          builder: (context, state) {
            if (state is UserLoading && _isLoading) {
              return const Center(child: LoadingIndicator());
            }
            
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileImageSection().animate().fadeIn(duration: 400.ms),
                    const SizedBox(height: 24),
                    _buildPersonalInfoSection(isDarkMode).animate().fadeIn(duration: 400.ms, delay: 100.ms),
                    const SizedBox(height: 24),
                    _buildContactInfoSection(isDarkMode).animate().fadeIn(duration: 400.ms, delay: 200.ms),
                    const SizedBox(height: 24),
                    _buildInterestsSection(isDarkMode).animate().fadeIn(duration: 400.ms, delay: 300.ms),
                    const SizedBox(height: 32),
                    if (_isLoading)
                      const Center(child: LoadingIndicator())
                    else
                      _buildSaveButton().animate().fadeIn(duration: 400.ms, delay: 400.ms),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileImageSection() {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              Hero(
                tag: 'profile-${widget.user.id}-image',
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!) as ImageProvider
                        : _currentImagePath != null
                            ? NetworkImage(_currentImagePath!) as ImageProvider
                            : null,
                    child: _imageFile == null && _currentImagePath == null
                        ? Text(
                            _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : '?',
                            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: InkWell(
                  onTap: _showImageSourceDialog,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Change Profile Picture',
            style: TextStyle(
              color: AppTheme.accentColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Personal Information', Icons.person),
        CustomTextField(
          controller: _nameController,
          label: 'Full Name',
          hint: 'Enter your full name',
          prefixIcon: Icons.person_outline,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _emailController,
          label: 'Email',
          hint: 'Enter your email',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          readOnly: true, // Email cannot be changed
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () => _selectDate(context),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Birth Date',
              prefixIcon: const Icon(Icons.calendar_today_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: Text(
              _birthDate != null
                  ? DateFormat('MMMM dd, yyyy').format(_birthDate!)
                  : 'Select your birth date',
              style: TextStyle(
                color: _birthDate != null
                    ? Theme.of(context).textTheme.bodyLarge!.color
                    : Theme.of(context).hintColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _bioController,
          label: 'Bio',
          hint: 'Tell us about yourself',
          prefixIcon: Icons.info_outline,
          maxLines: 3,
          maxLength: 200,
        ),
      ],
    );
  }

  Widget _buildContactInfoSection(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Contact Information', Icons.contact_phone),
        CustomTextField(
          controller: _phoneController,
          label: 'Phone Number',
          hint: 'Enter your phone number',
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              if (!RegExp(r'^\+?[0-9]{10,15}$').hasMatch(value)) {
                return 'Please enter a valid phone number';
              }
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _addressController,
          label: 'Address',
          hint: 'Enter your address',
          prefixIcon: Icons.location_on_outlined,
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildInterestsSection(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Interests', Icons.favorite),
        const SizedBox(height: 8),
        Text(
          'Select your interests to help us recommend activities for you',
          style: TextStyle(
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableInterests.map((interest) {
            final isSelected = _selectedInterests.contains(interest);
            return InkWell(
              onTap: () => _toggleInterest(interest),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AppTheme.primaryColor 
                      : isDarkMode 
                          ? Colors.grey[800] 
                          : Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected 
                        ? AppTheme.primaryColor 
                        : isDarkMode 
                            ? Colors.grey[700]! 
                            : Colors.grey[300]!,
                  ),
                ),
                child: Text(
                  interest,
                  style: TextStyle(
                    color: isSelected 
                        ? Colors.white 
                        : isDarkMode 
                            ? Colors.white 
                            : Colors.black,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading || !_hasChanges ? null : _saveProfile,
        icon: const Icon(Icons.save),
        label: const Text('Save Changes'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: AppTheme.primaryColor,
          disabledBackgroundColor: AppTheme.primaryColor.withOpacity(0.5),
        ),
      ),
    );
  }
}
