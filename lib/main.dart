import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:waiting_room_app/data/queue_repository.dart';
import 'package:waiting_room_app/queue_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env', isOptional: true);

  final supabaseUrl = dotenv.env['SUPABASE_URL']?.trim();
  final supabasePublishableKey =
      (dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ??
              dotenv.env['SUPABASE_ANON_KEY'])
          ?.trim();

  if (supabaseUrl == null ||
      supabaseUrl.isEmpty ||
      supabaseUrl.contains('your-project-id') ||
      supabasePublishableKey == null ||
      supabasePublishableKey.isEmpty ||
      supabasePublishableKey == 'your-anon-key' ||
      supabasePublishableKey == 'your-publishable-key') {
    runApp(
      const _StartupErrorApp(
        message:
            'Supabase is not configured. Copy .env.example to .env and add '
            'your project URL and anon/publishable key.',
      ),
    );
    return;
  }

  final projectUri = Uri.tryParse(supabaseUrl);
  if (projectUri == null ||
      projectUri.scheme != 'https' ||
      !projectUri.host.endsWith('.supabase.co')) {
    runApp(
      const _StartupErrorApp(
        message: 'SUPABASE_URL must be a valid Supabase HTTPS project URL.',
      ),
    );
    return;
  }

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );
  final supabaseClient = Supabase.instance.client;
  if (supabaseClient.auth.currentSession == null) {
    try {
      await supabaseClient.auth.signInAnonymously();
    } on AuthException catch (error) {
      runApp(
        _StartupErrorApp(message: 'Anonymous sign-in failed: ${error.message}'),
      );
      return;
    }
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => QueueProvider(SupabaseQueueRepository(supabaseClient)),
      child: const WaitingRoomApp(),
    ),
  );
}

class WaitingRoomApp extends StatelessWidget {
  const WaitingRoomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(title: 'Waiting Room', home: WaitingRoomScreen());
  }
}

class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Waiting Room setup')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(message, textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}

class WaitingRoomScreen extends StatelessWidget {
  const WaitingRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final queueProvider = context.watch<QueueProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Waiting Room')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const _AddClientForm(),
            const SizedBox(height: 16),
            if (queueProvider.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  queueProvider.errorMessage!,
                  key: const Key('queueError'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            Text('Clients in Queue: ${queueProvider.clients.length}'),
            if (queueProvider.isLoading)
              const LinearProgressIndicator()
            else
              const SizedBox(height: 4),
            Expanded(
              child: queueProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : queueProvider.clients.isEmpty
                  ? const Center(child: Text('No one in queue yet...'))
                  : ListView.builder(
                      itemCount: queueProvider.clients.length,
                      itemBuilder: (context, index) {
                        final client = queueProvider.clients[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text(client.name),
                            subtitle: Text(
                              client.createdAt
                                  .toLocal()
                                  .toString()
                                  .split(' ')
                                  .first,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                context.read<QueueProvider>().removeClient(
                                  client.id,
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                key: const Key('nextClientButton'),
                onPressed: queueProvider.clients.isEmpty
                    ? null
                    : () => context.read<QueueProvider>().nextClient(),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Next Client'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddClientForm extends StatefulWidget {
  const _AddClientForm();

  @override
  State<_AddClientForm> createState() => _AddClientFormState();
}

class _AddClientFormState extends State<_AddClientForm> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _addClient() async {
    final added = await context.read<QueueProvider>().addClient(
      _controller.text,
    );
    if (added && mounted) {
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: const InputDecoration(labelText: 'Client Name'),
            onSubmitted: (_) => _addClient(),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(onPressed: _addClient, child: const Text('Add')),
      ],
    );
  }
}
