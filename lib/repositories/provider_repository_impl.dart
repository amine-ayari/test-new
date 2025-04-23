import 'dart:convert';
import 'dart:io';
import 'package:flutter_activity_app/models/activity.dart';
import 'package:flutter_activity_app/models/user.dart';
import 'package:flutter_activity_app/repositories/provider_repository.dart';
import 'package:flutter_activity_app/services/api_service.dart';
import 'package:flutter_activity_app/services/exceptions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class ProviderRepositoryImpl implements ProviderRepository {
  final SharedPreferences _sharedPreferences;
  final ApiService _apiService;
  final String _activitiesKey = 'provider_activities';

  ProviderRepositoryImpl(this._sharedPreferences, this._apiService);

  @override
  Future<List<Activity>> getProviderActivities(String providerId) async {
    try {
      print('Fetching activities for provider: $providerId');
      final response = await _apiService.getWithAuth('/providers');
      print('🔍 Response from backend: $response');

      if (response['success'] == true && response['data'] is List) {
        return (response['data'] as List)
            .map((json) => Activity.fromJson(json))
            .toList();
      } else {
        throw Exception('Invalid API response format');
      }
    } catch (e) {
      print('❌ Error: $e');
      rethrow;
    }
  }

@override
Future<Activity> createActivity(Activity activity) async {
  print('Creating activity: ${activity.toJson()}');
  try {
    // Vérifier que toutes les données requises sont présentes
    _validateActivityData(activity);
    
    // Préparer les images si elles existent
    List<File>? imageFiles;
    if (activity.images != null && activity.images.isNotEmpty) {
      imageFiles = activity.images.map((imagePath) => File(imagePath)).toList();
      imageFiles = imageFiles.where((file) => file.existsSync()).toList();
      
      if (imageFiles.isEmpty) {
        print('Warning: No valid image files found');
      } else {
        print('Found ${imageFiles.length} valid image files');
      }
    }
    
    // Créer une copie des données pour éviter de modifier l'objet original
    Map<String, dynamic> activityData = Map<String, dynamic>.from(activity.toJson());
    
    // Supprimer les champs qui ne doivent pas être envoyés directement
    activityData.remove('reviews');
    activityData.remove('rating');
    activityData.remove('_id'); // Supprimer l'ID vide
    
    // Extraire l'ID du provider
    if (activityData.containsKey('provider') && activityData['provider'] is Map) {
      activityData['providerId'] = activityData['provider']['id'];
      activityData.remove('provider');
    }
    
    // Supprimer les images des données JSON car elles seront envoyées séparément
    activityData.remove('images');
    
    // Étape 1: Télécharger les images si elles existent
    List<String> imageUrls = [];
    if (imageFiles != null && imageFiles.isNotEmpty) {
      try {
        // Utiliser une route spécifique pour l'upload d'images
        imageUrls = await _apiService.uploadImages(imageFiles);
        
        if (imageUrls.isNotEmpty) {
          // Définir l'image principale comme la première image téléchargée
          activityData['image'] = imageUrls[0];
          // Ajouter toutes les URLs d'images
          activityData['images'] = imageUrls;
        }
      } catch (e) {
        print('Error uploading images: $e');
        // Continuer sans images si l'upload échoue
      }
    }
    
    // Étape 2: Envoyer les données de l'activité avec les URLs des images
    print('Sending activity data: $activityData');
    
    final response = await _apiService.postWithAuth('/activities', activityData);
    
    if (response['success'] == true && response['data'] != null) {
      return Activity.fromJson(response['data']);
    } else {
      throw ApiException(
        message: 'Failed to create activity: ${response['message'] ?? 'Unknown error'}',
        statusCode: 400,
        responseBody: json.encode(response),
      );
    }
  } catch (e) {
    print('Error creating activity: $e');
    rethrow;
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
    throw ApiException(
      message: 'Validation échouée: ${errors.join(', ')}',
      statusCode: 400,
    );
  }
}

 @override
Future<Activity> updateActivity(Activity activity) async {
  print('Updating activity: ${activity.toJson()}');
  try {
    // Vérifier que toutes les données requises sont présentes
    _validateActivityData(activity);
    
    // Vérifier que l'ID de l'activité est présent
    if (activity.id?.isEmpty ?? true) {
      throw ApiException(
        message: 'ID de l\'activité manquant pour la mise à jour',
        statusCode: 400,
      );
    }
    
    // Préparer les images si elles existent
    List<File>? imageFiles;
    if (activity.images != null && activity.images.isNotEmpty) {
      // Filtrer pour ne garder que les nouvelles images (celles qui sont des chemins de fichiers locaux)
      List<String> cloudinaryUrls = [];
      List<String> localFilePaths = [];
      
      for (String path in activity.images) {
        if (path.startsWith('http') || path.startsWith('https')) {
          // C'est une URL Cloudinary existante
          cloudinaryUrls.add(path);
        } else {
          // C'est un chemin de fichier local
          localFilePaths.add(path);
        }
      }
      
      // Convertir les chemins locaux en objets File
      if (localFilePaths.isNotEmpty) {
        imageFiles = localFilePaths.map((path) => File(path)).toList();
        imageFiles = imageFiles.where((file) => file.existsSync()).toList();
        
        if (imageFiles.isEmpty) {
          print('Warning: No valid new image files found');
        } else {
          print('Found ${imageFiles.length} valid new image files');
        }
      }
      
      // Créer une copie des données pour éviter de modifier l'objet original
      Map<String, dynamic> activityData = Map<String, dynamic>.from(activity.toJson());
      
      // Supprimer les champs qui ne doivent pas être envoyés directement
      activityData.remove('reviews');
      activityData.remove('rating');
      
      // Extraire l'ID du provider
      if (activityData.containsKey('provider') && activityData['provider'] is Map) {
        activityData['providerId'] = activityData['provider']['id'];
        activityData.remove('provider');
      }
      
      // Étape 1: Télécharger les nouvelles images si elles existent
      List<String> newImageUrls = [];
      if (imageFiles != null && imageFiles.isNotEmpty) {
        try {
          // Utiliser une route spécifique pour l'upload d'images
          newImageUrls = await _apiService.uploadImages(imageFiles);
        } catch (e) {
          print('Error uploading new images: $e');
          // Continuer sans les nouvelles images si l'upload échoue
        }
      }
      
      // Combiner les URLs existantes et les nouvelles URLs
      List<String> allImageUrls = [...cloudinaryUrls, ...newImageUrls];
      
      // Mettre à jour les images dans les données
      if (allImageUrls.isNotEmpty) {
        // Utiliser l'image principale sélectionnée ou la première image
        activityData['image'] = activity.image.startsWith('http') ? 
                               activity.image : 
                               (newImageUrls.isNotEmpty ? newImageUrls[0] : cloudinaryUrls[0]);
        activityData['images'] = allImageUrls;
      }
      
      // Supprimer les images des données JSON car nous avons déjà traité ce champ
      activityData.remove('images');
      
      // Étape 2: Envoyer les données de l'activité avec les URLs des images
      print('Sending updated activity data: $activityData');
      
      final response = await _apiService.put('/activities/${activity.id}', activityData);
      
      if (response['success'] == true && response['data'] != null) {
        return Activity.fromJson(response['data']);
      } else {
        throw ApiException(
          message: 'Failed to update activity: ${response['message'] ?? 'Unknown error'}',
          statusCode: 400,
          responseBody: json.encode(response),
        );
      }
    }
    
    // Si aucune image n'est présente, envoyer simplement les données
    Map<String, dynamic> activityData = Map<String, dynamic>.from(activity.toJson());
    activityData.remove('reviews');
    activityData.remove('rating');
    
    if (activityData.containsKey('provider') && activityData['provider'] is Map) {
      activityData['providerId'] = activityData['provider']['id'];
      activityData.remove('provider');
    }
    
    final response = await _apiService.put('/activities/${activity.id}', activityData);
    
    if (response['success'] == true && response['data'] != null) {
      return Activity.fromJson(response['data']);
    } else {
      throw ApiException(
        message: 'Failed to update activity: ${response['message'] ?? 'Unknown error'}',
        statusCode: 400,
        responseBody: json.encode(response),
      );
    }
  } catch (e) {
    print('Error updating activity: $e');
    rethrow;
  }
}

  @override
  Future<void> deleteActivity(String activityId) async {
    try {
      await _apiService.delete('/activities/$activityId');
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Activity> updateAvailability(String activityId,
      List<AvailableDate> dates, List<AvailableTime> times) async {
    try {
      final response =
          await _apiService.put('/activities/$activityId/availability', {
        'dates': dates.map((d) => d.toJson()).toList(),
        'times': times.map((t) => t.toJson()).toList(),
      });
      return Activity.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Local storage helpers (can be removed if not needed elsewhere)
  List<Activity> _getLocalActivities() {
    final jsonString = _sharedPreferences.getString(_activitiesKey);
    if (jsonString == null) return [];

    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.map((json) => Activity.fromJson(json)).toList();
  }

  Future<void> _saveLocalActivities(List<Activity> activities) async {
    final jsonList = activities.map((a) => a.toJson()).toList();
    await _sharedPreferences.setString(_activitiesKey, jsonEncode(jsonList));
  }
@override
Future<User> updateProviderVerificationInfo({
  required String providerId,
  String? businessName,
  String? taxId,
  String? nationalId,
}) async {
  try {
    final updateData = {
      if (businessName != null) 'businessName': businessName,
      if (taxId != null) 'taxId': taxId,
      if (nationalId != null) 'nationalId': nationalId,
    };
    
    if (updateData.isEmpty) {
      throw ApiException(
        message: 'No data provided for update',
        statusCode: 400,
      );
    }
    
    final response = await _apiService.put(
      '/providers/$providerId/verification',
      updateData,
    );
    
    if (response['success'] == true && response['data'] != null) {
      return User.fromJson(response['data']);
    } else {
      throw ApiException(
        message: 'Failed to update provider verification info: ${response['message'] ?? 'Unknown error'}',
        statusCode: 400,
        responseBody: json.encode(response),
      );
    }
  } catch (e) {
    if (e is ApiException) rethrow;
    throw ApiException(
      message: 'Error updating provider verification info: $e',
      statusCode: 500,
    );
  }
}

@override
Future<User> getProviderVerificationStatus(String providerId) async {
  try {
    final response = await _apiService.getWithAuth('/providers/$providerId');
    
    if (response['success'] == true && response['data'] != null) {
      return User.fromJson(response['data']);
    } else {
      throw ApiException(
        message: 'Failed to get provider verification status: ${response['message'] ?? 'Unknown error'}',
        statusCode: 400,
        responseBody: json.encode(response),
      );
    }
  } catch (e) {
    if (e is ApiException) rethrow;
    throw ApiException(
      message: 'Error getting provider verification status: $e',
      statusCode: 500,
    );
  }
}}