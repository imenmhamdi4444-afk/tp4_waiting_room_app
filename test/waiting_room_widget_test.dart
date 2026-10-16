import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:waiting_room_app/main.dart';
import 'package:waiting_room_app/models/client.dart';
import 'package:waiting_room_app/queue_provider.dart';
import 'helpers/fake_queue_repository.dart';

Future<void> pumpWaitingRoom(
  WidgetTester tester,
  FakeQueueRepository repository,
) async {
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => QueueProvider(repository),
      child: const WaitingRoomApp(),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('shows the initial queue and adds a client', (tester) async {
    final repository = FakeQueueRepository();
    addTearDown(repository.dispose);
    await pumpWaitingRoom(tester, repository);

    expect(find.text('No one in queue yet...'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Alice');
    await tester.tap(find.text('Add'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Clients in Queue: 1'), findsOneWidget);
  });

  testWidgets('deletes a client using its id', (tester) async {
    final repository = FakeQueueRepository(
      initialClients: [
        Client(
          id: 'client-1',
          name: 'Bob',
          createdAt: DateTime.utc(2026, 10, 15),
        ),
      ],
    );
    addTearDown(repository.dispose);
    await pumpWaitingRoom(tester, repository);

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pump();
    await tester.pump();

    expect(find.text('Bob'), findsNothing);
    expect(find.text('Clients in Queue: 0'), findsOneWidget);
  });

  testWidgets('Next Client removes the first client in the queue', (
    tester,
  ) async {
    final repository = FakeQueueRepository(
      initialClients: [
        Client(
          id: 'client-1',
          name: 'Client A',
          createdAt: DateTime.utc(2026, 10, 15),
        ),
        Client(
          id: 'client-2',
          name: 'Client B',
          createdAt: DateTime.utc(2026, 10, 15, 1),
        ),
      ],
    );
    addTearDown(repository.dispose);
    await pumpWaitingRoom(tester, repository);

    await tester.tap(find.byKey(const Key('nextClientButton')));
    await tester.pump();
    await tester.pump();

    expect(find.text('Client A'), findsNothing);
    expect(find.text('Client B'), findsOneWidget);
    expect(find.text('Clients in Queue: 1'), findsOneWidget);
  });

  testWidgets('preserves entered text when realtime data changes', (
    tester,
  ) async {
    final repository = FakeQueueRepository();
    addTearDown(repository.dispose);
    await pumpWaitingRoom(tester, repository);

    await tester.enterText(find.byType(TextField), 'Waiting client');
    await repository.addClient('Existing client');
    await tester.pump();

    expect(find.text('Waiting client'), findsOneWidget);
    expect(find.text('Existing client'), findsOneWidget);
  });
}
