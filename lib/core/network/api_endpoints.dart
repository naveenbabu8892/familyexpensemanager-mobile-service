/// Exhaustive list of backend REST API routes exposed by FastAPI.
class ApiEndpoints {
  ApiEndpoints._();

  // Authentication
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';

  // Current User
  static const String usersMe = '/users/me';

  // Family Management
  static const String families = '/families';
  static const String familyCurrent = '/families/current';
  static const String familyInvite = '/families/invite';
  static const String familyInviteAccept = '/families/invite/accept';
  static const String familyMembers = '/families/members';
  static const String familyRelationships = '/family-relationships';

  // Categories
  static const String categories = '/categories';
  static String categoryDetail(String id) => '/categories/$id';

  // Expenses
  static const String expenses = '/expenses';
  static String expenseDetail(String id) => '/expenses/$id';

  // Income
  static const String income = '/income';
  static String incomeDetail(String id) => '/income/$id';

  // Budgets
  static const String budgets = '/budgets';
  static String budgetDetail(String id) => '/budgets/$id';

  // Dashboard & Reports
  static const String dashboard = '/dashboard';
  static const String reportMonthly = '/reports/monthly';
  static const String reportCategories = '/reports/categories';
  static const String reportMembers = '/reports/members';
  static const String reportPaymentMethods = '/reports/payment-methods';
}
