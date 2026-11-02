import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

/// Riverpod provider for [SecureStorageService].
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

/// Service encapsulating token storage and encrypted key-value pairs using FlutterSecureStorage.
class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions.defaultOptions,
              webOptions: WebOptions(
                dbName: 'family_expense_manager',
                publicKey: 'fem_secure_storage_pubkey',
              ),
            );

  // Access Token
  Future<String?> getAccessToken() async {
    return _storage.read(key: AppConstants.keyAccessToken);
  }

  Future<void> setAccessToken(String token) async {
    await _storage.write(key: AppConstants.keyAccessToken, value: token);
  }

  // Refresh Token
  Future<String?> getRefreshToken() async {
    return _storage.read(key: AppConstants.keyRefreshToken);
  }

  Future<void> setRefreshToken(String token) async {
    await _storage.write(key: AppConstants.keyRefreshToken, value: token);
  }

  // Active Family ID
  Future<String?> getActiveFamilyId() async {
    return _storage.read(key: AppConstants.keyFamilyId);
  }

  Future<void> setActiveFamilyId(String familyId) async {
    await _storage.write(key: AppConstants.keyFamilyId, value: familyId);
  }

  // Clear auth session
  Future<void> clearAuthSession() async {
    await _storage.delete(key: AppConstants.keyAccessToken);
    await _storage.delete(key: AppConstants.keyRefreshToken);
    await _storage.delete(key: AppConstants.keyUserId);
    await _storage.delete(key: AppConstants.keyFamilyId);
  }

  // Generic key-value helpers
  Future<String?> read(String key) => _storage.read(key: key);
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);
  Future<void> delete(String key) => _storage.delete(key: key);
  Future<void> clearAll() => _storage.deleteAll();
}
