import 'dart:convert';

enum CallType { audio, video }

enum CallStatus {
  calling,
  ringing,
  connected,
  inCall,
  ended,
  rejected,
  missed,
  busy,
  failed,
  disconnected,
}

enum CallDirection { incoming, outgoing }

class CallModel {
  final String id;
  final String callerId;
  final String callerName;
  final String? callerAvatarUrl;
  final String calleeId;
  final String calleeName;
  final String? calleeAvatarUrl;
  final CallType type;
  final CallStatus status;
  final CallDirection direction;
  final DateTime startedAt;
  final DateTime? connectedAt;
  final DateTime? endedAt;
  final int? durationSeconds;

  const CallModel({
    required this.id,
    required this.callerId,
    required this.callerName,
    this.callerAvatarUrl,
    required this.calleeId,
    required this.calleeName,
    this.calleeAvatarUrl,
    required this.type,
    required this.status,
    required this.direction,
    required this.startedAt,
    this.connectedAt,
    this.endedAt,
    this.durationSeconds,
  });

  bool get isMissed => status == CallStatus.missed;
  bool get isIncoming => direction == CallDirection.incoming;
  bool get isVideo => type == CallType.video;

  String get typeLabel => type == CallType.video ? 'Video Call' : 'Audio Call';

  String get statusLabel {
    switch (status) {
      case CallStatus.calling:
        return 'Calling...';
      case CallStatus.ringing:
        return 'Ringing...';
      case CallStatus.connected:
        return 'Connected';
      case CallStatus.inCall:
        return 'In Call';
      case CallStatus.ended:
        return 'Ended';
      case CallStatus.rejected:
        return 'Declined';
      case CallStatus.missed:
        return 'Missed';
      case CallStatus.busy:
        return 'Busy';
      case CallStatus.failed:
        return 'Failed';
      case CallStatus.disconnected:
        return 'Disconnected';
    }
  }

  String get formattedDuration {
    if (durationSeconds == null || durationSeconds == 0) return '';
    final minutes = durationSeconds! ~/ 60;
    final seconds = durationSeconds! % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  CallModel copyWith({
    String? id,
    String? callerId,
    String? callerName,
    String? callerAvatarUrl,
    String? calleeId,
    String? calleeName,
    String? calleeAvatarUrl,
    CallType? type,
    CallStatus? status,
    CallDirection? direction,
    DateTime? startedAt,
    DateTime? connectedAt,
    DateTime? endedAt,
    int? durationSeconds,
  }) {
    return CallModel(
      id: id ?? this.id,
      callerId: callerId ?? this.callerId,
      callerName: callerName ?? this.callerName,
      callerAvatarUrl: callerAvatarUrl ?? this.callerAvatarUrl,
      calleeId: calleeId ?? this.calleeId,
      calleeName: calleeName ?? this.calleeName,
      calleeAvatarUrl: calleeAvatarUrl ?? this.calleeAvatarUrl,
      type: type ?? this.type,
      status: status ?? this.status,
      direction: direction ?? this.direction,
      startedAt: startedAt ?? this.startedAt,
      connectedAt: connectedAt ?? this.connectedAt,
      endedAt: endedAt ?? this.endedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'callerId': callerId,
      'callerName': callerName,
      'callerAvatarUrl': callerAvatarUrl,
      'calleeId': calleeId,
      'calleeName': calleeName,
      'calleeAvatarUrl': calleeAvatarUrl,
      'type': type.name,
      'status': status.name,
      'direction': direction.name,
      'startedAt': startedAt.toIso8601String(),
      'connectedAt': connectedAt?.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'durationSeconds': durationSeconds,
    };
  }

  factory CallModel.fromJson(Map<String, dynamic> json) {
    return CallModel(
      id: json['id'] as String,
      callerId: json['callerId'] as String,
      callerName: json['callerName'] as String,
      callerAvatarUrl: json['callerAvatarUrl'] as String?,
      calleeId: json['calleeId'] as String,
      calleeName: json['calleeName'] as String,
      calleeAvatarUrl: json['calleeAvatarUrl'] as String?,
      type: CallType.values.firstWhere((e) => e.name == json['type']),
      status: CallStatus.values.firstWhere((e) => e.name == json['status']),
      direction: CallDirection.values
          .firstWhere((e) => e.name == json['direction']),
      startedAt: DateTime.parse(json['startedAt'] as String),
      connectedAt: json['connectedAt'] != null
          ? DateTime.parse(json['connectedAt'] as String)
          : null,
      endedAt: json['endedAt'] != null
          ? DateTime.parse(json['endedAt'] as String)
          : null,
      durationSeconds: json['durationSeconds'] as int?,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory CallModel.fromJsonString(String s) =>
      CallModel.fromJson(jsonDecode(s) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is CallModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
