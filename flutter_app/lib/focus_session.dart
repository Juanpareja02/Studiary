/// A wall-clock session. Pauses do not count, and Android background suspension
/// cannot slow the timer down. Serialize on every transition, never every tick.
class FocusSession {
  FocusSession({
    required this.id,
    required this.subjectId,
    required this.startedAt,
    required this.totalSeconds,
    required this.remainingAtPause,
    this.deadline,
  });

  factory FocusSession.start(String subjectId, int minutes, DateTime now) =>
      FocusSession(
        id: '${now.microsecondsSinceEpoch}-$subjectId',
        subjectId: subjectId,
        startedAt: now,
        totalSeconds: minutes * 60,
        remainingAtPause: minutes * 60,
        deadline: now.add(Duration(minutes: minutes)),
      );

  final String id;
  final String subjectId;
  final DateTime startedAt;
  final int totalSeconds;
  int remainingAtPause;
  DateTime? deadline;
  bool get running => deadline != null;
  int remaining(DateTime now) => deadline == null
      ? remainingAtPause
      : ((deadline!.difference(now).inMilliseconds / 1000).ceil()).clamp(
          0,
          totalSeconds,
        );
  int studiedMinutes(DateTime now) => (totalSeconds - remaining(now)) ~/ 60;
  void pause(DateTime now) {
    remainingAtPause = remaining(now);
    deadline = null;
  }

  void resume(DateTime now) {
    deadline ??= now.add(Duration(seconds: remainingAtPause));
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'subjectId': subjectId,
    'startedAt': startedAt.toUtc().toIso8601String(),
    'totalSeconds': totalSeconds,
    'remainingAtPause': remainingAtPause,
    'deadline': deadline?.toUtc().toIso8601String(),
  };
  factory FocusSession.fromMap(Map<String, dynamic> map) {
    final total = map['totalSeconds'] as int;
    final remaining = map['remainingAtPause'] as int;
    if (total <= 0 || total > 7200 || remaining < 0 || remaining > total) {
      throw const FormatException('Invalid focus session');
    }
    return FocusSession(
      id: map['id'] as String,
      subjectId: map['subjectId'] as String,
      startedAt: DateTime.parse(map['startedAt'] as String).toLocal(),
      totalSeconds: total,
      remainingAtPause: remaining,
      deadline: DateTime.tryParse(map['deadline']?.toString() ?? ''),
    );
  }
}
