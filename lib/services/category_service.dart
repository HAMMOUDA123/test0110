import 'package:supabase_flutter/supabase_flutter.dart';

class CategoryService {
  final SupabaseClient supabase = Supabase.instance.client;

  // Fetch all categories
  Future<List<Map<String, dynamic>>> fetchCategories() async {
    try {
      print('Fetching categories from Supabase...');
      final response = await supabase.from('categories').select('*');
      print('Supabase response: $response');
      return response;
    } catch (e) {
      print('Error fetching categories: $e');
      rethrow;
    }
  }

  // Add new category
  Future<void> addCategory(String name, String description) async {
    try {
      print('Adding new category: $name');
      await supabase
          .from('categories')
          .insert({'name': name, 'description': description});
      print('Category added successfully');
    } catch (e) {
      print('Error adding category: $e');
      rethrow;
    }
  }

  // Update category
  Future<void> updateCategory(int id, String name, String description) async {
    try {
      print('Updating category with id: $id');
      await supabase.from('categories').update({
        'name': name,
        'description': description,
      }).eq('id', id);
      print('Category updated successfully');
    } catch (e) {
      print('Error updating category: $e');
      rethrow;
    }
  }

  // Delete category
  Future<void> deleteCategory(int id) async {
    try {
      print('Deleting category with id: $id');
      await supabase.from('categories').delete().eq('id', id);
      print('Category deleted successfully');
    } catch (e) {
      print('Error deleting category: $e');
      rethrow;
    }
  }
}
