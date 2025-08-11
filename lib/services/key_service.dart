import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:models/models.dart';

/// Service for managing secure storage and retrieval of cryptographic keys
class KeyService {
  static const String _privateKeyKey = 'nostr_private_key';
  static const String _firstLaunchKey = 'app_first_launch';

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      // Use AES encryption
      encryptedSharedPreferences: true,
    ),
  );

  /// Gets the stored private key, or generates and stores a new one if none exists
  static Future<String> getOrCreatePrivateKey() async {
    try {
      // Check if we have a stored private key
      final storedKey = await getStoredPrivateKey();
      if (storedKey != null) {
        debugPrint('KeyService: Using existing private key');
        return storedKey;
      }

      // No stored key found, generate a new one
      debugPrint('KeyService: No existing private key found, generating new one');
      final newPrivateKey = Utils.generateRandomHex64();
      
      // Store the new private key
      await storePrivateKey(newPrivateKey);
      
      // Mark that this is no longer the first launch
      await _markFirstLaunchComplete();
      
      debugPrint('KeyService: New private key generated and stored');
      return newPrivateKey;
    } catch (e) {
      debugPrint('KeyService: Error in getOrCreatePrivateKey: $e');
      // If we can't access secure storage, fall back to generating a temporary key
      // This ensures the app still works but the key won't persist
      return Utils.generateRandomHex64();
    }
  }

  /// Stores a private key securely
  static Future<void> storePrivateKey(String privateKey) async {
    try {
      await _storage.write(key: _privateKeyKey, value: privateKey);
      debugPrint('KeyService: Private key stored successfully');
    } catch (e) {
      debugPrint('KeyService: Failed to store private key: $e');
      throw Exception('Failed to store private key securely');
    }
  }

  /// Retrieves the stored private key, or null if none exists
  static Future<String?> getStoredPrivateKey() async {
    try {
      return await _storage.read(key: _privateKeyKey);
    } catch (e) {
      debugPrint('KeyService: Failed to read private key: $e');
      return null;
    }
  }

  /// Checks if this is the first launch of the app
  static Future<bool> isFirstLaunch() async {
    try {
      final firstLaunchComplete = await _storage.read(key: _firstLaunchKey);
      return firstLaunchComplete == null;
    } catch (e) {
      debugPrint('KeyService: Failed to check first launch status: $e');
      // If we can't read, assume it's not the first launch to be safe
      return false;
    }
  }

  /// Marks the first launch as complete
  static Future<void> _markFirstLaunchComplete() async {
    try {
      await _storage.write(key: _firstLaunchKey, value: 'completed');
    } catch (e) {
      debugPrint('KeyService: Failed to mark first launch complete: $e');
    }
  }

  /// Clears all stored keys (for logout/reset functionality)
  static Future<void> clearStoredKeys() async {
    try {
      await _storage.delete(key: _privateKeyKey);
      await _storage.delete(key: _firstLaunchKey);
      debugPrint('KeyService: All keys cleared successfully');
    } catch (e) {
      debugPrint('KeyService: Failed to clear keys: $e');
      throw Exception('Failed to clear stored keys');
    }
  }

  /// Gets all stored key information (for debugging/settings display)
  static Future<Map<String, dynamic>> getKeyInfo() async {
    try {
      final hasPrivateKey = await getStoredPrivateKey() != null;
      final isFirst = await isFirstLaunch();
      
      return {
        'hasStoredPrivateKey': hasPrivateKey,
        'isFirstLaunch': isFirst,
        'storageAvailable': true,
      };
    } catch (e) {
      debugPrint('KeyService: Failed to get key info: $e');
      return {
        'hasStoredPrivateKey': false,
        'isFirstLaunch': true,
        'storageAvailable': false,
        'error': e.toString(),
      };
    }
  }

  /// Generates a new private key and replaces the existing one
  /// WARNING: This will cause loss of the previous identity
  static Future<String> regeneratePrivateKey() async {
    try {
      debugPrint('KeyService: Regenerating private key - this will change user identity');
      
      // Generate new private key
      final newPrivateKey = Utils.generateRandomHex64();
      
      // Store the new private key (overwrites the old one)
      await storePrivateKey(newPrivateKey);
      
      debugPrint('KeyService: Private key regenerated successfully');
      return newPrivateKey;
    } catch (e) {
      debugPrint('KeyService: Failed to regenerate private key: $e');
      throw Exception('Failed to regenerate private key');
    }
  }

  /// Exports the private key in nsec format for backup
  /// WARNING: This exposes the private key - use with extreme caution
  static Future<String?> exportPrivateKeyAsNsec() async {
    try {
      final privateKey = await getStoredPrivateKey();
      if (privateKey == null) return null;
      
      // Convert hex private key to nsec format
      return Utils.encodeShareableFromString(privateKey, type: 'nsec');
    } catch (e) {
      debugPrint('KeyService: Failed to export private key: $e');
      return null;
    }
  }

  /// Imports a private key from nsec format
  /// WARNING: This will replace the existing private key
  static Future<void> importPrivateKeyFromNsec(String nsec) async {
    try {
      // Decode nsec to get hex private key
      final privateKey = Utils.decodeShareableToString(nsec);
      
      // Validate that it's a valid private key
      if (privateKey.length != 64) {
        throw Exception('Invalid private key length');
      }
      
      // Store the imported private key
      await storePrivateKey(privateKey);
      
      debugPrint('KeyService: Private key imported successfully');
    } catch (e) {
      debugPrint('KeyService: Failed to import private key: $e');
      throw Exception('Failed to import private key: $e');
    }
  }
}