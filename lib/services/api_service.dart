import 'dart:convert';
import 'package:flutter_activity_app/services/exceptions.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_activity_app/models/activity.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'dart:math';

class ApiService {
  final String baseUrl;
  final http.Client _httpClient;

  ApiService({
    required this.baseUrl,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  // Generic methods
  Future<dynamic> get(String endpoint) async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw ApiException(
          message: 'Failed to load data: ${response.statusCode}',
          statusCode: response.statusCode,
          responseBody: response.body,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to connect to the server: $e',
        statusCode: 0,
      );
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw ApiException(
          message: 'Failed to create data: ${response.statusCode}',
          statusCode: response.statusCode,
          responseBody: response.body,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to connect to the server: $e',
        statusCode: 0,
      );
    }
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    try {
      final token = await getAccessToken();
      final response = await _httpClient.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw ApiException(
          message: 'Failed to update data: ${response.statusCode}',
          statusCode: response.statusCode,
          responseBody: response.body,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to connect to the server: $e',
        statusCode: 0,
      );
    }
  }

  Future<Map<String, dynamic>> sendMultipartRequest(
      http.MultipartRequest request) async {
    try {
      // Retrieve the access token
      final token = await getAccessToken();
  
      // Add the token to the request headers
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
  
      // Send the request
      var response = await request.send();
  
      // Read the response
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Convert the response to a string
        var responseBody = await response.stream.bytesToString();
  
        // Return the response as JSON
        return jsonDecode(responseBody);
      } else {
        var responseBody = await response.stream.bytesToString();
        throw ApiException(
          message: 'Failed to send multipart request: ${response.statusCode}',
          statusCode: response.statusCode,
          responseBody: responseBody,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Error sending multipart request: $e',
        statusCode: 0,
      );
    }
  }

  Future<dynamic> delete(String endpoint) async {
    try {
      final token = await getAccessToken();
      final response = await _httpClient.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        throw ApiException(
          message: 'Failed to delete data: ${response.statusCode}',
          statusCode: response.statusCode,
          responseBody: response.body,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to connect to the server: $e',
        statusCode: 0,
      );
    }
  }

  // Specific methods for activities
  Future<List<Activity>> getActivities() async {
    try {
      print('Requesting activities from API...');
      final jsonData = await get('/activities');
      print('API response received: $jsonData');
  
      if (jsonData is List) {
        final activities = jsonData.map((json) => Activity.fromJson(json)).toList();
        print('Parsed ${activities.length} activities.');
        return activities;
      } else {
        throw Exception('Unexpected response format: $jsonData');
      }
    } catch (e) {
      print('Error fetching activities: $e');
      throw Exception('Failed to load activities: $e');
    }
  }

  Future<Activity> getActivityById(String id) async {
    final jsonData = await get('/activities/$id');
    return Activity.fromJson(jsonData);
  }

  Future<List<String>> getCategories() async {
    final jsonData = await get('/categories');
    return (jsonData as List).map((json) => json['name'] as String).toList();
  }

  Future<void> toggleFavorite(String activityId, bool isFavorite) async {
    await postWithAuth(
        '/users/favorites/$activityId', {'isFavorite': isFavorite});
  }

  Future<List<Activity>> getFavoriteActivities() async {
    final jsonData = await getWithAuth('/users/favorites');
    print('Favorite activities: $jsonData'); // Debugging log
    return (jsonData as List).map((json) => Activity.fromJson(json)).toList();
  }

  // Method to check if the backend is reachable
  Future<bool> isBackendReachable() async {
    try {
      print('Base URL: $baseUrl'); // Print the base URL for verification

      final response = await _httpClient.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 1));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken');
  }

  static Future<void> _saveTokens(
      String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', accessToken);
    await prefs.setString('refreshToken', refreshToken);
  }

  static Future<void> _clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('refreshToken');
  }

  Future<dynamic> getWithAuth(String endpoint) async {
    try {
      final token = await getAccessToken();

      final response = await _httpClient.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw ApiException(
          message: 'Failed to load data: ${response.statusCode}',
          statusCode: response.statusCode,
          responseBody: response.body,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to connect to the server: $e',
        statusCode: 0,
      );
    }
  }

  Future<dynamic> postWithAuth(
      String endpoint, Map<String, dynamic> data) async {
    try {
      final token = await getAccessToken();
      final response = await _httpClient.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw ApiException(
          message: 'Failed to create data: ${response.statusCode}',
          statusCode: response.statusCode,
          responseBody: response.body,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to connect to the server: $e',
        statusCode: 0,
      );
    }
  }

  Future<Map<String, dynamic>> multipartPost(
    String endpoint,
    Map<String, dynamic> data, {
    List<File>? imageFiles,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');

    // Get access token
    final token = await getAccessToken();
    print("token: $token");
    final request = http.MultipartRequest('POST', uri);

    // Convert data to string values to avoid type issues
    final stringData = data.map((key, value) => 
      MapEntry(key, value is String ? value : value.toString()));

    // Add data fields individually
    stringData.forEach((key, value) {
      request.fields[key] = value;
    });

    // Add images if provided
    if (imageFiles != null && imageFiles.isNotEmpty) {
      print("Adding ${imageFiles.length} images to request");
      
      for (var i = 0; i < imageFiles.length; i++) {
        final file = imageFiles[i];
        
        if (await file.exists()) {
          final stream = http.ByteStream(file.openRead());
          final length = await file.length();
          final filename = path.basename(file.path);
          
          print("Adding image $i: $filename (${length} bytes)");
          
          final multipartFile = http.MultipartFile(
            'image',  // Use consistent field name for all images
            stream,
            length,
            filename: filename,
            contentType: _getContentType(filename),
          );
          
          request.files.add(multipartFile);
        } else {
          print("Warning: Image file not found: ${file.path}");
        }
      }
    }

    // Add headers
    request.headers.addAll({
      if (token != null) 'Authorization': 'Bearer $token',
    });

    // Send request
    try {
      final streamedResponse = await request.send();
      final responseString = await streamedResponse.stream.bytesToString();
      
      print("Response status: ${streamedResponse.statusCode}");
      print("Response body: $responseString");
      
      if (streamedResponse.statusCode >= 200 && streamedResponse.statusCode < 300) {
        return json.decode(responseString);
      } else {
        throw ApiException(
          message: 'Request failed with status: ${streamedResponse.statusCode}',
          statusCode: streamedResponse.statusCode,
          responseBody: responseString,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Error during multipart request: $e',
        statusCode: 0,
      );
    }
  }

  Future<Map<String, dynamic>> multipartRequest(
    String method,
    String endpoint,
    Map<String, dynamic> data, {
    List<File>? imageFiles,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    
    // Get access token
    final token = await getAccessToken();
    print("Using token for multipart $method request: ${token != null ? token.substring(0, min(10, token.length)) + '...' : 'null'}");
    
    final request = http.MultipartRequest(method, uri);
    
    // Convert data to string values to avoid type issues
    final stringData = data.map((key, value) => 
      MapEntry(key, value is String ? value : value.toString()));

    // Add data fields individually
    stringData.forEach((key, value) {
      request.fields[key] = value;
    });
    
    // Add images if provided
    if (imageFiles != null && imageFiles.isNotEmpty) {
      print("Adding ${imageFiles.length} images to $method request");
      
      for (var i = 0; i < imageFiles.length; i++) {
        final file = imageFiles[i];
        
        if (await file.exists()) {
          final stream = http.ByteStream(file.openRead());
          final length = await file.length();
          final filename = path.basename(file.path);
          
          print("Adding image $i: $filename (${length} bytes)");
          
          final multipartFile = http.MultipartFile(
            'image', // Use a consistent field name for all images
            stream,
            length,
            filename: filename,
            contentType: _getContentType(filename),
          );
          
          request.files.add(multipartFile);
        } else {
          print("Warning: Image file not found: ${file.path}");
        }
      }
    }
    
    // Add headers including authorization
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    
    // Send request and handle response
    try {
      final streamedResponse = await request.send();
      final responseString = await streamedResponse.stream.bytesToString();
      
      print("Multipart $method response status: ${streamedResponse.statusCode}");
      print("Multipart $method response body: $responseString");
      
      if (streamedResponse.statusCode >= 200 && streamedResponse.statusCode < 300) {
        return json.decode(responseString);
      } else {
        throw ApiException(
          message: 'Request failed with status: ${streamedResponse.statusCode}',
          statusCode: streamedResponse.statusCode,
          responseBody: responseString,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Error during multipart $method request: $e',
        statusCode: 0,
      );
    }
  }

  // Helper method to determine content type based on file extension
  MediaType _getContentType(String filename) {
    final ext = path.extension(filename).toLowerCase();
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return MediaType('image', 'jpeg');
      case '.png':
        return MediaType('image', 'png');
      case '.gif':
        return MediaType('image', 'gif');
      case '.webp':
        return MediaType('image', 'webp');
      default:
        return MediaType('application', 'octet-stream');
    }
  }

   // Method to reject an activity
  Future<void> rejectActivity(String id) async {
    try {
      final response = await http.post(
        Uri.parse('https://yourapi.com/activities/$id/reject'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to reject activity');
      }
    } catch (e) {
      throw Exception('Error rejecting activity: $e');
    }
  }

  // Method to like an activity
  Future<void> likeActivity(String id) async {
    try {
      final response = await http.post(
        Uri.parse('https://yourapi.com/activities/$id/like'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to like activity');
      }
    } catch (e) {
      throw Exception('Error liking activity: $e');
    }
  }
// Nouvelle méthode pour télécharger uniquement des images
  Future<List<String>> uploadImages(List<File> imageFiles) async {
    final uri = Uri.parse('$baseUrl/upload');
    
    // Get access token
    final token = await getAccessToken();
    final request = http.MultipartRequest('POST', uri);
    
    print("Uploading ${imageFiles.length} images");
    
    // Add images to the request
    for (var i = 0; i < imageFiles.length; i++) {
      final file = imageFiles[i];
      
      if (await file.exists()) {
        final stream = http.ByteStream(file.openRead());
        final length = await file.length();
        final filename = path.basename(file.path);
        
        print("Adding image $i: $filename (${length} bytes)");
        
        final multipartFile = http.MultipartFile(
          'image',  // Use consistent field name for all images
          stream,
          length,
          filename: filename,
          contentType: _getContentType(filename),
        );
        
        request.files.add(multipartFile);
      } else {
        print("Warning: Image file not found: ${file.path}");
      }
    }
    
    // Add authorization header
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    
    // Send request
    try {
      final streamedResponse = await request.send();
      final responseString = await streamedResponse.stream.bytesToString();
      
      print("Image upload response status: ${streamedResponse.statusCode}");
      print("Image upload response body: $responseString");
      
      if (streamedResponse.statusCode >= 200 && streamedResponse.statusCode < 300) {
        final responseData = json.decode(responseString);
        if (responseData['success'] == true && responseData['urls'] != null) {
          return List<String>.from(responseData['urls']);
        } else {
          throw ApiException(
            message: 'Failed to upload images: ${responseData['message'] ?? 'Unknown error'}',
            statusCode: streamedResponse.statusCode,
            responseBody: responseString,
          );
        }
      } else {
        throw ApiException(
          message: 'Image upload failed with status: ${streamedResponse.statusCode}',
          statusCode: streamedResponse.statusCode,
          responseBody: responseString,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Error during image upload: $e',
        statusCode: 0,
      );
    }
  }
}


