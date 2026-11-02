import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/domain/auth_state.dart';
import 'package:mobile/features/auth/domain/user.dart';
import 'package:mobile/features/auth/presentation/auth_controller.dart';
import 'package:mobile/features/auth/presentation/change_password_dialog.dart';
import 'package:mobile/features/family/domain/family.dart';
import 'package:mobile/features/profile/data/user_repository_impl.dart';
import 'package:mobile/features/profile/domain/user_repository.dart';
import 'package:mobile/features/profile/presentation/profile_screen.dart';

class MockUserRepository implements UserRepository {
  User currentUser = const User(
    id: 'user-123',
    fullName: 'Raj Sharma',
    email: 'raj.sharma@example.com',
    phone: '+91 9876543210',
    avatarUrl: '☕',
    isActive: true,
  );

  bool updateCalled = false;
  String? lastUpdatedName;
  String? lastUpdatedPhone;
  String? lastUpdatedAvatar;

  @override
  Future<User> getCurrentUser() async {
    return currentUser;
  }

  @override
  Future<User> updateCurrentUser({
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    updateCalled = true;
    lastUpdatedName = fullName;
    lastUpdatedPhone = phone;
    lastUpdatedAvatar = avatarUrl;
    currentUser = User(
      id: currentUser.id,
      fullName: fullName ?? currentUser.fullName,
      email: currentUser.email,
      phone: phone ?? currentUser.phone,
      avatarUrl: avatarUrl ?? currentUser.avatarUrl,
      isActive: true,
    );
    return currentUser;
  }
}

class FakeAuthController extends AuthController {
  bool logoutCalled = false;

  @override
  AuthState build() {
    return const AuthState.authenticated(
      user: User(
        id: 'user-123',
        fullName: 'Raj Sharma',
        email: 'raj.sharma@example.com',
        phone: '+91 9876543210',
        avatarUrl: '☕',
        isActive: true,
      ),
      family: Family(
        id: 'family-100',
        name: 'The Sharma Household',
        currency: 'INR',
        createdBy: 'user-123',
        userRole: 'owner',
      ),
    );
  }

  @override
  Future<void> logout() async {
    logoutCalled = true;
    state = const AuthState.unauthenticated();
  }

  @override
  Future<void> refreshProfile() async {
    // Keep user state updated
    final user = state.user;
    if (user != null) {
      state = state.copyWith(
        user: User(
          id: user.id,
          fullName: 'Raj V. Sharma',
          email: user.email,
          phone: '+91 9999988888',
          avatarUrl: '🌿',
          isActive: true,
        ),
      );
    }
  }
}

Widget createTestWidget({
  required MockUserRepository mockUserRepo,
  required FakeAuthController fakeAuthController,
}) {
  return ProviderScope(
    overrides: [
      userRepositoryProvider.overrideWithValue(mockUserRepo),
      authControllerProvider.overrideWith(() => fakeAuthController),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: const ProfileScreen(),
    ),
  );
}

void main() {
  late MockUserRepository mockUserRepo;
  late FakeAuthController fakeAuthController;

  setUp(() {
    mockUserRepo = MockUserRepository();
    fakeAuthController = FakeAuthController();
  });

  group('Profile and Settings Screen Tests', () {
    testWidgets('1. Displays user profile details: Name, Email, Phone, Role, and Avatar',
        (tester) async {
      tester.view.physicalSize = const Size(450 * 2, 1200 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(
          mockUserRepo: mockUserRepo,
          fakeAuthController: fakeAuthController,
        ),
      );
      await tester.pumpAndSettle();

      // Verify Profile Card elements
      expect(find.text('Raj Sharma'), findsWidgets);
      expect(find.text('raj.sharma@example.com'), findsOneWidget);
      expect(find.text('+91 9876543210'), findsOneWidget);
      expect(find.text('Role: OWNER'), findsOneWidget);
      expect(find.text('☕'), findsOneWidget);

      // Verify Preferences section
      expect(find.text('Preferences'), findsOneWidget);
      expect(find.text('Currency'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Theme'), findsOneWidget);

      // Verify Family Hub section
      expect(find.text('Family Hub'), findsOneWidget);
      expect(find.text('Family Space'), findsOneWidget);

      // Verify Security section
      expect(find.text('Security'), findsOneWidget);
      expect(find.text('Change Password'), findsOneWidget);

      // Verify Legal & Information section
      expect(find.text('Information'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Terms of Service'), findsOneWidget);

      // Verify Logout
      final logoutBtn = find.byKey(const Key('logout_button'));
      await tester.scrollUntilVisible(logoutBtn, 200);
      expect(logoutBtn, findsOneWidget);
    });

    testWidgets('2. Updates profile name and phone via Edit Profile dialog',
        (tester) async {
      tester.view.physicalSize = const Size(450 * 2, 1200 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(
          mockUserRepo: mockUserRepo,
          fakeAuthController: fakeAuthController,
        ),
      );
      await tester.pumpAndSettle();

      // Tap Edit Profile button
      final editBtn = find.text('Edit Profile').first;
      await tester.tap(editBtn);
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AlertDialog, 'Edit Profile'), findsOneWidget);

      // Enter new name and phone
      final nameField = find.widgetWithText(TextFormField, 'Raj Sharma');
      await tester.enterText(nameField, 'Raj V. Sharma');

      final phoneField = find.widgetWithText(TextFormField, '+91 9876543210');
      await tester.enterText(phoneField, '+91 9999988888');

      // Tap Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(mockUserRepo.updateCalled, isTrue);
      expect(mockUserRepo.lastUpdatedName, 'Raj V. Sharma');
      expect(mockUserRepo.lastUpdatedPhone, '+91 9999988888');
      expect(find.text('Profile updated successfully!'), findsOneWidget);
    });

    testWidgets('3. Avatar picker opens and updates avatar emoji',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          mockUserRepo: mockUserRepo,
          fakeAuthController: fakeAuthController,
        ),
      );
      await tester.pumpAndSettle();

      // Tap camera icon on avatar
      final cameraIcon = find.byIcon(Icons.camera_alt_rounded);
      await tester.tap(cameraIcon);
      await tester.pumpAndSettle();

      expect(find.text('Choose Avatar'), findsOneWidget);
      expect(find.text('🌿'), findsOneWidget);

      // Pick '🌿' avatar
      await tester.tap(find.text('🌿'));
      await tester.pumpAndSettle();

      expect(mockUserRepo.updateCalled, isTrue);
      expect(mockUserRepo.lastUpdatedAvatar, '🌿');
    });

    testWidgets('4. Currency picker changes selected currency',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          mockUserRepo: mockUserRepo,
          fakeAuthController: fakeAuthController,
        ),
      );
      await tester.pumpAndSettle();

      // Tap Currency tile
      await tester.tap(find.text('Currency'));
      await tester.pumpAndSettle();

      expect(find.text('Select Currency'), findsOneWidget);
      expect(find.text('US Dollar (\$)'), findsOneWidget);

      // Select USD
      await tester.tap(find.text('US Dollar (\$)'));
      await tester.pumpAndSettle();

      // Dialog closed and subtitle updated
      expect(find.text('US Dollar (\$)'), findsOneWidget);
    });

    testWidgets('5. Notifications switch toggles state',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          mockUserRepo: mockUserRepo,
          fakeAuthController: fakeAuthController,
        ),
      );
      await tester.pumpAndSettle();

      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);

      final switchWidget = tester.widget<Switch>(switchFinder);
      expect(switchWidget.value, isTrue);

      // Toggle switch off
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      final updatedSwitch = tester.widget<Switch>(switchFinder);
      expect(updatedSwitch.value, isFalse);
      expect(find.text('Notifications turned off'), findsOneWidget);
    });

    testWidgets('6. Theme picker opens and allows selecting Dark Theme',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          mockUserRepo: mockUserRepo,
          fakeAuthController: fakeAuthController,
        ),
      );
      await tester.pumpAndSettle();

      // Tap Theme tile
      await tester.tap(find.text('Theme'));
      await tester.pumpAndSettle();

      expect(find.text('Appearance & Theme'), findsOneWidget);
      expect(find.text('Dark Theme'), findsOneWidget);

      // Select Dark Theme
      await tester.tap(find.text('Dark Theme'));
      await tester.pumpAndSettle();

      // Bottom sheet closes and theme updates
      expect(find.text('Vintage Dark (Deep Mocha)'), findsOneWidget);
    });

    testWidgets('7. Security Change Password opens ChangePasswordDialog',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          mockUserRepo: mockUserRepo,
          fakeAuthController: fakeAuthController,
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to Change Password and tap
      await tester.scrollUntilVisible(find.text('Change Password'), 100);
      await tester.tap(find.text('Change Password'));
      await tester.pumpAndSettle();

      expect(find.byType(ChangePasswordDialog), findsOneWidget);
      expect(find.text('Current Password'), findsOneWidget);
      expect(find.text('New Password'), findsOneWidget);
      expect(find.text('Confirm New Password'), findsOneWidget);

      // Close dialog
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.byType(ChangePasswordDialog), findsNothing);
    });

    testWidgets('8. About, Privacy Policy, and Terms dialogs open with proper contents',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          mockUserRepo: mockUserRepo,
          fakeAuthController: fakeAuthController,
        ),
      );
      await tester.pumpAndSettle();

      // 1. About
      await tester.scrollUntilVisible(find.text('About'), 100);
      await tester.tap(find.text('About'));
      await tester.pumpAndSettle();
      expect(find.text('Version 1.0.0'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // 2. Privacy Policy
      await tester.scrollUntilVisible(find.text('Privacy Policy'), 100);
      await tester.tap(find.text('Privacy Policy'));
      await tester.pumpAndSettle();
      expect(find.text('Understood'), findsOneWidget);
      await tester.tap(find.text('Understood'));
      await tester.pumpAndSettle();

      // 3. Terms of Service
      await tester.scrollUntilVisible(find.text('Terms of Service'), 100);
      await tester.tap(find.text('Terms of Service'));
      await tester.pumpAndSettle();
      expect(find.text('I Agree'), findsOneWidget);
      await tester.tap(find.text('I Agree'));
      await tester.pumpAndSettle();
    });

    testWidgets('9. Logout button shows confirmation dialog and invokes AuthController.logout()',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          mockUserRepo: mockUserRepo,
          fakeAuthController: fakeAuthController,
        ),
      );
      await tester.pumpAndSettle();

      // Scroll down to Logout button
      final logoutBtn = find.byKey(const Key('logout_button'));
      await tester.scrollUntilVisible(logoutBtn, 200);
      await tester.tap(logoutBtn);
      await tester.pumpAndSettle();

      // Confirmation dialog
      expect(find.text('Sign Out'), findsWidgets);
      expect(
        find.text('Are you sure you want to sign out of Family Expense Manager?'),
        findsOneWidget,
      );

      // Tap Sign Out confirm
      final confirmBtn = find.byKey(const Key('confirm_logout_button'));
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      expect(fakeAuthController.logoutCalled, isTrue);
    });
  });
}
