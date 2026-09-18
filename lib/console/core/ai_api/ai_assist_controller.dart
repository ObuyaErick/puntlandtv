import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/error/failure.dart';
import 'puntland_ai_api.dart';

/// Where an assistance request is up to.
enum AiRequestState { idle, running, ready, failed }

/// Drives one assistance request at a time, for one screen.
///
/// A plain `ChangeNotifier` with the API injected, like `ArticleEditor` — no
/// Riverpod, so the whole thing is testable with a fake and a `Duration.zero`
/// fixture, and so the pending state can be driven deterministically rather
/// than raced against a provider rebuild.
///
/// Two properties it exists to guarantee:
///
/// **One request at a time.** A second press while one is in flight is ignored
/// rather than queued. Two overlapping translations of the same article would
/// finish in an order nobody chose, and the second answer would silently
/// replace a panel the editor was already reading.
///
/// **A late answer cannot land.** The screen that started a request may be gone
/// by the time it returns — the editor closed, the locale switched, the panel
/// dismissed — so every completion checks [_generation] before touching state.
/// Without that, an abandoned request reopens a review panel over whatever the
/// editor is doing three minutes later.
class AiAssistController<T> extends ChangeNotifier {
  AiAssistController({required this.ai});

  final PuntlandAiApi ai;

  AiRequestState _state = AiRequestState.idle;
  T? _result;
  Failure? _error;

  /// Bumped by every start and every cancel. A completion whose generation is
  /// stale is dropped on the floor — see the class doc.
  int _generation = 0;

  AiRequestState get state => _state;
  bool get isRunning => _state == AiRequestState.running;
  T? get result => _result;
  Failure? get error => _error;

  /// Runs [request], unless one is already in flight.
  ///
  /// Answers the result, or null when the request failed, was superseded, or
  /// was refused because another was already running. Callers branch on null
  /// rather than catching: every failure here is already held in [error], and a
  /// second error path would be a second place to forget one.
  Future<T?> run(Future<T> Function() request) async {
    if (isRunning) return null;

    final generation = ++_generation;
    _state = AiRequestState.running;
    _error = null;
    _result = null;
    notifyListeners();

    try {
      final value = await request();
      if (generation != _generation) return null;

      _result = value;
      _state = AiRequestState.ready;
      notifyListeners();
      return value;
    } catch (error) {
      if (generation != _generation) return null;

      _error = error is Failure
          ? error
          : const Failure(kind: FailureKind.unknown, code: 'UNKNOWN');
      _state = AiRequestState.failed;
      notifyListeners();
      return null;
    }
  }

  /// Abandons whatever is in flight and returns to rest.
  ///
  /// The HTTP request itself may still be on the wire — this does not stop the
  /// backend, and the usage row is written either way, which is honest: the
  /// work was done and it was billed. What it stops is the answer arriving in a
  /// UI that has moved on.
  void cancel() {
    if (_state == AiRequestState.idle) return;
    _generation++;
    _state = AiRequestState.idle;
    _result = null;
    _error = null;
    notifyListeners();
  }

  /// Clears a finished request without disturbing one in flight.
  void reset() {
    if (isRunning) return;
    _state = AiRequestState.idle;
    _result = null;
    _error = null;
    notifyListeners();
  }
}
