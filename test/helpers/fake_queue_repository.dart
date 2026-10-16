import 'dart:async';

import 'package:waiting_room_app/data/queue_repository.dart';
import 'package:waiting_room_app/models/client.dart';

class FakeQueueRepository implements QueueRepository {
  FakeQueueRepository({Iterable<Client> initialClients = const []})
    : _clients = List.of(initialClients);

  final List<Client> _clients;
  final StreamController<List<Client>> _updates =
      StreamController<List<Client>>.broadcast(sync: true);
  int _nextId = 0;
  String? addError;

  @override
  Stream<List<Client>> watchClients() async* {
    yield List.unmodifiable(_clients);
    yield* _updates.stream;
  }

  @override
  Future<void> addClient(String name) async {
    if (addError case final message?) {
      throw QueueRepositoryException(message);
    }

    _clients.add(
      Client(
        id: 'client-${_nextId++}',
        name: name,
        createdAt: DateTime.utc(2026),
      ),
    );
    _emit();
  }

  @override
  Future<void> removeClient(String id) async {
    _clients.removeWhere((client) => client.id == id);
    _emit();
  }

  Future<void> dispose() => _updates.close();

  void _emit() {
    _updates.add(List.unmodifiable(_clients));
  }
}
