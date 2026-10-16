import 'package:flutter_test/flutter_test.dart';
import 'package:waiting_room_app/models/client.dart';
import 'package:waiting_room_app/queue_provider.dart';

import 'helpers/fake_queue_repository.dart';

void main() {
  test('Client.fromMap converts a database row to a typed model', () {
    final client = Client.fromMap({
      'id': 'client-1',
      'name': 'Alice',
      'created_at': '2026-10-15T10:30:00.000Z',
    });

    expect(client.id, 'client-1');
    expect(client.name, 'Alice');
    expect(client.createdAt, DateTime.utc(2026, 10, 15, 10, 30));
  });

  test('loads clients from the repository stream', () async {
    final existingClient = Client(
      id: 'client-1',
      name: 'Alice',
      createdAt: DateTime.utc(2026),
    );
    final repository = FakeQueueRepository(initialClients: [existingClient]);
    final provider = QueueProvider(repository);
    addTearDown(() async {
      provider.dispose();
      await repository.dispose();
    });

    await Future<void>.delayed(Duration.zero);

    expect(provider.isLoading, isFalse);
    expect(provider.clients, [existingClient]);
  });

  test('adds a trimmed client and receives it through the stream', () async {
    final repository = FakeQueueRepository();
    final provider = QueueProvider(repository);
    addTearDown(() async {
      provider.dispose();
      await repository.dispose();
    });
    await Future<void>.delayed(Duration.zero);

    final added = await provider.addClient('  Alice  ');
    await Future<void>.delayed(Duration.zero);

    expect(added, isTrue);
    expect(provider.clients.map((client) => client.name), ['Alice']);
  });

  test('does not send a blank name to the repository', () async {
    final repository = FakeQueueRepository();
    final provider = QueueProvider(repository);
    addTearDown(() async {
      provider.dispose();
      await repository.dispose();
    });

    final added = await provider.addClient('   ');

    expect(added, isFalse);
    expect(provider.clients, isEmpty);
  });

  test('nextClient removes the first client by its database id', () async {
    final first = Client(
      id: 'client-1',
      name: 'Alice',
      createdAt: DateTime.utc(2026),
    );
    final second = Client(
      id: 'client-2',
      name: 'Bob',
      createdAt: DateTime.utc(2026, 1, 2),
    );
    final repository = FakeQueueRepository(initialClients: [first, second]);
    final provider = QueueProvider(repository);
    addTearDown(() async {
      provider.dispose();
      await repository.dispose();
    });
    await Future<void>.delayed(Duration.zero);

    await provider.nextClient();
    await Future<void>.delayed(Duration.zero);

    expect(provider.clients, [second]);
  });

  test('exposes database errors instead of silently ignoring them', () async {
    final repository = FakeQueueRepository()..addError = 'Insert denied';
    final provider = QueueProvider(repository);
    addTearDown(() async {
      provider.dispose();
      await repository.dispose();
    });
    await Future<void>.delayed(Duration.zero);

    final added = await provider.addClient('Alice');

    expect(added, isFalse);
    expect(provider.errorMessage, contains('Insert denied'));
  });

  test(
    'does not notify listeners when nextClient is called on an empty queue',
    () async {
      final repository = FakeQueueRepository();
      final provider = QueueProvider(repository);
      var notifications = 0;
      provider.addListener(() => notifications++);
      addTearDown(() async {
        provider.dispose();
        await repository.dispose();
      });
      await Future<void>.delayed(Duration.zero);
      notifications = 0;

      await provider.nextClient();

      expect(provider.clients, isEmpty);
      expect(notifications, 0);
    },
  );
}
