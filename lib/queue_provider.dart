import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:waiting_room_app/data/queue_repository.dart';
import 'package:waiting_room_app/models/client.dart';

class QueueProvider extends ChangeNotifier {
  QueueProvider(this._repository) {
    _subscription = _repository.watchClients().listen(
      (clients) {
        _clients
          ..clear()
          ..addAll(clients);
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (Object error) {
        _isLoading = false;
        _errorMessage = 'Could not load the waiting list: $error';
        notifyListeners();
      },
    );
  }

  final QueueRepository _repository;
  final List<Client> _clients = [];
  late final StreamSubscription<List<Client>> _subscription;

  bool _isLoading = true;
  String? _errorMessage;

  List<Client> get clients => List.unmodifiable(_clients);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> addClient(String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return false;
    }

    _clearError();
    try {
      await _repository.addClient(trimmedName);
      return true;
    } on QueueRepositoryException catch (error) {
      _setError('Could not add client: ${error.message}');
      return false;
    }
  }

  Future<void> removeClient(String id) async {
    _clearError();
    try {
      await _repository.removeClient(id);
    } on QueueRepositoryException catch (error) {
      _setError('Could not remove client: ${error.message}');
    }
  }

  Future<void> nextClient() async {
    if (_clients.isEmpty) {
      return;
    }

    await removeClient(_clients.first.id);
  }

  void _clearError() {
    if (_errorMessage == null) {
      return;
    }
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
