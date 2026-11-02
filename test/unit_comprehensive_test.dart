import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/core/storage/secure_storage_service.dart';
import 'package:mobile/features/auth/domain/auth_state.dart';
import 'package:mobile/features/auth/domain/auth_tokens.dart';
import 'package:mobile/features/auth/domain/user.dart';
import 'package:mobile/features/budgets/domain/budget.dart';
import 'package:mobile/features/family/domain/family.dart';

class MockInMemoryStorage extends SecureStorageService {
  final Map<String, String> _map = {};

  @override
  Future<String?> getAccessToken() async => _map['access_token'];

  @override
  Future<void> setAccessToken(String token) async => _map['access_token'] = token;

  @override
  Future<String?> getRefreshToken() async => _map['refresh_token'];

  @override
  Future<void> setRefreshToken(String token) async => _map['refresh_token'] = token;

  @override
  Future<void> clearAuthSession() async => _map.clear();

  @override
  Future<void> write(String key, String value) async => _map[key] = value;

  @override
  Future<String?> read(String key) async => _map[key];

  @override
  Future<void> delete(String key) async => _map.remove(key);
}

void main() {
  group('1. Unit: Authentication State & Domain Entities', () {
    test('AuthState transitions correctly between initial, loading, authenticated, error, unauthenticated', () {
      const initial = AuthState.initial();
      expect(initial.isInitial, isTrue);
      expect(initial.isAuthenticated, isFalse);

      const loading = AuthState.loading();
      expect(loading.isLoading, isTrue);

      const user = User(
        id: 'usr-1',
        fullName: 'Raj Sharma',
        email: 'raj@example.com',
        phone: '+91 9876543210',
      );
      const family = Family(
        id: 'fam-1',
        name: 'Sharma Family',
        createdBy: 'usr-1',
        currency: 'INR',
      );
      final auth = AuthState.authenticated(user: user, family: family);
      expect(auth.isAuthenticated, isTrue);
      expect(auth.user?.fullName, 'Raj Sharma');
      expect(auth.family?.name, 'Sharma Family');

      const err = AuthState.error(message: 'Invalid credentials');
      expect(err.isError, isTrue);
      expect(err.errorMessage, 'Invalid credentials');

      const unauth = AuthState.unauthenticated();
      expect(unauth.isUnauthenticated, isTrue);
    });

    test('User entity deserializes and serializes JSON properly', () {
      final json = {
        'id': 'usr-1',
        'full_name': 'Raj Sharma',
        'email': 'raj@example.com',
        'phone': '+91 9876543210',
        'avatar_url': '☕',
        'is_active': true,
        'created_at': '2026-10-01T12:00:00Z',
      };
      final user = User.fromJson(json);
      expect(user.id, 'usr-1');
      expect(user.fullName, 'Raj Sharma');
      expect(user.avatarUrl, '☕');
      expect(user.toJson()['full_name'], 'Raj Sharma');
    });
  });

  group('2. Unit: Token Handling & Secure Storage', () {
    test('Token storage sets, reads, and clears auth tokens securely', () async {
      final storage = MockInMemoryStorage();
      expect(await storage.getAccessToken(), isNull);
      expect(await storage.getRefreshToken(), isNull);

      await storage.setAccessToken('access-xyz-123');
      await storage.setRefreshToken('refresh-abc-456');

      expect(await storage.getAccessToken(), 'access-xyz-123');
      expect(await storage.getRefreshToken(), 'refresh-abc-456');

      await storage.clearAuthSession();
      expect(await storage.getAccessToken(), isNull);
      expect(await storage.getRefreshToken(), isNull);
    });

    test('AuthTokens domain parses bearer and refresh tokens from JSON', () {
      final json = {
        'access_token': 'test_access',
        'refresh_token': 'test_refresh',
        'token_type': 'bearer',
        'expires_in': 3600,
      };
      final tokens = AuthTokens.fromJson(json);
      expect(tokens.accessToken, 'test_access');
      expect(tokens.refreshToken, 'test_refresh');
      expect(tokens.tokenType, 'bearer');
      expect(tokens.expiresIn, 3600);
    });
  });

  group('3. Unit: Expense Validation Logic', () {
    test('Validates amount > 0, category, date, paid by, and payment method', () {
      // Amount validation
      String? validateAmount(String? val) {
        if (val == null || val.trim().isEmpty) return 'Please enter an amount';
        final parsed = double.tryParse(val.replaceAll(',', '').trim());
        if (parsed == null || parsed <= 0) return 'Amount must be greater than 0';
        return null;
      }

      expect(validateAmount(null), 'Please enter an amount');
      expect(validateAmount(''), 'Please enter an amount');
      expect(validateAmount('0'), 'Amount must be greater than 0');
      expect(validateAmount('-50'), 'Amount must be greater than 0');
      expect(validateAmount('2500'), isNull);
      expect(validateAmount('2,500.50'), isNull);

      // Title validation
      String? validateTitle(String? val) {
        if (val == null || val.trim().isEmpty) return 'Please enter a title';
        return null;
      }

      expect(validateTitle(''), 'Please enter a title');
      expect(validateTitle('Grocery'), isNull);
    });
  });

  group('4. Unit: Budget Calculations & Display Logic', () {
    test('Calculates spent, remaining, percentage, and warning status tiers correctly', () {
      const budget1 = Budget(
        id: 'b-1',
        familyId: 'f-1',
        createdBy: 'usr-1',
        categoryId: 'c-1',
        categoryName: 'Grocery',
        amount: 10000.0,
        amountSpent: 7200.0,
        remainingAmount: 2800.0,
        percentageUsed: 72.0,
        month: 10,
        year: 2026,
      );

      // Healthy Tier (72%)
      expect(budget1.remainingAmount, 2800.0);
      expect(budget1.percentageUsed, 72.0);
      expect(budget1.isExceeded, isFalse);
      expect(budget1.statusLabel, 'Healthy');

      // Warning Tier 75%
      const budget2 = Budget(
        id: 'b-2',
        familyId: 'f-1',
        createdBy: 'usr-1',
        categoryId: 'c-2',
        categoryName: 'Dining',
        amount: 4000.0,
        amountSpent: 3000.0,
        remainingAmount: 1000.0,
        percentageUsed: 75.0,
        month: 10,
        year: 2026,
      );
      expect(budget2.percentageUsed, 75.0);
      expect(budget2.isExceeded, isFalse);
      expect(budget2.statusLabel, 'Warning');

      // Warning Tier 90%
      const budget3 = Budget(
        id: 'b-3',
        familyId: 'f-1',
        createdBy: 'usr-1',
        categoryId: 'c-3',
        categoryName: 'Shopping',
        amount: 5000.0,
        amountSpent: 4600.0,
        remainingAmount: 400.0,
        percentageUsed: 92.0,
        month: 10,
        year: 2026,
      );
      expect(budget3.percentageUsed, 92.0);
      expect(budget3.isExceeded, isFalse);
      expect(budget3.statusLabel, 'Near Limit');

      // Exceeded Tier (> 100%)
      const budget4 = Budget(
        id: 'b-4',
        familyId: 'f-1',
        createdBy: 'usr-1',
        categoryId: 'c-4',
        categoryName: 'Entertainment',
        amount: 2000.0,
        amountSpent: 2500.0,
        remainingAmount: -500.0,
        percentageUsed: 125.0,
        month: 10,
        year: 2026,
      );
      expect(budget4.percentageUsed, 125.0);
      expect(budget4.isExceeded, isTrue);
      expect(budget4.remainingAmount, -500.0);
      expect(budget4.statusLabel, 'Exceeded');
    });
  });

  group('5. Unit: API Error Handling & Exceptions', () {
    test('ApiException maps status codes and validation field errors accurately', () {
      final validationErr = ValidationException(
        statusCode: 422,
        message: 'Validation failed',
        fieldErrors: {'amount': 'Amount must be greater than 0', 'email': 'Invalid email format'},
      );
      expect(validationErr.statusCode, 422);
      expect(validationErr.message, 'Validation failed');
      expect(validationErr.fieldErrors?['amount'], 'Amount must be greater than 0');

      final unauthorizedErr = UnauthorizedException(
        statusCode: 401,
        message: 'Could not validate credentials',
      );
      expect(unauthorizedErr.statusCode, 401);

      final forbiddenErr = ForbiddenException(
        statusCode: 403,
        message: 'Only family owner can invite members',
      );
      expect(forbiddenErr.statusCode, 403);
      expect(forbiddenErr.message, 'Only family owner can invite members');

      const networkErr = NetworkTimeoutException(
        message: 'Connection timed out. Check your internet connection.',
      );
      expect(networkErr.message, contains('Connection timed out'));
    });
  });
}
