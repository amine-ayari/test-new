import 'dart:collection';
import 'dart:typed_data';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_activity_app/bloc/provider/provider_bloc.dart';
import 'package:flutter_activity_app/bloc/provider/provider_event.dart';
import 'package:flutter_activity_app/bloc/provider/provider_state.dart';
import 'package:flutter_activity_app/config/app_theme.dart';
import 'package:flutter_activity_app/di/service_locator.dart';
import 'package:flutter_activity_app/models/activity.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ActivityFormScreen extends StatefulWidget {
  final String providerId;
  final Activity? activity; // Si editing une activité existante

  const ActivityFormScreen({
    Key? key,
    required this.providerId,
    this.activity,
  }) : super(key: key);

  @override
  State<ActivityFormScreen> createState() => _ActivityFormScreenState();
}

class _ActivityFormScreenState extends State<ActivityFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late ProviderBloc _providerBloc;
  late TabController _tabController;

  // Contrôleurs pour les champs de formulaire
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  final _capacityController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  // Données du formulaire
  String _selectedCategory = 'Adventure';
  List<String> _selectedTags = [];
  List<String> _includes = [];
  List<String> _excludes = [];
  List<File> _imageFiles = [];
  List<String> _additionalImages = [];
  List<AvailableDate> _availableDates = [];
  List<AvailableTime> _availableTimes = [];

  // Pour la carte
  final MapController _mapController = MapController();
  LatLng _selectedLocation = const LatLng(48.8566, 2.3522); // Paris par défaut
  bool _isMapFullScreen = false;
  bool _isLocationLoading = false;

  // Pour le calendrier
  DateTime _selectedDate = DateTime.now();

  // Optimisations de performance
  bool _isLowPowerDevice = false;
  bool _lowPowerModeEnabled = false;
  int _maxZoom = 18;
  int _minZoom = 4;
  bool _isDarkMapFailed = false;
  bool _isDarkMapLoading = false;

  // États de l'interface
  bool _isEditing = false;
  bool _isLoading = false;
  bool _isDarkMode = false;
  bool _isSubmitting = false;
  double _uploadProgress = 0.0;
  String _uploadStatus = '';

  // Contrôleurs pour les champs dynamiques
  final TextEditingController _includeController = TextEditingController();
  final TextEditingController _excludeController = TextEditingController();
  final TextEditingController _additionalImageController =
      TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  // Pour le stepper
  int _currentStep = 0;
  final List<String> _stepTitles = [
    'Informations de base',
    'Détails',
    'Localisation',
    'Inclus & Exclus',
    'Images',
    'Disponibilité',
    'Tags'
  ];

  // Listes de données
  final List<String> _categories = [
    'Adventure',
    'Cultural',
    'Educational',
    'Entertainment',
    'Food & Drink',
    'Nature',
    'Sports',
    'Wellness',
    'Other',
  ];

  final List<String> _availableTags = [
    'Family-friendly',
    'Outdoor',
    'Indoor',
    'Group',
    'Individual',
    'Beginner',
    'Advanced',
    'Seasonal',
    'All-year',
    'Weekend',
    'Weekday',
    'Morning',
    'Afternoon',
    'Evening',
    'Kid-friendly',
    'Pet-friendly',
    'Accessible',
  ];

  // Validation state
  final Map<int, bool> _stepValidationState = {};
  bool _formSubmitted = false;

  @override
  void initState() {
    super.initState();
    _providerBloc = getIt<ProviderBloc>();
    _tabController = TabController(length: _stepTitles.length, vsync: this);
    _tabController.addListener(_handleTabChange);

    // Vérifier si c'est le soir pour activer automatiquement le mode nuit
    final hour = DateTime.now().hour;
    if (hour >= 19 || hour <= 6) {
      _isDarkMode = true;
    }

    // Détecter les appareils moins puissants
    _detectLowPowerDevice();

    // Tester le chargement de la carte en mode nuit
    if (_isDarkMode) {
      _testDarkMapLoading();
    }

    // Si editing une activité existante, remplir le formulaire
    if (widget.activity != null) {
      _isEditing = true;
      _nameController.text = widget.activity!.name;
      _descriptionController.text = widget.activity!.description;
      _locationController.text = widget.activity!.location;
      _priceController.text = widget.activity!.price.toString();
      _durationController.text = widget.activity!.duration;
      if (widget.activity!.capacity != null) {
        _capacityController.text = widget.activity!.capacity.toString();
      }
      _latitudeController.text = widget.activity!.latitude.toString();
      _longitudeController.text = widget.activity!.longitude.toString();
      _selectedLocation =
          LatLng(widget.activity!.latitude, widget.activity!.longitude);
      _selectedCategory = widget.activity!.category;
      _selectedTags = List<String>.from(widget.activity!.tags);
      _includes = List<String>.from(widget.activity!.includes);
      _excludes = List<String>.from(widget.activity!.excludes);
      _additionalImages = List<String>.from(widget.activity!.images);
      _availableDates =
          List<AvailableDate>.from(widget.activity!.availableDates);
      _availableTimes =
          List<AvailableTime>.from(widget.activity!.availableTimes);
    } else {
      // Obtenir la position actuelle pour une nouvelle activité
      /*  _getCurrentLocation(); */

      // Initialiser les dates et heures disponibles par défaut
      _initializeDefaultAvailability();
    }

    // Écouter les changements de coordonnées
    _latitudeController.addListener(_updateMapFromCoordinates);
    _longitudeController.addListener(_updateMapFromCoordinates);

    // Configurer la gestion de la mémoire
    _setupMemoryManagement();

    // Initialize validation state
    for (int i = 0; i < _stepTitles.length; i++) {
      _stepValidationState[i] = false;
    }
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _currentStep = _tabController.index;
      });
    }
  }

  Future<void> _detectLowPowerDevice() async {
    try {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      // Logique de détection simplifiée - à adapter selon vos besoins
      // Vérifier la RAM disponible ou d'autres métriques
      final sdkInt = deviceInfo.version.sdkInt;
      final manufacturer = deviceInfo.manufacturer;

      // Considérer comme appareil à faible puissance si Android < 8 ou certains fabricants connus
      if (sdkInt < 26 ||
          manufacturer.toLowerCase().contains('mediatek') ||
          manufacturer.toLowerCase().contains('spreadtrum')) {
        setState(() {
          _isLowPowerDevice = true;
          _maxZoom = 16;
        });
      }
    } catch (e) {
      print('Impossible de détecter les capacités de l\'appareil: $e');
    }
  }

  Future<void> _testDarkMapLoading() async {
    setState(() {
      _isDarkMapLoading = true;
      _isDarkMapFailed = false;
    });

    try {
      final response = await http.get(Uri.parse(
          'https://cartodb-basemaps-a.global.ssl.fastly.net/dark_all/1/1/1.png'));

      if (response.statusCode != 200) {
        setState(() {
          _isDarkMapFailed = true;
        });
      }
    } catch (e) {
      setState(() {
        _isDarkMapFailed = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isDarkMapLoading = false;
        });
      }
    }
  }

  void _setupMemoryManagement() {
    // Configurer la gestion du cycle de vie
    SystemChannels.lifecycle.setMessageHandler((msg) async {
      if (msg == AppLifecycleState.paused.toString()) {
        _releaseResourcesInBackground();
      } else if (msg == AppLifecycleState.resumed.toString()) {
        _restoreResourcesInForeground();
      }
      return null;
    });
  }

  void _releaseResourcesInBackground() {
    // Réduire le zoom pour libérer les tuiles à haute résolution
    if (_mapController.zoom > 10) {
      _mapController.move(_selectedLocation, 10);
    }

    // Vider le cache des images non essentielles
    imageCache.clear();
    imageCache.clearLiveImages();
  }

  void _restoreResourcesInForeground() {
    // Restaurer les ressources si nécessaire
    if (mounted) {
      setState(() {});
    }
  }

  void _initializeDefaultAvailability() {
    // Ajouter les 14 prochains jours comme disponibles par défaut
    final now = DateTime.now();
    for (int i = 1; i <= 14; i++) {
      final date = DateTime(now.year, now.month, now.day + i);
      _availableDates.add(AvailableDate(date: date, available: true));
    }

    // Ajouter quelques heures par défaut
    _availableTimes.addAll([
      AvailableTime(time: '09:00', available: true),
      AvailableTime(time: '11:00', available: true),
      AvailableTime(time: '14:00', available: true),
      AvailableTime(time: '16:00', available: true),
    ]);
  }

  void _updateMapFromCoordinates() {
    if (_latitudeController.text.isNotEmpty &&
        _longitudeController.text.isNotEmpty) {
      try {
        final lat = double.parse(_latitudeController.text);
        final lng = double.parse(_longitudeController.text);
        setState(() {
          _selectedLocation = LatLng(lat, lng);
        });
        _mapController.move(_selectedLocation, _mapController.zoom);
      } catch (e) {
        // Ignorer les erreurs de parsing
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLocationLoading = true;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          setState(() => _isLocationLoading = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() => _isLocationLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Veuillez autoriser l\'accès à la localisation dans les paramètres'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Paramètres',
              onPressed: () => Geolocator.openAppSettings(),
            ),
          ),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      if (!mounted) return;
      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _latitudeController.text = position.latitude.toString();
        _longitudeController.text = position.longitude.toString();
        _isLocationLoading = false;
      });

      _mapController.move(_selectedLocation, _isLowPowerDevice ? 12.0 : 15.0);
      _getAddressFromCoordinates();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLocationLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de localisation: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Simuler l'obtention d'une adresse à partir des coordonnées
  void _getAddressFromCoordinates() {
    // Dans une application réelle, vous utiliseriez un service de géocodage
    // comme Google Maps Geocoding API ou Nominatim

    // Simuler un délai de chargement
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;

      setState(() {
        _locationController.text =
            'Adresse proche de (${_selectedLocation.latitude.toStringAsFixed(4)}, ${_selectedLocation.longitude.toStringAsFixed(4)})';
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _capacityController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _includeController.dispose();
    _excludeController.dispose();
    _additionalImageController.dispose();
    _timeController.dispose();
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _mapController.dispose();

    // Libérer les ressources
    imageCache.clear();
    imageCache.clearLiveImages();

    super.dispose();
  }

  // Nouvelle méthode pour compresser les images avant l'envoi
  Future<File> _compressImage(File file) async {
    try {
      // Lire l'image
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(Uint8List.fromList(bytes));

      if (image == null) return file;

      // Calculer les nouvelles dimensions (max 1200px)
      final maxDimension = 1200;
      int width = image.width;
      int height = image.height;

      if (width > height && width > maxDimension) {
        height = (height * (maxDimension / width)).round();
        width = maxDimension;
      } else if (height > width && height > maxDimension) {
        width = (width * (maxDimension / height)).round();
        height = maxDimension;
      }

      // Redimensionner l'image
      final resized = img.copyResize(image,
          width: width,
          height: height,
          interpolation: img.Interpolation.average);

      // Compresser l'image
      final compressedImage = img.encodeJpg(resized, quality: 80);

      // Sauvegarder l'image compressée
      final tempDir = await getTemporaryDirectory();
      final tempPath =
          path.join(tempDir.path, 'compressed_${path.basename(file.path)}');
      final compressedFile = File(tempPath);
      await compressedFile.writeAsBytes(compressedImage);

      // Vérifier si la compression a réduit la taille
      final originalSize = await file.length();
      final compressedSize = await compressedFile.length();

      print('Image compressée: ${file.path}');
      print('Taille originale: ${(originalSize / 1024).toStringAsFixed(2)} KB');
      print(
          'Taille compressée: ${(compressedSize / 1024).toStringAsFixed(2)} KB');

      // Retourner l'image compressée si elle est plus petite, sinon l'originale
      if (compressedSize < originalSize) {
        return compressedFile;
      } else {
        return file;
      }
    } catch (e) {
      print('Erreur lors de la compression de l\'image: $e');
      return file; // En cas d'erreur, retourner l'image originale
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: _isLowPowerDevice ? 60 : 80,
      );

      if (image != null) {
        setState(() {
          _imageFiles.add(File(image.path));
        });

        // Afficher un message de succès
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Image ajoutée avec succès'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sélection de l\'image: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: _isLowPowerDevice ? 60 : 80,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (image != null) {
        setState(() {
          _imageFiles.add(File(image.path));
        });

        // Afficher un message de succès
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Photo prise avec succès'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la prise de photo: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imageFiles.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Image supprimée'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  void _addInclude() {
    if (_includeController.text.isNotEmpty) {
      setState(() {
        _includes.add(_includeController.text);
        _includeController.clear();
      });

      // Donner un feedback à l'utilisateur
      FocusScope.of(context).unfocus(); // Masquer le clavier
    }
  }

  void _removeInclude(int index) {
    setState(() {
      _includes.removeAt(index);
    });
  }

  void _addExclude() {
    if (_excludeController.text.isNotEmpty) {
      setState(() {
        _excludes.add(_excludeController.text);
        _excludeController.clear();
      });

      // Donner un feedback à l'utilisateur
      FocusScope.of(context).unfocus(); // Masquer le clavier
    }
  }

  void _removeExclude(int index) {
    setState(() {
      _excludes.removeAt(index);
    });
  }

  void _addAdditionalImage() {
    if (_additionalImageController.text.isNotEmpty) {
      setState(() {
        _additionalImages.add(_additionalImageController.text);
        _additionalImageController.clear();
      });
    }
  }

  void _removeAdditionalImage(int index) {
    setState(() {
      _additionalImages.removeAt(index);
    });
  }

  void _toggleDarkMode() {
    setState(() {
      _isDarkMode = !_isDarkMode;

      // Tester le chargement de la carte en mode nuit si on active le mode nuit
      if (_isDarkMode) {
        _testDarkMapLoading();
      }
    });

    // Feedback tactile
    HapticFeedback.lightImpact();
  }

  void _toggleLowPowerMode() {
    setState(() {
      _lowPowerModeEnabled = !_lowPowerModeEnabled;

      if (_lowPowerModeEnabled) {
        // Réduire la qualité et les performances en mode basse consommation
        _maxZoom = 15;
      } else {
        // Restaurer les paramètres normaux
        _maxZoom = _isLowPowerDevice ? 16 : 18;
      }
    });

    // Recharger la carte avec les nouveaux paramètres
    _mapController.move(_selectedLocation, _mapController.zoom);

    // Feedback tactile
    HapticFeedback.mediumImpact();
  }

  void _nextStep() {
    if (_currentStep < _stepTitles.length - 1) {
      // Valider l'étape actuelle avant de passer à la suivante
      if (_validateCurrentStep()) {
        setState(() {
          _currentStep++;
          _tabController.animateTo(_currentStep);
        });
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _tabController.animateTo(_currentStep);
      });
    }
  }

  bool _validateCurrentStep() {
    _formSubmitted = true;

    // Validation spécifique à chaque étape
    switch (_currentStep) {
      case 0: // Informations de base
        return _validateBasicInfo();
      case 1: // Détails
        return _validateDetails();
      case 2: // Localisation
        return _validateLocation();
      case 3: // Inclus & Exclus
        return true; // Optionnel
      case 4: // Images
        return _validateImages();
      case 5: // Disponibilité
        return true; // Optionnel
      case 6: // Tags
        return true; // Optionnel
      default:
        return true;
    }
  }

  bool _validateBasicInfo() {
    return _nameController.text.isNotEmpty &&
        _selectedCategory.isNotEmpty &&
        _locationController.text.isNotEmpty;
  }

  bool _validateDetails() {
    return _descriptionController.text.isNotEmpty &&
        _priceController.text.isNotEmpty &&
        _durationController.text.isNotEmpty;
  }

  bool _validateLocation() {
    return _latitudeController.text.isNotEmpty &&
        _longitudeController.text.isNotEmpty;
  }

  bool _validateImages() {
    // Les images sont optionnelles, mais si l'utilisateur en a ajouté,
    // on vérifie qu'elles sont valides
    return true;
  }

  void _toggleMapFullScreen() {
    setState(() {
      _isMapFullScreen = !_isMapFullScreen;
    });

    // Feedback tactile
    HapticFeedback.mediumImpact();
  }

  void _toggleDateAvailability(DateTime date) {
    final formattedDate = DateTime(date.year, date.month, date.day);

    // Vérifier si la date existe déjà
    final existingIndex = _availableDates.indexWhere((d) =>
        d.date.year == formattedDate.year &&
        d.date.month == formattedDate.month &&
        d.date.day == formattedDate.day);

    if (existingIndex >= 0) {
      // Inverser la disponibilité
      setState(() {
        final currentAvailability = _availableDates[existingIndex].available;
        _availableDates[existingIndex] = AvailableDate(
          date: formattedDate,
          available: !currentAvailability,
        );
      });
    } else {
      // Ajouter une nouvelle date disponible
      setState(() {
        _availableDates.add(AvailableDate(
          date: formattedDate,
          available: true,
        ));
      });
    }
  }

  bool _isDateAvailable(DateTime date) {
    final formattedDate = DateTime(date.year, date.month, date.day);

    final existingDate = _availableDates.firstWhere(
      (d) =>
          d.date.year == formattedDate.year &&
          d.date.month == formattedDate.month &&
          d.date.day == formattedDate.day,
      orElse: () => AvailableDate(date: formattedDate, available: false),
    );

    return existingDate.available;
  }

  void _addTime() {
    if (_timeController.text.isNotEmpty) {
      // Valider le format de l'heure (HH:MM)
      final RegExp timeRegex = RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$');
      if (!timeRegex.hasMatch(_timeController.text)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Format d\'heure invalide. Utilisez HH:MM'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // Vérifier si l'heure existe déjà
      final existingIndex =
          _availableTimes.indexWhere((t) => t.time == _timeController.text);

      if (existingIndex >= 0) {
        // Mettre à jour la disponibilité
        setState(() {
          _availableTimes[existingIndex] = AvailableTime(
            time: _timeController.text,
            available: true,
          );
        });
      } else {
        // Ajouter une nouvelle heure
        setState(() {
          _availableTimes.add(AvailableTime(
            time: _timeController.text,
            available: true,
          ));

          // Trier les heures
          _availableTimes.sort((a, b) => a.time.compareTo(b.time));
        });
      }

      _timeController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  void _toggleTimeAvailability(int index) {
    setState(() {
      final time = _availableTimes[index];
      _availableTimes[index] = AvailableTime(
        time: time.time,
        available: !time.available,
      );
    });
  }

  void _removeTime(int index) {
    setState(() {
      _availableTimes.removeAt(index);
    });
  }

  // Méthode pour obtenir l'URL du template selon le mode
  String _getTileUrlTemplate() {
    if (_isDarkMode) {
      if (_isDarkMapFailed) {
        // Fallback en cas d'échec du chargement des tuiles sombres
        return 'https://stamen-tiles.a.ssl.fastly.net/toner/{z}/{x}/{y}.png';
      }
      // Mode nuit: CartoDB Dark
      return 'https://cartodb-basemaps-{s}.global.ssl.fastly.net/dark_all/{z}/{x}/{y}.png';
    } else {
      // Mode jour: OpenStreetMap standard
      return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }

  // Ajouter cette méthode à la classe _ActivityFormScreenState
  void _debugPrintFormData() {
    print('=== DONNÉES DU FORMULAIRE ===');
    print('Nom: ${_nameController.text}');
    print('Description: ${_descriptionController.text}');
    print('Catégorie: $_selectedCategory');
    print('Localisation: ${_locationController.text}');
    print('Prix: ${_priceController.text}');
    print('Durée: ${_durationController.text}');
    print('Capacité: ${_capacityController.text}');
    print('Latitude: ${_latitudeController.text}');
    print('Longitude: ${_longitudeController.text}');
    print('Tags: $_selectedTags');
    print('Inclus: $_includes');
    print('Exclus: $_excludes');
    print('Images: ${_imageFiles.length} fichiers');
    print('Dates disponibles: ${_availableDates.length} dates');
    print('Heures disponibles: ${_availableTimes.length} heures');
    print('=== FIN DES DONNÉES ===');
  }

  Future<void> _submitForm() async {
    print('Tentative d\'envoi du formulaire');
    _debugPrintFormData();

    // Valider tous les champs obligatoires
    bool isValid = _validateAllFields();

    if (isValid) {
      setState(() {
        _isLoading = true;
        _isSubmitting = true;
        _uploadProgress = 0.0;
        _uploadStatus = 'Préparation des données...';
      });

      try {
        // Compresser les images avant l'envoi
        setState(() {
          _uploadStatus = 'Compression des images...';
        });

        List<File> compressedImages = [];
        if (_imageFiles.isNotEmpty) {
          for (int i = 0; i < _imageFiles.length; i++) {
            setState(() {
              _uploadProgress =
                  (i / _imageFiles.length) * 0.5; // 50% pour la compression
              _uploadStatus =
                  'Compression de l\'image ${i + 1}/${_imageFiles.length}...';
            });

            final compressedImage = await _compressImage(_imageFiles[i]);
            compressedImages.add(compressedImage);
          }
        }

        // Créer un objet Provider (simplifié pour l'exemple)
        final provider = Provider(
          id: widget.providerId,
          name: "Provider Name",
          rating: _isEditing ? widget.activity!.provider.rating : 0.0,
          verified: true,
          image: "assets/images/provider_placeholder.jpg",
          phone: "+1234567890",
          email: "provider@example.com",
        );

        // Get image paths from the compressed files
        List<String> imagePaths = [];
        if (compressedImages.isNotEmpty) {
          imagePaths = compressedImages.map((file) => file.path).toList();
        }

        setState(() {
          _uploadStatus = 'Création de l\'activité...';
          _uploadProgress = 0.5; // 50% pour l'envoi
        });

        // Vérifier que les valeurs numériques sont correctement formatées
        double price = 0.0;
        try {
          price = double.parse(_priceController.text);
        } catch (e) {
          throw Exception('Le prix doit être un nombre valide');
        }

        int? capacity;
        if (_capacityController.text.isNotEmpty) {
          try {
            capacity = int.parse(_capacityController.text);
          } catch (e) {
            throw Exception('La capacité doit être un nombre entier valide');
          }
        }

        // Créer ou mettre à jour l'activité
        final activity = Activity(
          id: _isEditing ? widget.activity!.id : '',
          name: _nameController.text,
          description: _descriptionController.text,
          category: _selectedCategory,
          location: _locationController.text,
          price: price,
          duration: _durationController.text,
          capacity: capacity,
          image: compressedImages.isNotEmpty
              ? compressedImages.first.path
              : (_isEditing
                  ? widget.activity!.image
                  : 'https://res.cloudinary.com/dpl8pr4y7/image/upload/v1745336268/ufab63vrlt62wskfy8km.jpg'),
          rating: _isEditing ? widget.activity!.rating : 0.0,
          reviews: _isEditing ? widget.activity!.reviews : [],
          tags: _selectedTags,
          provider: provider,
          includes: _includes,
          excludes: _excludes,
          images: imagePaths, // Use the compressed image paths
          latitude: _selectedLocation.latitude,
          longitude: _selectedLocation.longitude,
          isFavorite: _isEditing ? widget.activity!.isFavorite : false,
          availableDates: _availableDates,
          availableTimes: _availableTimes,
          requiresApproval: false, // Add this line
        );

        // Vérifier que toutes les données requises sont présentes
        _validateActivityData(activity);

        setState(() {
          _uploadStatus = _isEditing
              ? 'Mise à jour de l\'activité...'
              : 'Création de l\'activité...';
          _uploadProgress = 0.7; // 70%
        });

        if (_isEditing) {
          _providerBloc.add(UpdateActivity(activity));
        } else {
          _providerBloc.add(CreateActivity(activity));
        }

        // Simuler la progression de l'envoi
        for (double i = 0.7; i < 0.95; i += 0.05) {
          await Future.delayed(Duration(milliseconds: 200));
          if (!mounted) return;
          setState(() {
            _uploadProgress = i;
          });
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          _isSubmitting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'envoi du formulaire: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
              textColor: Colors.white,
            ),
          ),
        );
      }
    } else {
      // Afficher un message d'erreur global
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez remplir tous les champs obligatoires'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );

      // Trouver l'onglet avec l'erreur
      for (int i = 0; i < _stepTitles.length; i++) {
        if (!_validateStep(i)) {
          setState(() {
            _currentStep = i;
            _tabController.animateTo(i);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Veuillez corriger les erreurs dans l\'onglet ${_stepTitles[i]}'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
          break;
        }
      }
    }
  }

  // Nouvelle méthode pour valider tous les champs
  bool _validateAllFields() {
    _formSubmitted = true;

    // Valider chaque étape
    bool isValid = true;
    for (int i = 0; i < _stepTitles.length; i++) {
      if (!_validateStep(i)) {
        isValid = false;
      }
    }

    return isValid;
  }

  // Nouvelle méthode pour valider une étape spécifique
  bool _validateStep(int step) {
    switch (step) {
      case 0: // Informations de base
        return _nameController.text.isNotEmpty &&
            _selectedCategory.isNotEmpty &&
            _locationController.text.isNotEmpty;
      case 1: // Détails
        return _descriptionController.text.isNotEmpty &&
            _priceController.text.isNotEmpty &&
            _durationController.text.isNotEmpty;
      case 2: // Localisation
        return _latitudeController.text.isNotEmpty &&
            _longitudeController.text.isNotEmpty;
      case 3: // Inclus & Exclus
        return true; // Optionnel
      case 4: // Images
        return true; // Optionnel
      case 5: // Disponibilité
        return true; // Optionnel
      case 6: // Tags
        return true; // Optionnel
      default:
        return true;
    }
  }

  // Nouvelle méthode pour valider les données de l'activité
  void _validateActivityData(Activity activity) {
    List<String> errors = [];

    if (activity.name.isEmpty) {
      errors.add('Le nom est requis');
    }

    if (activity.description.isEmpty) {
      errors.add('La description est requise');
    }

    if (activity.category.isEmpty) {
      errors.add('La catégorie est requise');
    }

    if (activity.location.isEmpty) {
      errors.add('La localisation est requise');
    }

    if (activity.duration.isEmpty) {
      errors.add('La durée est requise');
    }

    if (errors.isNotEmpty) {
      throw Exception('Validation échouée: ${errors.join(', ')}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = _isDarkMode
        ? ThemeData.dark().copyWith(
            primaryColor: AppTheme.primaryColor,
            scaffoldBackgroundColor: const Color(0xFF121212),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E1E1E),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          )
        : ThemeData.light().copyWith(
            primaryColor: AppTheme.primaryColor,
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.textPrimaryColor,
              elevation: 0,
            ),
          );

    return BlocProvider.value(
      value: _providerBloc,
      child: Theme(
        data: theme,
        child: BlocListener<ProviderBloc, ProviderState>(
          listener: (context, state) {
            if (state is ActivityCreated || state is ActivityUpdated) {
              setState(() {
                _isLoading = false;
                _isSubmitting = false;
                _uploadProgress = 1.0;
                _uploadStatus = 'Terminé!';
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isEditing
                      ? 'Activité mise à jour avec succès'
                      : 'Activité créée avec succès'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              );

              // Attendre un peu pour montrer le succès avant de fermer
              Future.delayed(Duration(seconds: 1), () {
                if (mounted) {
                  Navigator.pop(context);
                }
              });
            } else if (state is ProviderError) {
              setState(() {
                _isLoading = false;
                _isSubmitting = false;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erreur: ${state.message}'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  action: SnackBarAction(
                    label: 'Réessayer',
                    onPressed: _submitForm,
                    textColor: Colors.white,
                  ),
                ),
              );
            }
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                  _isEditing ? 'Modifier l\'activité' : 'Créer une activité'),
              elevation: 0,
              actions: [
                IconButton(
                  icon: Icon(_isDarkMode
                      ? Icons.wb_sunny_outlined
                      : Icons.dark_mode_outlined),
                  onPressed: _toggleDarkMode,
                  tooltip: _isDarkMode ? 'Mode jour' : 'Mode nuit',
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: _stepTitles.asMap().entries.map((entry) {
                  final index = entry.key;
                  final title = entry.value;

                  return Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(title),
                        if (_formSubmitted && !_validateStep(index))
                          Icon(Icons.error_outline,
                              color: Colors.red, size: 16),
                      ],
                    ),
                  );
                }).toList(),
                onTap: (index) {
                  setState(() {
                    _currentStep = index;
                  });
                },
                indicatorColor: AppTheme.primaryColor,
                labelColor: _isDarkMode ? Colors.white : AppTheme.primaryColor,
                unselectedLabelColor:
                    _isDarkMode ? Colors.white60 : Colors.grey,
              ),
            ),
            body: _isLoading
                ? _buildLoadingIndicator()
                : Form(
                    key: _formKey,
                    child: TabBarView(
                      controller: _tabController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildBasicInfoTab(),
                        _buildDetailsTab(),
                        _buildLocationTab(),
                        _buildIncludesExcludesTab(),
                        _buildImagesTab(),
                        _buildAvailabilityTab(),
                        _buildTagsTab(),
                      ],
                    ),
                  ),
            bottomNavigationBar: _isMapFullScreen ? null : _buildBottomNavBar(),
            floatingActionButton: _isMapFullScreen
                ? FloatingActionButton(
                    onPressed: _toggleMapFullScreen,
                    child: Icon(Icons.fullscreen_exit),
                    tooltip: 'Quitter le plein écran',
                    backgroundColor: AppTheme.primaryColor,
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isSubmitting) ...[
            // Indicateur de progression avec pourcentage
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: _uploadProgress,
                    color: AppTheme.primaryColor,
                    backgroundColor:
                        _isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    strokeWidth: 8,
                  ),
                ),
                Text(
                  '${(_uploadProgress * 100).toInt()}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color:
                        _isDarkMode ? Colors.white : AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _uploadStatus,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _isDarkMode ? Colors.white : AppTheme.textPrimaryColor,
              ),
            ),
          ] else ...[
            // Indicateur de chargement simple
            CircularProgressIndicator(
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              _isEditing ? 'Chargement de l\'activité...' : 'Initialisation...',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _isDarkMode ? Colors.white : AppTheme.textPrimaryColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            ElevatedButton.icon(
              onPressed: _previousStep,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Précédent'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isDarkMode ? Colors.grey[800] : Colors.grey[200],
                foregroundColor: _isDarkMode ? Colors.white : Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )
          else
            const SizedBox.shrink(),
          if (_currentStep < _stepTitles.length - 1)
            ElevatedButton.icon(
              onPressed: _nextStep,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Suivant'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: _submitForm,
              icon: const Icon(Icons.check),
              label: Text(_isEditing ? 'Mettre à jour' : 'Créer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Informations de base'),
          const SizedBox(height: 16),

          // Nom de l'activité
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Nom de l\'activité *',
              hintText: 'Ex: Randonnée au Mont Blanc',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: Icon(Icons.title),
              filled: true,
              fillColor: _isDarkMode ? Colors.grey[800] : Colors.grey[50],
              errorText: _formSubmitted && _nameController.text.isEmpty
                  ? 'Le nom est requis'
                  : null,
            ),
            style: TextStyle(
              color: _isDarkMode ? Colors.white : Colors.black87,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer un nom d\'activité';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Catégorie
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: InputDecoration(
              labelText: 'Catégorie *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: Icon(Icons.category),
              filled: true,
              fillColor: _isDarkMode ? Colors.grey[800] : Colors.grey[50],
              errorText: _formSubmitted && _selectedCategory.isEmpty
                  ? 'La catégorie est requise'
                  : null,
            ),
            items: _categories.map((category) {
              return DropdownMenuItem<String>(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedCategory = value;
                });
              }
            },
            dropdownColor: _isDarkMode ? Colors.grey[800] : Colors.white,
            style: TextStyle(
              color: _isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // Localisation
          TextFormField(
            controller: _locationController,
            decoration: InputDecoration(
              labelText: 'Adresse / Lieu *',
              hintText: 'Ex: 123 Rue de la Montagne, Chamonix',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: Icon(Icons.location_on),
              filled: true,
              fillColor: _isDarkMode ? Colors.grey[800] : Colors.grey[50],
              errorText: _formSubmitted && _locationController.text.isEmpty
                  ? 'La localisation est requise'
                  : null,
              suffixIcon: IconButton(
                icon: Icon(Icons.my_location),
                onPressed: _getCurrentLocation,
                tooltip: 'Utiliser ma position actuelle',
              ),
            ),
            style: TextStyle(
              color: _isDarkMode ? Colors.white : Colors.black87,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer une adresse';
              }
              return null;
            },
          ),

          const SizedBox(height: 24),

          // Aperçu de l'activité
          Container(
            decoration: BoxDecoration(
              color: _isDarkMode ? Colors.grey[850] : Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.preview,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Aperçu de l\'activité',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

                // Contenu
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Titre et catégorie
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _nameController.text.isEmpty
                                  ? 'Nom de l\'activité'
                                  : _nameController.text,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color:
                                    _isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _selectedCategory,
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Localisation
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color:
                                _isDarkMode ? Colors.white70 : Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _locationController.text.isEmpty
                                  ? 'Adresse / Lieu'
                                  : _locationController.text,
                              style: TextStyle(
                                color: _isDarkMode
                                    ? Colors.white70
                                    : Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Prix et durée
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.euro,
                                  size: 14,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _priceController.text.isEmpty
                                      ? '0.00'
                                      : _priceController.text,
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _durationController.text.isEmpty
                                      ? 'Durée'
                                      : _durationController.text,
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 300.ms, duration: 500.ms),

          const SizedBox(height: 24),

          // Conseils
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isDarkMode
                  ? AppTheme.primaryColor.withOpacity(0.1)
                  : AppTheme.primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Conseil',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isDarkMode
                              ? Colors.white
                              : AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Donnez un nom accrocheur à votre activité et choisissez la catégorie qui correspond le mieux.',
                        style: TextStyle(
                          color:
                              _isDarkMode ? Colors.white70 : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Détails de l\'activité'),
          const SizedBox(height: 16),

          // Description
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'Description *',
              hintText: 'Décrivez votre activité en détail...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: Icon(Icons.description),
              filled: true,
              fillColor: _isDarkMode ? Colors.grey[800] : Colors.grey[50],
              errorText: _formSubmitted && _descriptionController.text.isEmpty
                  ? 'La description est requise'
                  : null,
              alignLabelWithHint: true,
            ),
            style: TextStyle(
              color: _isDarkMode ? Colors.white : Colors.black87,
            ),
            maxLines: 4,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer une description';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Prix et durée
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _priceController,
                  decoration: InputDecoration(
                    labelText: 'Prix (€) *',
                    hintText: 'Ex: 25.50',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(Icons.euro),
                    filled: true,
                    fillColor: _isDarkMode ? Colors.grey[800] : Colors.grey[50],
                    errorText: _formSubmitted && _priceController.text.isEmpty
                        ? 'Le prix est requis'
                        : null,
                  ),
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white : Colors.black87,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Requis';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Prix invalide';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _durationController,
                  decoration: InputDecoration(
                    labelText: 'Durée *',
                    hintText: 'Ex: 2 heures',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(Icons.access_time),
                    filled: true,
                    fillColor: _isDarkMode ? Colors.grey[800] : Colors.grey[50],
                    errorText:
                        _formSubmitted && _durationController.text.isEmpty
                            ? 'La durée est requise'
                            : null,
                  ),
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white : Colors.black87,
                  ),
                  keyboardType: TextInputType.number, // Use numeric keyboard
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Requis';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Capacité
          TextFormField(
            controller: _capacityController,
            decoration: InputDecoration(
              labelText: 'Capacité (personnes, optionnel)',
              hintText: 'Ex: 10',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: Icon(Icons.people),
              filled: true,
              fillColor: _isDarkMode ? Colors.grey[800] : Colors.grey[50],
            ),
            style: TextStyle(
              color: _isDarkMode ? Colors.white : Colors.black87,
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
          ),

          const SizedBox(height: 24),

          // Conseils
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isDarkMode
                  ? AppTheme.primaryColor.withOpacity(0.1)
                  : AppTheme.primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.tips_and_updates,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Astuce',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isDarkMode
                              ? Colors.white
                              : AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Une description détaillée et attrayante augmente les chances que votre activité soit réservée.',
                        style: TextStyle(
                          color:
                              _isDarkMode ? Colors.white70 : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationTab() {
    return Stack(
      children: [
        // Carte en plein écran ou en mode normal
        SizedBox(
          height: _isMapFullScreen
              ? MediaQuery.of(context).size.height
              : MediaQuery.of(context).size.height * 0.5,
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLocation,
              initialZoom:
                  (_isLowPowerDevice || _lowPowerModeEnabled) ? 12.0 : 13.0,
              onTap: (_, point) {
                setState(() {
                  _selectedLocation = point;
                  _latitudeController.text = point.latitude.toString();
                  _longitudeController.text = point.longitude.toString();
                });
                _getAddressFromCoordinates();
              },
              interactionOptions: InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: _getTileUrlTemplate(),
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.flutter_activity_app',
                maxZoom: _maxZoom.toDouble(),
                minZoom: _minZoom.toDouble(),
                tileProvider: NetworkTileProvider(),
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    width: (_isLowPowerDevice || _lowPowerModeEnabled)
                        ? 30.0
                        : 40.0,
                    height: (_isLowPowerDevice || _lowPowerModeEnabled)
                        ? 30.0
                        : 40.0,
                    point: _selectedLocation,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: (_isLowPowerDevice || _lowPowerModeEnabled)
                            ? null
                            : [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: (_isLowPowerDevice || _lowPowerModeEnabled)
                            ? 20
                            : 30,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Boutons de contrôle de la carte
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            children: [
              // Bouton plein écran
              _buildMapControlButton(
                icon:
                    _isMapFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                onPressed: _toggleMapFullScreen,
                tooltip:
                    _isMapFullScreen ? 'Quitter le plein écran' : 'Plein écran',
              ),
              const SizedBox(height: 8),

              // Bouton ma position
              _buildMapControlButton(
                icon: Icons.my_location,
                onPressed: _getCurrentLocation,
                tooltip: 'Ma position',
              ),
              const SizedBox(height: 8),

              // Bouton zoom in
              _buildMapControlButton(
                icon: Icons.add,
                onPressed: () {
                  _mapController.move(
                      _selectedLocation, _mapController.zoom + 1);
                },
                tooltip: 'Zoom avant',
              ),
              const SizedBox(height: 8),

              // Bouton zoom out
              _buildMapControlButton(
                icon: Icons.remove,
                onPressed: () {
                  _mapController.move(
                      _selectedLocation, _mapController.zoom - 1);
                },
                tooltip: 'Zoom arrière',
              ),
              const SizedBox(height: 8),

              // Bouton mode basse consommation
              _buildMapControlButton(
                icon: _lowPowerModeEnabled
                    ? Icons.battery_saver
                    : Icons.battery_full,
                onPressed: _toggleLowPowerMode,
                tooltip: _lowPowerModeEnabled
                    ? 'Désactiver le mode économie d\'énergie'
                    : 'Activer le mode économie d\'énergie',
                color:
                    _lowPowerModeEnabled ? Colors.green : AppTheme.primaryColor,
              ),
            ],
          ),
        ),

        // Formulaire de coordonnées (visible uniquement en mode normal)
        if (!_isMapFullScreen)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSectionTitle('Coordonnées de l\'activité'),
                  const SizedBox(height: 16),

                  // Latitude et longitude
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _latitudeController,
                          decoration: InputDecoration(
                            labelText: 'Latitude *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: Icon(Icons.map),
                            filled: true,
                            fillColor: _isDarkMode
                                ? Colors.grey[800]
                                : Colors.grey[50],
                            errorText: _formSubmitted &&
                                    _latitudeController.text.isEmpty
                                ? 'La latitude est requise'
                                : null,
                          ),
                          style: TextStyle(
                            color: _isDarkMode ? Colors.white : Colors.black87,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Requis';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Invalide';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _longitudeController,
                          decoration: InputDecoration(
                            labelText: 'Longitude *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: Icon(Icons.map),
                            filled: true,
                            fillColor: _isDarkMode
                                ? Colors.grey[800]
                                : Colors.grey[50],
                            errorText: _formSubmitted &&
                                    _longitudeController.text.isEmpty
                                ? 'La longitude est requise'
                                : null,
                          ),
                          style: TextStyle(
                            color: _isDarkMode ? Colors.white : Colors.black87,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Requis';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Invalide';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Conseil
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _isDarkMode
                          ? AppTheme.primaryColor.withOpacity(0.1)
                          : AppTheme.primaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppTheme.primaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Comment utiliser la carte',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _isDarkMode
                                      ? Colors.white
                                      : AppTheme.textPrimaryColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Touchez la carte pour sélectionner l\'emplacement de votre activité. Les coordonnées seront automatiquement mises à jour.',
                                style: TextStyle(
                                  color: _isDarkMode
                                      ? Colors.white70
                                      : Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Indicateur de chargement
        if (_isLocationLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  Widget _buildIncludesExcludesTab() {
    return _optimizedAnimation(
      SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Ce qui est inclus et exclu'),
            const SizedBox(height: 16),

            // Inclus
            _buildSubsectionTitle('Inclus dans l\'activité'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildAnimatedFormField(
                    controller: _includeController,
                    labelText: 'Ajouter un élément inclus',
                    prefixIcon: Icons.check_circle_outline,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addInclude,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_includes.isNotEmpty)
              _buildListItems(
                items: _includes,
                icon: Icons.check_circle,
                iconColor: Colors.green,
                onDelete: _removeInclude,
              ),

            const SizedBox(height: 24),

            // Exclus
            _buildSubsectionTitle('Non inclus dans l\'activité'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildAnimatedFormField(
                    controller: _excludeController,
                    labelText: 'Ajouter un élément exclu',
                    prefixIcon: Icons.not_interested,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addExclude,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_excludes.isNotEmpty)
              _buildListItems(
                items: _excludes,
                icon: Icons.not_interested,
                iconColor: Colors.red,
                onDelete: _removeExclude,
              ),

            const SizedBox(height: 24),

            // Conseil
            _buildTipCard(
              icon: Icons.lightbulb_outline,
              title: 'Conseil',
              content:
                  'Soyez précis sur ce qui est inclus et exclu pour éviter toute confusion avec vos clients.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagesTab() {
    return _optimizedAnimation(
      SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Images de l\'activité'),
            const SizedBox(height: 16),

            // Image principale
            _buildSubsectionTitle('Image principale'),
            const SizedBox(height: 8),
            _buildImagePickerArea(),
            const SizedBox(height: 24),

            // Images supplémentaires
            _buildSubsectionTitle('Images supplémentaires'),
            const SizedBox(height: 8),
            if (_imageFiles.isNotEmpty)
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _imageFiles.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _imageFiles[index],
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                              cacheWidth:
                                  (_isLowPowerDevice || _lowPowerModeEnabled)
                                      ? 240
                                      : 480,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              )
            else
              Center(
                child: Text(
                  'Aucune image supplémentaire',
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white60 : Colors.grey,
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Boutons d'ajout d'images
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Galerie'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _takePhoto,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Appareil photo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    foregroundColor: _isDarkMode ? Colors.white : Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Conseil
            _buildTipCard(
              icon: Icons.photo_camera,
              title: 'Conseil pour les photos',
              content:
                  'Des images de haute qualité et bien éclairées augmentent l\'attractivité de votre activité. Ajoutez plusieurs photos pour montrer différents aspects.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilityTab() {
    return _optimizedAnimation(
      SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Disponibilité'),
            const SizedBox(height: 8),
            Text(
              'Définissez quand votre activité est disponible',
              style: TextStyle(
                color: _isDarkMode ? Colors.white60 : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),

            // Calendrier
            Container(
              decoration: BoxDecoration(
                color: _isDarkMode ? Colors.grey[850] : Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isDarkMode ? Colors.white24 : Colors.grey[300]!,
                ),
              ),
              child: Column(
                children: [
                  // En-tête du calendrier
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Dates disponibles',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Calendrier
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: _buildCalendar(),
                  ),

                  // Légende
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Colors.green,
                              width: 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Disponible',
                          style: TextStyle(
                            color:
                                _isDarkMode ? Colors.white70 : Colors.grey[700],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Colors.red,
                              width: 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Non disponible',
                          style: TextStyle(
                            color:
                                _isDarkMode ? Colors.white70 : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Heures disponibles
            Container(
              decoration: BoxDecoration(
                color: _isDarkMode ? Colors.grey[850] : Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isDarkMode ? Colors.white24 : Colors.grey[300]!,
                ),
              ),
              child: Column(
                children: [
                  // En-tête des heures
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Heures disponibles',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Ajouter une heure
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildAnimatedFormField(
                            controller: _timeController,
                            labelText: 'Ajouter une heure (ex: 14:00)',
                            prefixIcon: Icons.schedule,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _addTime,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ),

                  // Liste des heures
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableTimes.asMap().entries.map((entry) {
                        final index = entry.key;
                        final time = entry.value;
                        return GestureDetector(
                          onTap: () => _toggleTimeAvailability(index),
                          child: Chip(
                            label: Text(time.time),
                            backgroundColor: time.available
                                ? Colors.green.withOpacity(0.2)
                                : Colors.red.withOpacity(0.2),
                            side: BorderSide(
                              color: time.available ? Colors.green : Colors.red,
                              width: 1,
                            ),
                            deleteIcon: const Icon(
                              Icons.close,
                              size: 16,
                            ),
                            onDeleted: () => _removeTime(index),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Conseil
            _buildTipCard(
              icon: Icons.event_available,
              title: 'Conseil pour la disponibilité',
              content:
                  'Définissez précisément quand votre activité est disponible pour éviter les réservations à des moments où vous ne pouvez pas assurer l\'activité.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 2, 0);

    return Column(
      children: [
        // En-tête du mois
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                setState(() {
                  _selectedDate = DateTime(
                    _selectedDate.year,
                    _selectedDate.month - 1,
                    1,
                  );
                });
              },
            ),
            Text(
              DateFormat('MMMM yyyy').format(_selectedDate),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: _isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                setState(() {
                  _selectedDate = DateTime(
                    _selectedDate.year,
                    _selectedDate.month + 1,
                    1,
                  );
                });
              },
            ),
          ],
        ),

        // Jours de la semaine
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Lu', 'Ma', 'Me', 'Je', 'Ve', 'Sa', 'Di'].map((day) {
              return SizedBox(
                width: 30,
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _isDarkMode ? Colors.white70 : Colors.grey[700],
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // Grille du calendrier
        _buildCalendarGrid(),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    final now = DateTime.now();
    final firstDayOfMonth =
        DateTime(_selectedDate.year, _selectedDate.month, 1);

    // Déterminer le premier jour à afficher (lundi précédent le 1er du mois)
    int firstWeekday = firstDayOfMonth.weekday;
    final firstDay = firstDayOfMonth.subtract(Duration(days: firstWeekday - 1));

    // Nombre de jours à afficher (42 = 6 semaines)
    const daysToShow = 42;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
      ),
      itemCount: daysToShow,
      itemBuilder: (context, index) {
        final day = firstDay.add(Duration(days: index));
        final isCurrentMonth = day.month == _selectedDate.month;
        final isPast = day.isBefore(DateTime(now.year, now.month, now.day));
        final isToday = day.year == now.year &&
            day.month == now.month &&
            day.day == now.day;
        final isAvailable = _isDateAvailable(day);

        // Déterminer le style du jour
        final textColor = isCurrentMonth
            ? (_isDarkMode ? Colors.white : Colors.black)
            : (_isDarkMode ? Colors.white38 : Colors.grey[400]);

        final backgroundColor = isAvailable
            ? Colors.green.withOpacity(0.3)
            : (isPast
                ? Colors.grey.withOpacity(0.1)
                : Colors.red.withOpacity(0.3));

        final borderColor = isAvailable
            ? Colors.green
            : (isPast ? Colors.transparent : Colors.red);

        return GestureDetector(
          onTap: isPast ? null : () => _toggleDateAvailability(day),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isToday
                  ? AppTheme.primaryColor.withOpacity(0.3)
                  : backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isToday ? AppTheme.primaryColor : borderColor,
                width: isToday ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(
                day.day.toString(),
                style: TextStyle(
                  color: isToday ? AppTheme.primaryColor : textColor,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTagsTab() {
    return _optimizedAnimation(
      SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Tags et caractéristiques'),
            const SizedBox(height: 8),
            Text(
              'Sélectionnez les tags qui décrivent le mieux votre activité',
              style: TextStyle(
                color: _isDarkMode ? Colors.white60 : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),

            // Tags
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableTags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: isSelected,
                  onSelected: (_) => _toggleTag(tag),
                  backgroundColor:
                      _isDarkMode ? Colors.grey[800] : Colors.grey[200],
                  selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                  checkmarkColor: AppTheme.primaryColor,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : (_isDarkMode ? Colors.white : Colors.black),
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Résumé
            if (_selectedTags.isNotEmpty) ...[
              _buildSubsectionTitle('Tags sélectionnés'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isDarkMode ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isDarkMode ? Colors.white24 : Colors.grey[300]!,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedTags.join(', '),
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Conseil
            _buildTipCard(
              icon: Icons.tag,
              title: 'Pourquoi les tags sont importants',
              content:
                  'Les tags aident les utilisateurs à trouver votre activité lors des recherches. Choisissez ceux qui sont les plus pertinents pour augmenter la visibilité.',
            ),

            const SizedBox(height: 32),

            // Bouton de soumission
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submitForm,
                icon: const Icon(Icons.check),
                label: Text(_isEditing
                    ? 'Mettre à jour l\'activité'
                    : 'Créer l\'activité'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePickerArea() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: _isDarkMode ? Colors.grey[800] : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isDarkMode ? Colors.white24 : Colors.grey[300]!,
          ),
        ),
        child: _imageFiles.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _imageFiles.first,
                  fit: BoxFit.cover,
                  cacheWidth:
                      (_isLowPowerDevice || _lowPowerModeEnabled) ? 640 : 1280,
                ),
              )
            : _isEditing && widget.activity!.image.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.activity!.image,
                      fit: BoxFit.cover,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate,
                        size: 48,
                        color: _isDarkMode ? Colors.white54 : Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ajouter une image principale',
                        style: TextStyle(
                          color:
                              _isDarkMode ? Colors.white70 : Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Touchez pour sélectionner une image',
                        style: TextStyle(
                          color:
                              _isDarkMode ? Colors.white54 : Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildMapControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    Color? color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        tooltip: tooltip,
        color: color ?? AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: _isDarkMode ? Colors.white : AppTheme.textPrimaryColor,
      ),
    );
  }

  Widget _buildSubsectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: _isDarkMode ? Colors.white70 : Colors.grey[800],
      ),
    );
  }

  Widget _buildTipCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isDarkMode
            ? AppTheme.primaryColor.withOpacity(0.1)
            : AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                        _isDarkMode ? Colors.white : AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white70 : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItems({
    required List<String> items,
    required IconData icon,
    required Color iconColor,
    required Function(int) onDelete,
  }) {
    return Card(
      elevation: 0,
      color: _isDarkMode ? Colors.grey[800] : Colors.grey[100],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return ListTile(
              leading: Icon(icon, color: iconColor),
              title: Text(
                item,
                style: TextStyle(
                  color: _isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => onDelete(index),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAnimatedFormField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    String? hintText,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: Icon(prefixIcon),
        filled: true,
        fillColor: _isDarkMode ? Colors.grey[800] : Colors.grey[50],
      ),
      style: TextStyle(
        color: _isDarkMode ? Colors.white : Colors.black87,
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
    );
  }

  Widget _buildAnimatedDropdown({
    required String value,
    required String labelText,
    required IconData prefixIcon,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?)? onChanged,
    required String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: Icon(prefixIcon),
        filled: true,
        fillColor: _isDarkMode ? Colors.grey[800] : Colors.grey[50],
      ),
      items: items,
      onChanged: onChanged,
      validator: validator,
      dropdownColor: _isDarkMode ? Colors.grey[800] : Colors.white,
      style: TextStyle(
        color: _isDarkMode ? Colors.white : Colors.black87,
      ),
    );
  }

  // Méthode pour optimiser les animations
  Widget _optimizedAnimation(Widget child) {
    if (_isLowPowerDevice || _lowPowerModeEnabled) {
      return child;
    }

    return child
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.1, end: 0, duration: 300.ms);
  }
}

// Classe pour la mise en cache des tuiles
class CachedNetworkTileProvider extends TileProvider {
  final Map<String, Uint8List> _cache = {};
  final int maxCacheSize;

  CachedNetworkTileProvider({this.maxCacheSize = 100});

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final url = getTileUrl(coordinates, options);

    return CachedNetworkImageProvider(
      url,
      cacheKey: 'tile_${coordinates.x}_${coordinates.y}_${coordinates.z}',
      maxWidth: 256,
      maxHeight: 256,
    );
  }

  void clearCache() {
    _cache.clear();
  }
}
