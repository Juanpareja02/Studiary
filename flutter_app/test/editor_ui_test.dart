import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:studiary/app_state.dart';
import 'package:studiary/models.dart';
import 'package:studiary/notebook_page.dart';
import 'package:studiary/schedule_widget.dart';
import 'package:studiary/dialogs.dart';
import 'package:studiary/main.dart' as app;

class EditorState extends AppState {
  EditorState() : super(initialize: false) {
    user = supabase.User(
      id: 'editor-qa',
      appMetadata: {},
      userMetadata: {},
      aud: 'authenticated',
      createdAt: '2026-09-05T00:00:00Z',
    );
    subjects = [Subject(id: 'math', name: 'Matemáticas', color: '#123456')];
  }
  @override
  void addNote(PlannerNote note) {
    notes.add(note);
  }

  @override
  void updateNote(PlannerNote note) {
    notes = notes.map((n) => n.id == note.id ? note : n).toList();
  }

  @override
  Future<void> saveLocally() async {}
}

void main() {
  testWidgets('notebook persists a draft, previews Markdown and saves a page', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final state = EditorState();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => NotebookPage(state: state, subjectId: 'math'),
                ),
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Álgebra');
    await tester.enterText(
      find.byType(TextField).last,
      '## Vectores\n\nUn **resumen** de clase.',
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString('studiary-draft-editor-qa-math'),
      contains('Vectores'),
    );
    await tester.tap(find.byTooltip('Vista previa'));
    await tester.pumpAndSettle();
    expect(find.byType(NoteMarkdown), findsOneWidget);
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(state.notes.single.title, 'Álgebra');
    expect(prefs.getString('studiary-draft-editor-qa-math'), isNull);
    expect(tester.takeException(), isNull);
    state.dispose();
  });

  testWidgets(
    'editing an old subject color does not crash the color selector',
    (tester) async {
      final state = EditorState();
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () =>
                    showSubjectForm(context, subject: state.subjects.single),
                child: const Text('Editar'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();
      expect(find.text('#123456'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      state.dispose();
    },
  );

  testWidgets('weekly schedule fits a narrow phone and large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final day = DateTime.now().weekday;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: WeeklyScheduleBoard(
                subjects: [
                  Subject(
                    id: 'math',
                    name: 'Matemáticas y análisis avanzado',
                    color: '#8A9BFF',
                  ),
                ],
                entries: [
                  ScheduleEntry(
                    id: 'e',
                    profileId: 'default',
                    dayOfWeek: day,
                    startTime: '08:30',
                    endTime: '10:00',
                    subjectId: 'math',
                  ),
                ],
                onAdd: (_, _) {},
                onEdit: (_) {},
                onDelete: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'weekly agenda alternates between calendar and list without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await initializeDateFormatting('es_ES');

      final state = EditorState();
      final now = DateTime.now();
      state.events = [
        PlannerEvent(
          id: 'agenda-event',
          title: 'Examen de matemáticas',
          startDate: DateTime(now.year, now.month, now.day, 9),
          type: EventType.examen,
        ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: app.WeeklyAgenda(state: state)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Vista semanal'), findsOneWidget);
      expect(find.text('HORA'), findsOneWidget);
      await tester.tap(find.text('Lista'));
      await tester.pumpAndSettle();
      expect(find.text('Examen de matemáticas'), findsOneWidget);
      expect(find.text('HORA'), findsNothing);
      await tester.tap(find.text('Calendario'));
      await tester.pumpAndSettle();
      expect(find.text('HORA'), findsOneWidget);
      expect(tester.takeException(), isNull);
      state.dispose();
    },
  );

  testWidgets('a custom school schedule can be deleted with confirmation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = EditorState();
    state.profiles = [
      ScheduleProfile(id: 'default', name: 'Horario principal'),
      ScheduleProfile(id: 'second', name: 'Segundo semestre'),
    ];
    state.schedule = [
      ScheduleEntry(
        id: 'second-class',
        profileId: 'second',
        dayOfWeek: 1,
        startTime: '08:00',
        endTime: '09:00',
        subjectId: 'math',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: app.ScheduleAgenda(state: state)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Segundo semestre').last);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byTooltip('Eliminar horario actual'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Eliminar horario'), findsOneWidget);
    expect(
      find.textContaining('También se eliminará su clase guardada.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Eliminar').last);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(state.profiles.map((profile) => profile.id), ['default']);
    expect(state.schedule, isEmpty);
    expect(find.byTooltip('Eliminar horario actual'), findsNothing);
    expect(tester.takeException(), isNull);
    state.dispose();
  });
}
