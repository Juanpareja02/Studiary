import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'package:studiary/app_state.dart';
import 'package:studiary/brand.dart';
import 'package:studiary/models.dart';
import 'package:studiary/services.dart';
import 'package:studiary/theme.dart';
import 'package:studiary/tutorial.dart';
import 'package:studiary/widgets.dart';

void main() {
  testWidgets('Studiary muestra su marca', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Column(
          children: [
            StudiaryLogo(width: 180),
            StudiaryMascot(size: 80, animate: false),
          ],
        ),
      ),
    );
    expect(find.byType(Image), findsNWidgets(2));
    expect(
      find.bySemanticsLabel('Studi, la mascota de Studiary'),
      findsOneWidget,
    );
  });

  test('la guía tiene pasos cortos y cubre el flujo principal', () {
    expect(studiaryTutorialSteps, hasLength(6));
    expect(
      studiaryTutorialSteps.map((step) => step.title),
      containsAll([
        'Empieza en Hoy',
        'Mira tu semana',
        'Entra en foco',
        'Tu cuenta, siempre contigo',
      ]),
    );
    expect(MascotPose.focus.asset, BrandAssets.mascotFocus);
  });

  test('acepta eventos guardados por la versión anterior', () {
    final event = PlannerEvent.fromMap({
      'id': 'legacy-1',
      'title': 'Práctica de álgebra',
      'startDate': '2026-09-03T09:00:00.000',
      'type': 'prácticas',
    });

    expect(event.type, EventType.practicas);
  });

  test('los eventos de varios días aparecen en cada fecha que cubren', () {
    final event = PlannerEvent(
      id: 'multi-day',
      title: 'Semana de exámenes',
      startDate: DateTime(2026, 9, 10),
      endDate: DateTime(2026, 9, 12),
      type: EventType.examen,
    );

    expect(plannerEventOccursOn(event, DateTime(2026, 9, 9)), isFalse);
    expect(plannerEventOccursOn(event, DateTime(2026, 9, 10)), isTrue);
    expect(plannerEventOccursOn(event, DateTime(2026, 9, 11)), isTrue);
    expect(plannerEventOccursOn(event, DateTime(2026, 9, 12)), isTrue);
    expect(plannerEventOccursOn(event, DateTime(2026, 9, 13)), isFalse);
  });

  test('migra las claves antiguas de Firestore por usuario', () {
    final migrated = normalizeLegacyRemoteData({
      'studiary-events-user-1-v3': [
        {'id': 'legacy-event'},
      ],
      'studiary-notes-user-1-v1': [
        {'id': 'legacy-note'},
      ],
    }, 'user-1');

    expect((migrated['events'] as List).single['id'], 'legacy-event');
    expect((migrated['notes'] as List).single['id'], 'legacy-note');
  });

  test('conserva el formato y el adjunto de una nota', () {
    final note = PlannerNote.fromMap({
      'id': 'note-1',
      'title': 'Tema 1',
      'subjectId': 'math',
      'type': 'image',
      'fileName': 'tema-1.png',
      'fileUrl': 'https://example.com/tema-1.png',
      'createdAt': '2026-09-03T09:00:00.000',
      'updatedAt': '2026-09-03T09:00:00.000',
    });

    final saved = note.toMap();
    expect(note.type, NoteType.image);
    expect(saved['fileName'], 'tema-1.png');
    expect(saved['fileUrl'], 'https://example.com/tema-1.png');
  });

  test('admite apuntes de vídeo y enlaces', () {
    expect(noteTypeFromString('video'), NoteType.video);
    expect(noteTypeFromString('link'), NoteType.link);
    final link = PlannerNote.fromMap({
      'id': 'link-1',
      'title': 'Material',
      'content': 'https://example.com',
      'subjectId': 'math',
      'type': 'link',
    });
    expect(link.type, NoteType.link);
    expect(link.toMap()['content'], 'https://example.com');
  });

  test('las sesiones de estudio se vinculan a una asignatura', () {
    final session = StudySession.fromMap({
      'id': 'session-1',
      'minutes': 45,
      'startedAt': '2026-09-04T09:00:00.000',
      'subjectId': 'math',
    });

    expect(session.minutes, 45);
    expect(session.subjectId, 'math');
    expect(session.toMap()['subjectId'], 'math');
  });

  test('tolera objetivos corruptos y mantiene las fechas en español', () async {
    final subject = Subject.fromMap({
      'id': 'math',
      'name': 'Matemáticas',
      'objectives': 'dato inválido',
    });
    await initializeDateFormatting('es_ES');

    expect(subject.objectives, isEmpty);
    expect(DateFormat('MMMM', 'es_ES').format(DateTime(2026, 9)), 'septiembre');
  });

  test('el tema admite colores pastel y variante oscura', () {
    final light = buildTheme(
      dark: false,
      backgroundHex: '#F1FBF7',
      primaryHex: '#82CDB4',
      textHex: '#20413E',
      surfaceHex: '#F7FFFB',
    );
    final dark = buildTheme(
      dark: true,
      backgroundHex: '#F1FBF7',
      primaryHex: '#82CDB4',
      textHex: '#20413E',
      surfaceHex: '#F7FFFB',
    );

    expect(light.brightness, Brightness.light);
    expect(light.colorScheme.primary, const Color(0xFF82CDB4));
    expect(dark.brightness, Brightness.dark);
    expect(dark.scaffoldBackgroundColor, isNot(light.scaffoldBackgroundColor));
  });

  test('Premium usa una única compra para siempre', () {
    expect(MonetizationService.premiumProductId, 'studiary_premium_lifetime');
    expect(
      MonetizationService.premiumIds,
      contains('studiary_premium_lifetime'),
    );
    expect(
      MonetizationService.premiumIds,
      isNot(contains('studiary_premium_monthly')),
    );
    expect(
      MonetizationService.premiumIds,
      isNot(contains('studiary_premium_yearly')),
    );
    expect(
      MonetizationService.entitlementIds,
      contains('studiary_premium_monthly'),
    );
    expect(
      MonetizationService.entitlementIds,
      contains('studiary_premium_yearly'),
    );
  });

  test('el horario conserva día, horas y asignatura', () {
    final entry = ScheduleEntry.fromMap({
      'id': 'class-1',
      'profileId': 'semester-1',
      'dayOfWeek': 3,
      'startTime': '10:30',
      'endTime': '12:00',
      'subjectId': 'math',
      'note': 'Llevar calculadora',
    });

    expect(entry.toMap(), {
      'id': 'class-1',
      'profileId': 'semester-1',
      'dayOfWeek': 3,
      'startTime': '10:30',
      'endTime': '12:00',
      'subjectId': 'math',
      'note': 'Llevar calculadora',
    });
  });

  test('permite crear, editar y eliminar eventos y clases', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await supabase.Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-publishable-key',
    );

    final state = AppState();
    final event = PlannerEvent(
      id: 'event-crud',
      title: 'Entrega de matemáticas',
      startDate: DateTime(2026, 9, 10, 10),
      type: EventType.practicas,
    );
    state.addEvent(event);
    expect(state.events, contains(event));

    final editedEvent = PlannerEvent(
      id: event.id,
      title: 'Entrega editada',
      startDate: event.startDate,
      type: event.type,
    );
    state.updateEvent(editedEvent);
    expect(state.events.single.title, 'Entrega editada');
    state.deleteEvent(event.id);
    expect(state.events, isEmpty);

    final entry = ScheduleEntry(
      id: 'schedule-crud',
      profileId: 'default',
      dayOfWeek: 1,
      startTime: '08:00',
      endTime: '09:00',
      subjectId: 'math',
    );
    state.addScheduleEntry(entry);
    expect(state.schedule.single.startTime, '08:00');
    state.updateScheduleEntry(
      ScheduleEntry(
        id: entry.id,
        profileId: entry.profileId,
        dayOfWeek: entry.dayOfWeek,
        startTime: '09:00',
        endTime: '10:00',
        subjectId: entry.subjectId,
      ),
    );
    expect(state.schedule.single.endTime, '10:00');
    state.deleteScheduleEntry(entry.id);
    expect(state.schedule, isEmpty);
    state.dispose();
  });
}
