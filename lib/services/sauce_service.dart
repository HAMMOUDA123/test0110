import 'package:supabase_flutter/supabase_flutter.dart';

class SauceService {
  final _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchSauces() async {
    final response = await _client.from('sauces').select().order('name');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> addSauce(String name) async {
    await _client.from('sauces').insert({'name': name});
  }

  Future<void> updateSauce(int id, String name) async {
    await _client.from('sauces').update({'name': name}).eq('id', id);
  }

  Future<void> deleteSauce(int id) async {
    await _client.from('sauces').delete().eq('id', id);
  }
}
