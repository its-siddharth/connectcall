import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/call_model.dart';
import '../models/user_model.dart';
import '../core/utils/storage_service.dart';

enum CallServiceState { idle, outgoing, incoming, connected, ended }

/// Manages call metadata, history, and local state.
///
/// Real-time WebRTC transport is handled by ZegoCloud (ZegoUIKitPrebuiltCall).
/// Signalling between two devices (incoming-call notification) is handled
/// by ZegoUIKitSignalingPlugin, which is initialised in ZegoService.
class CallingService extends ChangeNotifier {
  CallingService._();
  static final CallingService instance = CallingService._();

  static const _uuid = Uuid();

  StorageService? _storage;

  void init(StorageService storage) {
    _storage = storage;
  }

  StorageService get _store {
    assert(_storage != null, 'CallingService not initialized');
    return _storage!;
  }

  // ── Current call state ────────────────────────────────────────────────────

  CallModel? _currentCall;
  CallServiceState _state = CallServiceState.idle;
  CallModel? _incomingCall;

  CallModel? get currentCall => _currentCall;
  CallServiceState get state => _state;
  CallModel? get incomingCall => _incomingCall;
  bool get hasIncomingCall => _incomingCall != null;
  bool get isInCall =>
      _state == CallServiceState.connected ||
      _state == CallServiceState.outgoing ||
      _state == CallServiceState.incoming;

  // Timers
  Timer? _callTimer;
  int _callDurationSeconds = 0;
  int get callDurationSeconds => _callDurationSeconds;

  // ── Initiating calls ──────────────────────────────────────────────────────

  /// Start an outgoing call and return the created CallModel.
  /// The actual Zego connection is established by the call screen widget.
  CallModel initiateCall({
    required UserModel caller,
    required UserModel callee,
    required CallType type,
  }) {
    final call = CallModel(
      id: _uuid.v4(),
      callerId: caller.id,
      callerName: caller.name,
      callerAvatarUrl: caller.avatarUrl,
      calleeId: callee.id,
      calleeName: callee.name,
      calleeAvatarUrl: callee.avatarUrl,
      type: type,
      status: CallStatus.calling,
      direction: CallDirection.outgoing,
      startedAt: DateTime.now(),
    );

    _currentCall = call;
    _state = CallServiceState.outgoing;
    _callDurationSeconds = 0;
    notifyListeners();
    return call;
  }

  /// Register an incoming call (triggered by Zego invitation event).
  void onIncomingCall({
    required String callId,
    required String callerId,
    required String callerName,
    required String calleeId,
    required String calleeName,
    required CallType type,
  }) {
    _incomingCall = CallModel(
      id: callId,
      callerId: callerId,
      callerName: callerName,
      calleeId: calleeId,
      calleeName: calleeName,
      type: type,
      status: CallStatus.ringing,
      direction: CallDirection.incoming,
      startedAt: DateTime.now(),
    );
    _state = CallServiceState.incoming;
    notifyListeners();
  }

  // ── Call lifecycle events ─────────────────────────────────────────────────

  void onCallConnected() {
    final base = _currentCall ?? _incomingCall;
    _currentCall = base?.copyWith(
      status: CallStatus.connected,
      connectedAt: DateTime.now(),
    );
    _incomingCall = null;
    _state = CallServiceState.connected;
    _startTimer();
    notifyListeners();
  }

  void onCallAccepted() {
    _currentCall = _incomingCall;
    _incomingCall = null;
    onCallConnected();
  }

  void onCallRejected() {
    final call = (_currentCall ?? _incomingCall)?.copyWith(
      status: CallStatus.rejected,
      endedAt: DateTime.now(),
    );
    if (call != null) _saveCallToHistory(call);
    _reset();
  }

  void onCallMissed() {
    final call = (_currentCall ?? _incomingCall)?.copyWith(
      status: CallStatus.missed,
      endedAt: DateTime.now(),
    );
    if (call != null) _saveCallToHistory(call);
    _reset();
  }

  void onCallEnded() {
    _stopTimer();
    final call = _currentCall?.copyWith(
      status: CallStatus.ended,
      endedAt: DateTime.now(),
      durationSeconds: _callDurationSeconds,
    );
    if (call != null) _saveCallToHistory(call);
    _reset();
  }

  void onCallFailed() {
    final call = _currentCall?.copyWith(
      status: CallStatus.failed,
      endedAt: DateTime.now(),
    );
    if (call != null) _saveCallToHistory(call);
    _reset();
  }

  // ── History ───────────────────────────────────────────────────────────────

  List<CallModel> getCallHistory() => _store.getCallHistory();

  Future<void> clearCallHistory() async {
    await _store.saveCallHistory([]);
    notifyListeners();
  }

  Future<void> _saveCallToHistory(CallModel call) async {
    await _store.addCallToHistory(call);
    notifyListeners();
  }

  // ── Internal helpers ──────────────────────────────────────────────────────

  void _startTimer() {
    _callTimer?.cancel();
    _callDurationSeconds = 0;
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _callDurationSeconds++;
      notifyListeners();
    });
  }

  void _stopTimer() {
    _callTimer?.cancel();
    _callTimer = null;
  }

  void _reset() {
    _stopTimer();
    _currentCall = null;
    _incomingCall = null;
    _state = CallServiceState.idle;
    _callDurationSeconds = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}
