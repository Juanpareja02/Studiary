import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'models.dart';

class NotificationService {
  NotificationService._();
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;
  static bool _askedPermission = false;
  static Future<void> _queue = Future.value();
  static String? _fingerprint;

  static Future<void> initialize() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    tz.initializeTimeZones();
    // DateTime carries the device offset. Schedule that instant in UTC so a
    // user outside Spain gets the reminder at their own local event time.
    tz.setLocalLocation(tz.UTC);
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('ic_stat_studiary'),
    );
    await _plugin.initialize(settings: settings);
    _ready = true;
  }

  static Future<void> syncEvents(List<PlannerEvent> events) {
    if (!_ready) return Future.value();
    final snapshot = events.map((e) => PlannerEvent.fromMap(e.toMap())).toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    final fingerprint = jsonEncode(
      snapshot
          .map(
            (e) => {
              'id': e.id,
              'title': e.title,
              'start': e.startDate.toIso8601String(),
              'allDay': e.isAllDay,
              'type': e.type.name,
            },
          )
          .toList(),
    );
    _queue = _queue.catchError((Object _) {}).then((_) async {
      if (_fingerprint == fingerprint) return;
      try {
        if (snapshot.isNotEmpty && !_askedPermission) {
          _askedPermission = true;
          await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission();
        }
        await _plugin.cancelAll();
        final now = DateTime.now();
        const details = NotificationDetails(
          android: AndroidNotificationDetails(
            'studiary_events',
            'Recordatorios de Studiary',
            channelDescription: 'Avisos de clases, entregas y exámenes',
            importance: Importance.high,
            priority: Priority.high,
          ),
        );
        var scheduled = 0;
        for (final event in snapshot) {
          final localDate = event.startDate.toLocal();
          final reminder = event.isAllDay
              ? DateTime(localDate.year, localDate.month, localDate.day, 9)
              : localDate.subtract(const Duration(minutes: 30));
          if (!reminder.isAfter(now)) continue;
          if (scheduled++ >= 64) break;
          await _plugin.zonedSchedule(
            id: _notificationId(event.id),
            title: event.title,
            body: event.isAllDay
                ? 'Lo tienes previsto para hoy'
                : event.type == EventType.examen
                ? 'Examen en 30 minutos'
                : 'Tu evento empieza en 30 minutos',
            scheduledDate: tz.TZDateTime.from(reminder, tz.UTC),
            notificationDetails: details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            payload: event.id,
          );
        }
        _fingerprint = fingerprint;
      } catch (_) {
        debugPrint('Recordatorios pendientes de actualizar');
      }
    });
    return _queue;
  }

  static int _notificationId(String id) {
    var hash = 0;
    for (final unit in id.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return hash;
  }
}
