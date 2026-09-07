enum EventType { practicas, estudio, examen, personal }

extension EventTypeCopy on EventType {
  String get label {
    switch (this) {
      case EventType.practicas:
        return 'Prácticas';
      case EventType.estudio:
        return 'Estudio';
      case EventType.examen:
        return 'Examen';
      case EventType.personal:
        return 'Personal';
    }
  }
}

EventType eventTypeFromString(Object? value) {
  final normalized = value?.toString().trim().toLowerCase();
  final legacyNames = <String, EventType>{
    'prácticas': EventType.practicas,
    'practicas': EventType.practicas,
    'estudio': EventType.estudio,
    'examen': EventType.examen,
    'personal': EventType.personal,
  };
  final legacyType = legacyNames[normalized];
  if (legacyType != null) return legacyType;
  return EventType.values.firstWhere(
    (type) => type.name == normalized,
    orElse: () => EventType.personal,
  );
}

enum NoteType { text, pdf, image, video, link, file }

NoteType noteTypeFromString(Object? value) {
  return NoteType.values.firstWhere(
    (type) => type.name == value?.toString().trim().toLowerCase(),
    orElse: () => NoteType.text,
  );
}

class Objective {
  Objective({
    required this.id,
    required this.description,
    this.completed = false,
  });

  final String id;
  final String description;
  bool completed;

  Map<String, dynamic> toMap() => {
    'id': id,
    'description': description,
    'completed': completed,
  };

  factory Objective.fromMap(Map<String, dynamic> map) => Objective(
    id:
        map['id']?.toString() ??
        DateTime.now().microsecondsSinceEpoch.toString(),
    description: map['description']?.toString() ?? '',
    completed: map['completed'] == true,
  );
}

class Subject {
  Subject({
    required this.id,
    required this.name,
    required this.color,
    this.classroom,
    List<Objective>? objectives,
  }) : objectives = objectives ?? [];

  final String id;
  String name;
  String color;
  String? classroom;
  final List<Objective> objectives;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'color': color,
    'classroom': classroom,
    'objectives': objectives.map((objective) => objective.toMap()).toList(),
  };

  factory Subject.fromMap(Map<String, dynamic> map) => Subject(
    id:
        map['id']?.toString() ??
        DateTime.now().microsecondsSinceEpoch.toString(),
    name: map['name']?.toString() ?? 'Asignatura',
    color: map['color']?.toString() ?? '#F58F8F',
    classroom: map['classroom']?.toString(),
    objectives: _objectives(map['objectives']),
  );
}

class PlannerEvent {
  PlannerEvent({
    required this.id,
    required this.title,
    required this.startDate,
    required this.type,
    this.endDate,
    this.description,
    this.isAllDay = false,
    this.grade,
    this.subjectId,
    this.weight,
    this.color,
  });

  final String id;
  String title;
  DateTime startDate;
  DateTime? endDate;
  EventType type;
  String? description;
  bool isAllDay;
  double? grade;
  String? subjectId;
  double? weight;
  String? color;

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'type': type.name,
    'description': description,
    'isAllDay': isAllDay,
    'grade': grade,
    'subjectId': subjectId,
    'weight': weight,
    'color': color,
  };

  factory PlannerEvent.fromMap(
    Map<String, dynamic> map, {
    DateTime Function(Object?)? parseDate,
  }) {
    final parser =
        parseDate ??
        (Object? value) =>
            DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
    return PlannerEvent(
      id:
          map['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      title: map['title']?.toString() ?? 'Evento',
      startDate: parser(map['startDate']),
      endDate: map['endDate'] == null ? null : parser(map['endDate']),
      type: eventTypeFromString(map['type']),
      description: map['description']?.toString(),
      isAllDay: map['isAllDay'] == true,
      grade: _doubleValue(map['grade']),
      subjectId: map['subjectId']?.toString(),
      weight: _doubleValue(map['weight']),
      color: map['color']?.toString(),
    );
  }
}

bool plannerEventOccursOn(PlannerEvent event, DateTime date) {
  final end = event.endDate ?? event.startDate;
  final startDay = DateTime(
    event.startDate.year,
    event.startDate.month,
    event.startDate.day,
  );
  final endDay = DateTime(end.year, end.month, end.day);
  final target = DateTime(date.year, date.month, date.day);
  return !target.isBefore(startDay) && !target.isAfter(endDay);
}

class PlannerNote {
  PlannerNote({
    required this.id,
    required this.title,
    required this.content,
    required this.subjectId,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.archived = false,
    this.type = NoteType.text,
    this.fileName,
    this.fileUrl,
    this.fileDataUri,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  final String id;
  String title;
  String content;
  String subjectId;
  DateTime createdAt;
  DateTime updatedAt;
  bool archived;
  NoteType type;
  String? fileName;
  String? fileUrl;
  String? fileDataUri;

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'content': content,
    'subjectId': subjectId,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'archived': archived,
    'type': type.name,
    'fileName': fileName,
    'fileUrl': fileUrl,
    'fileDataUri': fileDataUri,
  };

  factory PlannerNote.fromMap(
    Map<String, dynamic> map, {
    DateTime Function(Object?)? parseDate,
  }) {
    final parser =
        parseDate ??
        (Object? value) =>
            DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
    return PlannerNote(
      id:
          map['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      title: map['title']?.toString() ?? 'Nota',
      content: map['content']?.toString() ?? '',
      subjectId: map['subjectId']?.toString() ?? '',
      createdAt: parser(map['createdAt']),
      updatedAt: parser(map['updatedAt']),
      archived: map['archived'] == true,
      type: noteTypeFromString(map['type']),
      fileName: map['fileName']?.toString(),
      fileUrl: map['fileUrl']?.toString(),
      fileDataUri: map['fileDataUri']?.toString(),
    );
  }
}

class StudySession {
  StudySession({
    required this.id,
    required this.minutes,
    required this.startedAt,
    this.subjectId,
  });

  final String id;
  final int minutes;
  final DateTime startedAt;
  final String? subjectId;

  Map<String, dynamic> toMap() => {
    'id': id,
    'minutes': minutes,
    'startedAt': startedAt.toIso8601String(),
    'subjectId': subjectId,
  };

  factory StudySession.fromMap(
    Map<String, dynamic> map, {
    DateTime Function(Object?)? parseDate,
  }) {
    final parser =
        parseDate ??
        (Object? value) =>
            DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
    return StudySession(
      id:
          map['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      minutes: (int.tryParse(map['minutes']?.toString() ?? '') ?? 0).clamp(
        0,
        2147483647,
      ),
      startedAt: parser(map['startedAt']),
      subjectId: map['subjectId']?.toString(),
    );
  }
}

class ScheduleEntry {
  ScheduleEntry({
    required this.id,
    required this.profileId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.subjectId,
    this.note,
  });

  final String id;
  String profileId;
  int dayOfWeek;
  String startTime;
  String endTime;
  String subjectId;
  String? note;

  Map<String, dynamic> toMap() => {
    'id': id,
    'profileId': profileId,
    'dayOfWeek': dayOfWeek,
    'startTime': startTime,
    'endTime': endTime,
    'subjectId': subjectId,
    'note': note,
  };

  factory ScheduleEntry.fromMap(Map<String, dynamic> map) => ScheduleEntry(
    id:
        map['id']?.toString() ??
        DateTime.now().microsecondsSinceEpoch.toString(),
    profileId: map['profileId']?.toString() ?? 'default',
    dayOfWeek: int.tryParse(map['dayOfWeek']?.toString() ?? '') ?? 1,
    startTime: map['startTime']?.toString() ?? '08:00',
    endTime: map['endTime']?.toString() ?? '09:00',
    subjectId: map['subjectId']?.toString() ?? '',
    note: map['note']?.toString(),
  );
}

class ScheduleProfile {
  ScheduleProfile({required this.id, required this.name});

  final String id;
  String name;

  Map<String, dynamic> toMap() => {'id': id, 'name': name};

  factory ScheduleProfile.fromMap(Map<String, dynamic> map) => ScheduleProfile(
    id: map['id']?.toString() ?? 'default',
    name: map['name']?.toString() ?? 'Horario principal',
  );
}

double? _doubleValue(Object? value) {
  if (value == null) return null;
  return double.tryParse(value.toString());
}

List<Objective> _objectives(Object? value) {
  if (value is! List) return [];
  return value
      .whereType<Map>()
      .map((item) => Objective.fromMap(Map<String, dynamic>.from(item)))
      .toList();
}
