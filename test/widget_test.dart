import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:waiting_room_app/main.dart';
import 'package:waiting_room_app/queue_provider.dart';

import 'helpers/fake_queue_repository.dart';

void main() {
  testWidgets('WaitingRoomApp shows the waiting room screen', (tester) async {
    final repository = FakeQueueRepository();
    addTearDown(repository.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => QueueProvider(repository),
        child: const WaitingRoomApp(),
      ),
    );
    await tester.pump();

    expect(find.text('Waiting Room'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Clients in Queue: 0'), findsOneWidget);
  });
}
