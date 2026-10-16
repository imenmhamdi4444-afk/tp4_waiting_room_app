import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:waiting_room_app/models/client.dart';

abstract interface class QueueRepository {
  Stream<List<Client>> watchClients();

  Future<void> addClient(String name);

  Future<void> removeClient(String id);
}

class SupabaseQueueRepository implements QueueRepository {
  SupabaseQueueRepository(this._supabase);

  final SupabaseClient _supabase;

  @override
  Stream<List<Client>> watchClients() {
    return _supabase
        .from('clients')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map(
          (rows) => rows
              .map((row) => Client.fromMap(row))
              .toList(growable: false),
        );
  }

  @override
  Future<void> addClient(String name) async {
    try {
      await _supabase.from('clients').insert({'name': name});
    } on PostgrestException catch (error) {
      throw QueueRepositoryException(error.message);
    }
  }

  @override
  Future<void> removeClient(String id) async {
    try {
      await _supabase.from('clients').delete().eq('id', id);
    } on PostgrestException catch (error) {
      throw QueueRepositoryException(error.message);
    }
  }
}

class QueueRepositoryException implements Exception {
  const QueueRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
