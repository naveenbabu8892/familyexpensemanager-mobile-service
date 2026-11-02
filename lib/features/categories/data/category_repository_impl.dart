import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/category.dart';

/// Abstract contract for Category repository.
abstract class CategoryRepository {
  Future<List<Category>> getCategories({String? type});
  Future<Category> createCategory({
    required String name,
    required String type,
    String icon = 'category',
    String color = '#607D8B',
  });
  Future<Category> updateCategory(
    String id, {
    String? name,
    String? icon,
    String? color,
  });
  Future<void> deleteCategory(String id);
}

/// Concrete implementation of [CategoryRepository] consuming FastAPI endpoints.
class CategoryRepositoryImpl implements CategoryRepository {
  final ApiClient _apiClient;

  CategoryRepositoryImpl(this._apiClient);

  @override
  Future<List<Category>> getCategories({String? type}) async {
    final response = await _apiClient.get(
      ApiEndpoints.categories,
      queryParameters: type != null ? {'type': type} : null,
    );
    final list = response.data as List;
    return list
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Category> createCategory({
    required String name,
    required String type,
    String icon = 'category',
    String color = '#607D8B',
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.categories,
      data: {
        'name': name.trim(),
        'type': type.toUpperCase(),
        'icon': icon,
        'color': color,
      },
    );
    return Category.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<Category> updateCategory(
    String id, {
    String? name,
    String? icon,
    String? color,
  }) async {
    final payload = <String, dynamic>{};
    if (name != null) payload['name'] = name.trim();
    if (icon != null) payload['icon'] = icon.trim();
    if (color != null) payload['color'] = color.trim();

    final response = await _apiClient.put(
      ApiEndpoints.categoryDetail(id),
      data: payload,
    );
    return Category.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteCategory(String id) async {
    await _apiClient.delete(ApiEndpoints.categoryDetail(id));
  }
}

/// Riverpod provider for [CategoryRepository].
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepositoryImpl(ref.watch(apiClientProvider));
});

/// Categories list provider filtered by type.
final categoriesListProvider =
    FutureProvider.family<List<Category>, String?>((ref, type) async {
  return ref.watch(categoryRepositoryProvider).getCategories(type: type);
});
