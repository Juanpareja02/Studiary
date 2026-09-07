import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'models.dart';
import 'notifications.dart';
import 'services.dart';
import 'theme.dart';
import 'sync_merge.dart';

Map<String, dynamic> normalizeLegacyRemoteData(
  Map<String, dynamic> remote,
  String uid,
) {
  final normalized = Map<String, dynamic>.from(remote);
  const fields = [
    'events',
    'subjects',
    'schedule',
    'profiles',
    'notes',
    'studySessions',
  ];
  for (final field in fields) {
    if (normalized.containsKey(field)) continue;
    final legacyKey = switch (field) {
      'events' => 'studiary-events-$uid-v3',
      'subjects' => 'studiary-subjects-$uid-v3',
      'schedule' => 'studiary-schedule-$uid-v3',
      'profiles' => 'studiary-profiles-$uid-v1',
      'notes' => 'studiary-notes-$uid-v1',
      _ => '',
    };
    final legacyValue = normalized[legacyKey];
    if (legacyValue is List) normalized[field] = legacyValue;
  }
  return normalized;
}

class AppState extends ChangeNotifier {
  AppState({bool initialize = true}) {
    if (initialize) _start();
  }

  supabase.User? user;
  bool loading = true;
  bool syncing = false;
  bool darkMode = false;
  String appearanceMode = 'system';
  String backgroundColor = defaultThemeBackground;
  String primaryColor = defaultThemePrimary;
  String textColor = defaultThemeText;
  String surfaceColor = defaultThemeSurface;
  bool tutorialCompleted = false;
  bool premium = false;
  int focusMinutes = 0;
  final List<String> focusDays = [];
  List<PlannerEvent> events = [];
  List<Subject> subjects = [];
  List<PlannerNote> notes = [];
  List<StudySession> studySessions = [];
  List<ScheduleEntry> schedule = [];
  List<ScheduleProfile> profiles = [
    ScheduleProfile(id: 'default', name: 'Horario principal'),
  ];
  PremiumService? _premiumService;
  PremiumService get premiumService => _premiumService ??= PremiumService(
    onPremiumChanged: (enabled) {
      premium = enabled;
      _notify();
    },
  );

  SharedPreferences? _prefs;
  StreamSubscription<supabase.User?>? _authSubscription;
  Future<void> _saveQueue = Future<void>.value();
  int _authGeneration = 0;
  Map<String, dynamic> _base = {};
  bool _dirty = false;
  int _mutation = 0;
  Timer? _syncDebounce;
  Timer? _retryTimer;
  Future<void>? _syncTask;
  String? _syncOwner;
  final Set<String> _pendingFileDeletes = {};
  bool get hasPendingChanges => _dirty;
  DateTime? lastSyncedAt;
  bool _disposed = false;
  String? syncError;

  ThemeMode get themeMode => switch (appearanceMode) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  Future<void> _start() async {
    _prefs = await SharedPreferences.getInstance();
    if (_disposed) return;
    _authSubscription = AuthService.changes.listen(_onUserChanged);
    _retryTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      if (user != null && !loading) unawaited(synchronize());
    });
  }

  Future<void> _onUserChanged(supabase.User? currentUser) async {
    if (_disposed) return;
    final generation = ++_authGeneration;
    user = currentUser;
    loading = true;
    premium = false;
    syncError = null;
    _notify();
    if (currentUser == null) {
      _clearData();
      loading = false;
      _notify();
      return;
    }

    final local = _readLocal(currentUser.id);
    _pendingFileDeletes
      ..clear()
      ..addAll(
        (local['_pendingFileDeletes'] as List? ?? []).whereType<String>(),
      );
    if (!_isCurrent(generation, currentUser.id)) return;
    _base = local['_syncBase'] is Map
        ? Map<String, dynamic>.from(local['_syncBase'] as Map)
        : {};
    _dirty = local['_syncDirty'] == true;
    _applyData(local);
    loading = false;
    _notify();
    await synchronize();
    if (!_isCurrent(generation, currentUser.id)) return;
    unawaited(NotificationService.syncEvents(events));
    unawaited(_restorePremium());
    _notify();
  }

  Future<void> _restorePremium() async {
    try {
      await premiumService.loadProducts();
      await premiumService.restore();
    } catch (error) {
      debugPrint('No se pudo restaurar Premium desde Google Play: $error');
    }
  }

  Map<String, dynamic> _readLocal(String uid) {
    final encoded = _prefs?.getString(_storageKey(uid));
    if (encoded == null) return {};
    try {
      final value = jsonDecode(encoded);
      return value is Map ? Map<String, dynamic>.from(value) : {};
    } catch (_) {
      return {};
    }
  }

  Map<String, dynamic> _dataMap() => {
    'events': events.map((event) => event.toMap()).toList(),
    'subjects': subjects.map((subject) => subject.toMap()).toList(),
    'notes': notes.map((note) => note.toMap()).toList(),
    'studySessions': studySessions.map((session) => session.toMap()).toList(),
    'schedule': schedule.map((entry) => entry.toMap()).toList(),
    'profiles': profiles.map((profile) => profile.toMap()).toList(),
    'focusMinutes': focusMinutes,
    'focusDays': List<String>.from(focusDays),
    'darkMode': darkMode,
    'appearanceMode': appearanceMode,
    'backgroundColor': backgroundColor,
    'primaryColor': primaryColor,
    'textColor': textColor,
    'surfaceColor': surfaceColor,
    'tutorialCompleted': tutorialCompleted,
  };

  void _applyData(Map<String, dynamic> data) {
    DateTime parseDate(Object? value) {
      if (value is DateTime) return value;
      return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
    }

    events = _list(
      data['events'],
    ).map((item) => PlannerEvent.fromMap(item, parseDate: parseDate)).toList();
    subjects = _list(data['subjects']).map(Subject.fromMap).toList();
    notes = _list(
      data['notes'],
    ).map((item) => PlannerNote.fromMap(item, parseDate: parseDate)).toList();
    studySessions = _list(
      data['studySessions'],
    ).map((item) => StudySession.fromMap(item, parseDate: parseDate)).toList();
    schedule = _list(data['schedule']).map(ScheduleEntry.fromMap).toList();
    final loadedProfiles = _list(
      data['profiles'],
    ).map(ScheduleProfile.fromMap).toList();
    profiles = loadedProfiles.isEmpty
        ? [ScheduleProfile(id: 'default', name: 'Horario principal')]
        : loadedProfiles;
    focusMinutes = (int.tryParse(data['focusMinutes']?.toString() ?? '') ?? 0)
        .clamp(0, 2147483647);
    final storedFocusDays = data['focusDays'];
    focusDays
      ..clear()
      ..addAll(
        storedFocusDays is List
            ? storedFocusDays.map((value) => value.toString())
            : const <String>[],
      );
    final storedAppearance = data['appearanceMode']?.toString();
    appearanceMode =
        const {'system', 'light', 'dark'}.contains(storedAppearance)
        ? storedAppearance!
        : data['darkMode'] == true
        ? 'dark'
        : 'system';
    darkMode = appearanceMode == 'dark';
    backgroundColor = _migrateDefaultColor(
      data['backgroundColor'],
      defaultThemeBackground,
      '#FFF8FB',
    );
    primaryColor = _migrateDefaultColor(
      data['primaryColor'],
      defaultThemePrimary,
      '#FF8FA3',
    );
    textColor = _migrateDefaultColor(
      data['textColor'],
      defaultThemeText,
      '#26334D',
    );
    surfaceColor = data['surfaceColor']?.toString() ?? defaultThemeSurface;
    tutorialCompleted = data['tutorialCompleted'] == true;
  }

  List<Map<String, dynamic>> _list(Object? value) {
    if (value is! List) return [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  void _clearData() {
    events = [];
    subjects = [];
    notes = [];
    studySessions = [];
    schedule = [];
    profiles = [ScheduleProfile(id: 'default', name: 'Horario principal')];
    focusMinutes = 0;
    focusDays.clear();
    tutorialCompleted = false;
    premium = false;
    _base = {};
    _dirty = false;
    _syncDebounce?.cancel();
    unawaited(NotificationService.syncEvents([]));
  }

  Future<void> _writeLocal(String uid, Map<String, dynamic> data) async {
    _prefs ??= await SharedPreferences.getInstance();
    if (!await _prefs!.setString(_storageKey(uid), jsonEncode(data))) {
      throw StateError('Local storage failed');
    }
  }

  Future<void> saveLocally() async {
    final uid = user?.id;
    if (uid == null) return;
    final snapshot = {
      ..._dataMap(),
      '_syncBase': _base,
      '_syncDirty': _dirty,
      '_pendingFileDeletes': _pendingFileDeletes.toList(),
    };
    _saveQueue = _saveQueue
        .catchError((Object _) {})
        .then((_) => _writeLocal(uid, snapshot));
    await _saveQueue;
  }

  Future<void> synchronize() async {
    final uid = user?.id;
    if (_syncTask != null) {
      await _syncTask;
      if (user?.id == uid && _syncOwner != uid) await synchronize();
      return;
    }
    _syncOwner = uid;
    _syncTask = _synchronize();
    try {
      await _syncTask;
    } finally {
      _syncTask = null;
      if (_dirty && syncError == null && !_disposed) {
        _syncDebounce?.cancel();
        _syncDebounce = Timer(
          const Duration(seconds: 1),
          () => unawaited(synchronize()),
        );
      }
    }
  }

  Future<void> _synchronize() async {
    final currentUser = user;
    final generation = _authGeneration;
    if (currentUser == null || _disposed) return;
    syncing = true;
    _notify();
    try {
      final remoteRow = await CloudSyncService.loadSnapshot(
        currentUser,
      ).timeout(const Duration(seconds: 15));
      if (!_isCurrent(generation, currentUser.id)) return;
      var remote = normalizeLegacyRemoteData(remoteRow.data, currentUser.id);
      var revision = remoteRow.revision;
      if (!_dirty) {
        _applyData(remote);
        _base = remote;
      } else {
        for (var attempt = 0; attempt < 4; attempt++) {
          final sentLocal = _dataMap();
          final mutation = _mutation;
          final merged = mergeStudyData(_base, sentLocal, remote);
          final result = await CloudSyncService.saveSnapshot(
            merged,
            revision,
          ).timeout(const Duration(seconds: 15));
          if (!_isCurrent(generation, currentUser.id)) return;
          if (!result.saved) {
            remote = result.data;
            revision = result.revision;
            if (attempt == 3) {
              throw StateError('Concurrent changes; retry later');
            }
            continue;
          }
          // Rebase edits made while this network request was in flight.
          final current = _dataMap();
          _base = result.data;
          _dirty = _mutation != mutation;
          _applyData(
            _dirty
                ? mergeStudyData(sentLocal, current, result.data)
                : result.data,
          );
          break;
        }
      }
      syncError = null;
      lastSyncedAt = DateTime.now();
      await saveLocally();
      if (!_dirty) {
        for (final path in _pendingFileDeletes.toList()) {
          if (!_isCurrent(generation, currentUser.id)) break;
          if (notes.any((note) => note.fileUrl == path)) continue;
          try {
            await CloudSyncService.deleteNoteFile(
              path,
              swallowErrors: false,
            ).timeout(const Duration(seconds: 10));
            if (_isCurrent(generation, currentUser.id)) {
              _pendingFileDeletes.remove(path);
            }
          } catch (_) {
            break;
          }
        }
        if (_isCurrent(generation, currentUser.id)) await saveLocally();
      }
    } catch (error) {
      if (_isCurrent(generation, currentUser.id)) {
        syncError =
            'Cambios guardados en este dispositivo. Reintentaremos la sincronización.';
      }
      debugPrint('Sincronización pendiente: ${error.runtimeType}');
    } finally {
      if (_isCurrent(generation, currentUser.id)) {
        syncing = false;
        _notify();
      }
    }
  }

  void _changed() {
    _mutation++;
    _dirty = true;
    _notify();
    unawaited(NotificationService.syncEvents(events));
    unawaited(
      saveLocally().catchError((Object _) {
        syncError =
            'No se pudo guardar en el dispositivo. Comprueba el espacio disponible.';
        _notify();
      }),
    );
    _syncDebounce?.cancel();
    _syncDebounce = Timer(
      const Duration(milliseconds: 700),
      () => unawaited(synchronize()),
    );
  }

  void addEvent(PlannerEvent event) {
    events = [...events, event];
    _changed();
  }

  void updateEvent(PlannerEvent event) {
    events = events.map((item) => item.id == event.id ? event : item).toList();
    _changed();
  }

  void deleteEvent(String id) {
    events = events.where((item) => item.id != id).toList();
    _changed();
  }

  void addSubject(Subject subject) {
    subjects = [...subjects, subject];
    _changed();
  }

  void updateSubject(Subject subject) {
    subjects = subjects
        .map((item) => item.id == subject.id ? subject : item)
        .toList();
    _changed();
  }

  void deleteSubject(String id) {
    subjects = subjects.where((item) => item.id != id).toList();
    final removedNotes = notes.where((note) => note.subjectId == id).toList();
    notes = notes.where((note) => note.subjectId != id).toList();
    // Keep historical study totals even if a subject is removed.
    for (final note in removedNotes) {
      final fileUrl = note.fileUrl;
      if (fileUrl != null) {
        _pendingFileDeletes.add(fileUrl);
      }
    }
    for (final event in events) {
      if (event.subjectId == id) event.subjectId = null;
    }
    schedule = schedule.where((entry) => entry.subjectId != id).toList();
    _changed();
  }

  void toggleObjective(String subjectId, String objectiveId) {
    for (final subject in subjects) {
      if (subject.id == subjectId) {
        final objective = subject.objectives
            .where((item) => item.id == objectiveId)
            .firstOrNull;
        if (objective != null) objective.completed = !objective.completed;
      }
    }
    _changed();
  }

  void addObjective(String subjectId, String description) {
    for (final subject in subjects) {
      if (subject.id == subjectId) {
        subject.objectives.add(Objective(id: _id(), description: description));
      }
    }
    _changed();
  }

  void addNote(PlannerNote note) {
    notes = [note, ...notes];
    _changed();
  }

  void updateNote(PlannerNote note) {
    note.updatedAt = DateTime.now();
    notes = notes.map((item) => item.id == note.id ? note : item).toList();
    _changed();
  }

  void deleteNote(String id) {
    final note = notes.where((item) => item.id == id).firstOrNull;
    notes = notes.where((note) => note.id != id).toList();
    if (note?.fileUrl != null) {
      _pendingFileDeletes.add(note!.fileUrl!);
    }
    _changed();
  }

  Future<void> deleteAccount() async {
    final currentUser = user;
    if (currentUser == null) return;
    await CloudSyncService.deleteAccount();
    await AuthService.signOut();
    await _saveQueue;
    await _prefs?.remove(_storageKey(currentUser.id));
    for (final key in _prefs?.getKeys() ?? <String>{}) {
      if (key.startsWith('studiary-draft-${currentUser.id}-') ||
          key == 'studiary-focus-${currentUser.id}') {
        await _prefs?.remove(key);
      }
    }
  }

  void setNoteArchived(String id, bool archived) {
    for (final note in notes) {
      if (note.id == id) note.archived = archived;
    }
    _changed();
  }

  void addScheduleEntry(ScheduleEntry entry) {
    schedule = [...schedule, entry];
    _changed();
  }

  void updateScheduleEntry(ScheduleEntry entry) {
    schedule = schedule
        .map((item) => item.id == entry.id ? entry : item)
        .toList();
    _changed();
  }

  void addScheduleProfile(String name) {
    profiles = [
      ...profiles,
      ScheduleProfile(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
      ),
    ];
    _changed();
  }

  bool deleteScheduleProfile(String id) {
    if (id == 'default' || profiles.length <= 1) return false;
    if (!profiles.any((profile) => profile.id == id)) return false;

    profiles = profiles.where((profile) => profile.id != id).toList();
    schedule = schedule.where((entry) => entry.profileId != id).toList();
    _changed();
    return true;
  }

  void deleteScheduleEntry(String id) {
    schedule = schedule.where((entry) => entry.id != id).toList();
    _changed();
  }

  void toggleTheme() {
    setAppearanceMode(appearanceMode == 'dark' ? 'light' : 'dark');
  }

  void setAppearanceMode(String mode) {
    if (!const {'system', 'light', 'dark'}.contains(mode)) return;
    appearanceMode = mode;
    darkMode = mode == 'dark';
    _changed();
  }

  void setThemeColors({
    required String background,
    required String primary,
    required String text,
    required String surface,
  }) {
    backgroundColor = background;
    primaryColor = primary;
    textColor = text;
    surfaceColor = surface;
    _changed();
  }

  void resetThemeColors() {
    setThemeColors(
      background: defaultThemeBackground,
      primary: defaultThemePrimary,
      text: defaultThemeText,
      surface: defaultThemeSurface,
    );
  }

  void completeTutorial() {
    if (tutorialCompleted) return;
    tutorialCompleted = true;
    _changed();
  }

  void resetTutorial() {
    tutorialCompleted = false;
    _changed();
  }

  void completeFocusSession(
    int minutes, {
    String? subjectId,
    DateTime? startedAt,
    String? sessionId,
  }) {
    if (minutes <= 0 ||
        (sessionId != null && studySessions.any((s) => s.id == sessionId))) {
      return;
    }
    focusMinutes += minutes;
    studySessions = [
      ...studySessions,
      StudySession(
        id: sessionId ?? _id(),
        minutes: minutes,
        startedAt:
            startedAt ?? DateTime.now().subtract(Duration(minutes: minutes)),
        subjectId: subjectId,
      ),
    ];
    final today = _dateKey(DateTime.now());
    if (!focusDays.contains(today)) focusDays.add(today);
    _changed();
  }

  void markPremium() {
    if (user == null || premium) return;
    premium = true;
    _changed();
  }

  List<PlannerEvent> eventsOn(DateTime date) {
    return events.where((event) => plannerEventOccursOn(event, date)).toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  double get averageGrade {
    final graded = events.where((event) => event.grade != null).toList();
    if (graded.isEmpty) return 0;
    final totalWeight = graded.fold<double>(
      0,
      (total, event) => total + (event.weight ?? 0),
    );
    if (totalWeight > 0) {
      return graded.fold<double>(0, (total, event) {
            return total + event.grade! * (event.weight ?? 0);
          }) /
          totalWeight;
    }
    return graded.fold<double>(0, (total, event) => total + event.grade!) /
        graded.length;
  }

  int get completedObjectives => subjects.fold<int>(
    0,
    (total, subject) =>
        total + subject.objectives.where((item) => item.completed).length,
  );

  int get totalObjectives => subjects.fold<int>(
    0,
    (total, subject) => total + subject.objectives.length,
  );

  List<PlannerEvent> examsForSubject(String subjectId) =>
      events
          .where(
            (event) =>
                event.subjectId == subjectId && event.type == EventType.examen,
          )
          .toList()
        ..sort((a, b) => a.startDate.compareTo(b.startDate));

  List<PlannerNote> notesForSubject(String subjectId) =>
      notes
          .where((note) => note.subjectId == subjectId && !note.archived)
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  int studyMinutesForSubject(String subjectId) => studySessions
      .where((session) => session.subjectId == subjectId)
      .fold<int>(0, (total, session) => total + session.minutes);

  double averageGradeForSubject(String subjectId) {
    final graded = events
        .where((event) => event.subjectId == subjectId && event.grade != null)
        .toList();
    if (graded.isEmpty) return 0;
    final totalWeight = graded.fold<double>(
      0,
      (total, event) => total + (event.weight ?? 0),
    );
    if (totalWeight > 0) {
      return graded.fold<double>(0, (total, event) {
            return total + event.grade! * (event.weight ?? 0);
          }) /
          totalWeight;
    }
    return graded.fold<double>(0, (total, event) => total + event.grade!) /
        graded.length;
  }

  @override
  void dispose() {
    _disposed = true;
    _authGeneration++;
    _authSubscription?.cancel();
    _retryTimer?.cancel();
    _syncDebounce?.cancel();
    _premiumService?.dispose();
    super.dispose();
  }

  bool _isCurrent(int generation, String uid) =>
      !_disposed && _authGeneration == generation && user?.id == uid;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  String _storageKey(String uid) => 'studiary-flutter-v1-$uid';

  String _migrateDefaultColor(
    Object? value,
    String currentDefault,
    String legacyDefault,
  ) {
    final stored = value?.toString();
    if (stored == null || stored == legacyDefault) return currentDefault;
    return stored;
  }

  String _id() => DateTime.now().microsecondsSinceEpoch.toString();

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
