import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/budgets/presentation/budgets_screen.dart';
import '../features/dashboard/presentation/home_screen.dart';
import '../features/expenses/domain/expense.dart';
import '../features/expenses/presentation/expense_detail_screen.dart';
import '../features/expenses/presentation/expense_form_screen.dart';
import '../features/expenses/presentation/transactions_screen.dart';
import '../features/family/presentation/accept_invitation_screen.dart';
import '../features/family/presentation/create_family_screen.dart';
import '../features/family/presentation/family_home_screen.dart';
import '../features/family/presentation/family_members_screen.dart';
import '../features/family/presentation/family_setup_screen.dart';
import '../features/family/presentation/invite_spouse_screen.dart';
import '../features/income/domain/income.dart';
import '../features/income/presentation/income_detail_screen.dart';
import '../features/income/presentation/income_form_screen.dart';
import '../features/income/presentation/income_list_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/reports/presentation/reports_screen.dart';
import 'shell_scaffold.dart';

final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

/// Riverpod provider exposing the configured [GoRouter] instance.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: false,
    routes: [
      // 1. Splash Screen
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // 2. Authentication & Onboarding Screens
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/family-setup',
        name: 'family-setup',
        builder: (context, state) => const FamilySetupScreen(),
      ),

      // 3. Family Management Screens
      GoRoute(
        path: '/family',
        name: 'family',
        builder: (context, state) => const FamilyHomeScreen(),
      ),
      GoRoute(
        path: '/family/create',
        name: 'family-create',
        builder: (context, state) => const CreateFamilyScreen(),
      ),
      GoRoute(
        path: '/family/invite',
        name: 'family-invite',
        builder: (context, state) => const InviteSpouseScreen(),
      ),
      GoRoute(
        path: '/family/members',
        name: 'family-members',
        builder: (context, state) => const FamilyMembersScreen(),
      ),
      GoRoute(
        path: '/family/accept-invite',
        name: 'family-accept-invite',
        builder: (context, state) {
          final token = state.uri.queryParameters['token'];
          return AcceptInvitationScreen(initialToken: token);
        },
      ),
      GoRoute(
        path: '/invite/:token',
        name: 'invite-deep-link',
        builder: (context, state) {
          final token = state.pathParameters['token'];
          return AcceptInvitationScreen(initialToken: token);
        },
      ),
      GoRoute(
        path: '/expenses/add',
        name: 'expense-add',
        builder: (context, state) => const ExpenseFormScreen(),
      ),
      GoRoute(
        path: '/expenses/:id',
        name: 'expense-detail',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final extra = state.extra as Expense?;
          return ExpenseDetailScreen(expenseId: id, initialExpense: extra);
        },
      ),
      GoRoute(
        path: '/income',
        name: 'income-list',
        builder: (context, state) => const IncomeListScreen(),
      ),
      GoRoute(
        path: '/income/add',
        name: 'income-add',
        builder: (context, state) => const IncomeFormScreen(),
      ),
      GoRoute(
        path: '/income/:id',
        name: 'income-detail',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final extra = state.extra as Income?;
          return IncomeDetailScreen(incomeId: id, initialIncome: extra);
        },
      ),

      // 3. Stateful Bottom Navigation Shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ShellScaffold(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Home / Dashboard
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: HomeScreen(),
                ),
              ),
            ],
          ),

          // Branch 1: Transactions
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/transactions',
                name: 'transactions',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: TransactionsScreen(),
                ),
              ),
            ],
          ),

          // Branch 2: Budgets
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/budgets',
                name: 'budgets',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: BudgetsScreen(),
                ),
              ),
            ],
          ),

          // Branch 3: Reports
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reports',
                name: 'reports',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ReportsScreen(),
                ),
              ),
            ],
          ),

          // Branch 4: Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ProfileScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
