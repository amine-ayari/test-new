import 'package:flutter/foundation.dart';

/// Configuration de l'application
class AppConfig {
  static const String apiBaseUrl = 'https://activityapp-backend.onrender.com/api';
  // For Android emulator, use 192.168.1.17 instead of localhost
  static String getApiBaseUrl() {
    // You can add platform-specific logic here if needed
    return apiBaseUrl;
  }
  /*  /// Obtenir l'URL de base de l'API en fonction de l'environnement
  static String getApiBaseUrl() {
    switch (_environment) {
      case 'prod':
        return _prodApiBaseUrl;
      case 'staging':
        return _stagingApiBaseUrl;
      default:
        return _devApiBaseUrl;
    }
  } */

  // URLs de base pour les environnements
  static const String _devApiBaseUrl = 'http://192.168.1.17:3000/api';
  static const String _stagingApiBaseUrl = 'http://192.168.1.17:3000/api';
  static const String _prodApiBaseUrl = 'http://192.168.1.17:3000/api';

  // URLs pour les sockets
  static const String _devSocketUrl = 'https://activityapp-backend.onrender.com';
  static const String _stagingSocketUrl = 'https://activityapp-backend.onrender.com';
  static const String _prodSocketUrl = 'https://activityapp-backend.onrender.com';

  // Clés d'API pour les services tiers
  static const String _devMapApiKey = 'dev_map_api_key';
  static const String _stagingMapApiKey = 'staging_map_api_key';
  static const String _prodMapApiKey = 'prod_map_api_key';

  // Environnement actuel
  static const String _environment =
      'dev'; // Changer à 'staging' ou 'prod' selon l'environnement

  /// Obtenir l'URL du socket en fonction de l'environnement
  static String getSocketUrl() {
    switch (_environment) {
      case 'prod':
        return _prodSocketUrl;
      case 'staging':
        return _stagingSocketUrl;
      default:
        return _devSocketUrl;
    }
  }

  /// Obtenir la clé d'API pour les cartes en fonction de l'environnement
  static String getMapApiKey() {
    switch (_environment) {
      case 'prod':
        return _prodMapApiKey;
      case 'staging':
        return _stagingMapApiKey;
      default:
        return _devMapApiKey;
    }
  }

  /// Vérifier si l'application est en mode développement
  static bool isDevelopment() {
    return _environment == 'dev';
  }

  /// Vérifier si l'application est en mode production
  static bool isProduction() {
    return _environment == 'prod';
  }

  /// Obtenir le timeout par défaut pour les requêtes HTTP (en secondes)
  static Duration getDefaultTimeout() {
    return const Duration(seconds: 30);
  }

  /// Obtenir le nombre maximum de tentatives pour les requêtes HTTP
  static int getMaxRetries() {
    return 3;
  }
}
