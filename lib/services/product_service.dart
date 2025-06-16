import 'package:supabase_flutter/supabase_flutter.dart';

class ProductService {
  Future<List<Map<String, dynamic>>> fetchProducts() async {
    try {
      final response = await Supabase.instance.client.from('products').select();
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error fetching products: $e');
    }
  }

  Future<int> addProduct({
    required String name,
    required double price,
    required String category,
    required String description,
    String? imageUrl,
  }) async {
    try {
      final response = await Supabase.instance.client.from('products').insert({
        'name': name,
        'price': price,
        'category': category,
        'description': description,
        'image_url': imageUrl,
      }).select();
      // Return the inserted product's id
      return response[0]['id'] as int;
    } catch (e) {
      throw Exception('Error adding product: $e');
    }
  }

  Future<void> updateProduct({
    required int id,
    required String name,
    required double price,
    required String category,
    required String description,
    String? imageUrl,
  }) async {
    try {
      await Supabase.instance.client.from('products').update({
        'name': name,
        'price': price,
        'category': category,
        'description': description,
        'image_url': imageUrl,
      }).eq('id', id);
    } catch (e) {
      throw Exception('Error updating product: $e');
    }
  }

  Future<void> setPizzaSauces(int pizzaId, List<int> sauceIds) async {
    final client = Supabase.instance.client;
    // Remove existing sauces for this pizza
    await client.from('pizza_sauces').delete().eq('pizza_id', pizzaId);
    // Insert new sauces
    if (sauceIds.isNotEmpty) {
      final inserts = sauceIds
          .map((sid) => {'pizza_id': pizzaId, 'sauce_id': sid})
          .toList();
      await client.from('pizza_sauces').insert(inserts);
    }
  }

  Future<List<int>> fetchPizzaSauceIds(int pizzaId) async {
    final response = await Supabase.instance.client
        .from('pizza_sauces')
        .select('sauce_id')
        .eq('pizza_id', pizzaId);
    return List<int>.from(response.map((row) => row['sauce_id']));
  }

  Future<void> deleteProduct(int id) async {
    try {
      await Supabase.instance.client.from('products').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error deleting product: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchProductsByIds(List<int> ids) async {
    if (ids.isEmpty) return [];
    try {
      final response = await Supabase.instance.client
          .from('products')
          .select()
          .filter('id', 'in', '(${ids.join(',')})');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error fetching products by IDs: $e');
    }
  }
}
