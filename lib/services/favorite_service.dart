import 'package:supabase_flutter/supabase_flutter.dart';

class FavoriteService {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<List<int>> fetchFavoriteProductIds(String userId) async {
    final response = await supabase
        .from('favorites')
        .select('product_id')
        .eq('user_id', userId);
    return List<int>.from(response.map((row) => row['product_id']));
  }

  Future<void> addFavorite(String userId, int productId) async {
    await supabase.from('favorites').insert({
      'user_id': userId,
      'product_id': productId,
    });
  }

  Future<void> removeFavorite(String userId, int productId) async {
    await supabase
        .from('favorites')
        .delete()
        .eq('user_id', userId)
        .eq('product_id', productId);
  }
}
