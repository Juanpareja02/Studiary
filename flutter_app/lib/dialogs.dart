import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_state.dart';
import 'models.dart';
import 'notebook_page.dart';
import 'video_note_page.dart';
import 'package:mime/mime.dart';
import 'services.dart';
import 'theme.dart';
import 'widgets.dart';

Future<void> showEventEditor(
  BuildContext context,
  AppState state, {
  PlannerEvent? event,
  DateTime? initialDate,
  EventType? initialType,
  String? initialSubjectId,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    builder: (_) => EventEditorSheet(
      state: state,
      event: event,
      initialDate: initialDate,
      initialType: initialType,
      initialSubjectId: initialSubjectId,
    ),
  );
}

class EventEditorSheet extends StatefulWidget {
  const EventEditorSheet({
    super.key,
    required this.state,
    this.event,
    this.initialDate,
    this.initialType,
    this.initialSubjectId,
  });

  final AppState state;
  final PlannerEvent? event;
  final DateTime? initialDate;
  final EventType? initialType;
  final String? initialSubjectId;

  @override
  State<EventEditorSheet> createState() => _EventEditorSheetState();
}

class _EventEditorSheetState extends State<EventEditorSheet> {
  late final TextEditingController titleController;
  late final TextEditingController descriptionController;
  late final TextEditingController gradeController;
  late final TextEditingController weightController;
  late DateTime startDate;
  DateTime? endDate;
  late EventType type;
  String? subjectId;
  bool allDay = false;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    final initial = widget.initialDate ?? DateTime.now();
    startDate =
        event?.startDate ??
        DateTime(initial.year, initial.month, initial.day, 9);
    endDate = event?.endDate;
    type = event?.type ?? widget.initialType ?? EventType.estudio;
    subjectId = event?.subjectId ?? widget.initialSubjectId;
    allDay = event?.isAllDay ?? false;
    titleController = TextEditingController(text: event?.title ?? '');
    descriptionController = TextEditingController(
      text: event?.description ?? '',
    );
    gradeController = TextEditingController(
      text: event?.grade?.toString() ?? '',
    );
    weightController = TextEditingController(
      text: event?.weight?.toString() ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isExam = type == EventType.examen;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SheetHandle(),
            const SizedBox(height: 22),
            Text(
              widget.event == null ? 'Nuevo evento' : 'Editar evento',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: titleController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Título',
                prefixIcon: Icon(Icons.title_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<EventType>(
              initialValue: type,
              decoration: const InputDecoration(
                labelText: 'Tipo',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: EventType.values
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(value.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) =>
                  setState(() => type = value ?? EventType.personal),
            ),
            const SizedBox(height: 12),
            _DateButton(
              label: 'Inicio',
              date: startDate,
              onTap: () => _pickDate(isStart: true),
            ),
            const SizedBox(height: 10),
            _DateButton(
              label: 'Fin opcional',
              date: endDate,
              onTap: () => _pickDate(isStart: false),
              onClear: endDate == null
                  ? null
                  : () => setState(() => endDate = null),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: allDay,
              onChanged: (value) => setState(() => allDay = value),
              title: const Text('Todo el día'),
              subtitle: const Text('Oculta la hora en la agenda'),
            ),
            if (isExam) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue:
                    widget.state.subjects.any((item) => item.id == subjectId)
                    ? subjectId
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Asignatura',
                  prefixIcon: Icon(Icons.menu_book_outlined),
                ),
                items: widget.state.subjects
                    .map(
                      (subject) => DropdownMenuItem(
                        value: subject.id,
                        child: Text(subject.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => subjectId = value),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: gradeController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Nota',
                        prefixIcon: Icon(Icons.grade_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: weightController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Peso %',
                        prefixIcon: Icon(Icons.percent_rounded),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check_rounded),
                label: Text(
                  widget.event == null ? 'Guardar evento' : 'Guardar cambios',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final current = isStart ? startDate : endDate ?? startDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('es'),
    );
    if (picked == null || !mounted) return;
    if (isStart) {
      setState(
        () => startDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          startDate.hour,
          startDate.minute,
        ),
      );
    } else {
      setState(
        () => endDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          current.hour,
          current.minute,
        ),
      );
    }
  }

  void _save() {
    final title = titleController.text.trim();
    if (title.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escribe un título de al menos 2 caracteres.'),
        ),
      );
      return;
    }
    if (endDate != null && endDate!.isBefore(startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La fecha de fin debe ser posterior al inicio.'),
        ),
      );
      return;
    }
    final gradeText = gradeController.text.trim().replaceAll(',', '.');
    final weightText = weightController.text.trim().replaceAll(',', '.');
    final grade = double.tryParse(gradeText);
    final weight = double.tryParse(weightText);
    if (gradeText.isNotEmpty && (grade == null || grade < 0 || grade > 10)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La nota debe estar entre 0 y 10.')),
      );
      return;
    }
    if (weightText.isNotEmpty &&
        (weight == null || weight < 0 || weight > 100)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El peso debe estar entre 0 y 100 %.')),
      );
      return;
    }
    final saved = PlannerEvent(
      id: widget.event?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      startDate: startDate,
      endDate: endDate,
      type: type,
      description: descriptionController.text.trim().isEmpty
          ? null
          : descriptionController.text.trim(),
      isAllDay: allDay,
      grade: grade,
      subjectId: type == EventType.examen ? subjectId : null,
      weight: weight,
      color:
          '#${eventTypeColor(type).toARGB32().toRadixString(16).substring(2)}',
    );
    if (widget.event == null) {
      widget.state.addEvent(saved);
    } else {
      widget.state.updateEvent(saved);
    }
    Navigator.pop(context);
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    gradeController.dispose();
    weightController.dispose();
    super.dispose();
  }
}

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 38,
      height: 4,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(4),
      ),
    ),
  );
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.date,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined),
          suffixIcon: onClear == null
              ? null
              : IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded),
                ),
        ),
        child: Text(
          date == null
              ? 'Seleccionar fecha'
              : DateFormat('EEEE, d MMMM · HH:mm', 'es_ES').format(date!),
        ),
      ),
    );
  }
}

Future<void> showEventDetails(
  BuildContext context,
  AppState state,
  PlannerEvent event,
) async {
  await showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SheetHandle(),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: Text(
                  event.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              EventTypeBadge(type: event.type),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            DateFormat(
              'EEEE, d MMMM yyyy · HH:mm',
              'es_ES',
            ).format(event.startDate),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (event.description != null) ...[
            const SizedBox(height: 12),
            Text(event.description!, style: const TextStyle(height: 1.4)),
          ],
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    showEventEditor(context, state, event: event);
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () {
                    Navigator.pop(context);
                    _confirmDelete(context, state, event);
                  },
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Eliminar'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Future<void> _confirmDelete(
  BuildContext context,
  AppState state,
  PlannerEvent event,
) async {
  final confirmed = await _ownedDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Eliminar evento'),
      content: Text('¿Quieres eliminar “${event.title}”?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Eliminar'),
        ),
      ],
    ),
  );
  if (confirmed == true) state.deleteEvent(event.id);
}

Future<void> showSubjectManager(BuildContext context, AppState state) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    builder: (_) => SubjectManagerSheet(state: state),
  );
}

class SubjectManagerSheet extends StatefulWidget {
  const SubjectManagerSheet({super.key, required this.state});

  final AppState state;

  @override
  State<SubjectManagerSheet> createState() => _SubjectManagerSheetState();
}

class _SubjectManagerSheetState extends State<SubjectManagerSheet> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SheetHandle(),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Asignaturas',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                onPressed: () async {
                  final subject = await showSubjectForm(context);
                  if (subject != null) {
                    widget.state.addSubject(subject);
                    setState(() {});
                  }
                },
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (widget.state.subjects.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('Todavía no tienes asignaturas.')),
            ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: widget.state.subjects.map((subject) {
                return Card(
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: colorFromHex(subject.color),
                    ),
                    title: Text(
                      subject.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle:
                        subject.classroom == null || subject.classroom!.isEmpty
                        ? null
                        : Text(subject.classroom!),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'edit') {
                          final edited = await showSubjectForm(
                            context,
                            subject: subject,
                          );
                          if (edited != null) {
                            widget.state.updateSubject(edited);
                            setState(() {});
                          }
                        } else {
                          widget.state.deleteSubject(subject.id);
                          setState(() {});
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Editar')),
                        PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                      ],
                    ),
                    children: [
                      ...subject.objectives.map(
                        (objective) => CheckboxListTile(
                          contentPadding: const EdgeInsets.only(
                            left: 72,
                            right: 8,
                          ),
                          value: objective.completed,
                          onChanged: (_) {
                            widget.state.toggleObjective(
                              subject.id,
                              objective.id,
                            );
                            setState(() {});
                          },
                          title: Text(objective.description),
                        ),
                      ),
                      ListTile(
                        contentPadding: const EdgeInsets.only(left: 72),
                        leading: const Icon(Icons.add_task_rounded),
                        title: const Text('Añadir objetivo'),
                        onTap: () async {
                          final objective = await _textDialog(
                            context,
                            'Nuevo objetivo',
                            'Ej: Repasar el tema 3',
                          );
                          if (objective != null &&
                              objective.trim().isNotEmpty) {
                            widget.state.addObjective(
                              subject.id,
                              objective.trim(),
                            );
                            setState(() {});
                          }
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

Future<Subject?> showSubjectForm(
  BuildContext context, {
  Subject? subject,
}) async {
  final name = TextEditingController(text: subject?.name ?? '');
  final classroom = TextEditingController(text: subject?.classroom ?? '');
  var color = subject?.color ?? '#F58F8F';
  final result = await _ownedDialog<Subject>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(subject == null ? 'Nueva asignatura' : 'Editar asignatura'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: classroom,
              decoration: const InputDecoration(labelText: 'Aula o grupo'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: color,
              decoration: const InputDecoration(labelText: 'Color'),
              items:
                  {color, '#8A9BFF', '#B9A7F8', '#8FD9C2', '#F58F8F', '#FFF0B8'}
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 8,
                                backgroundColor: colorFromHex(value),
                              ),
                              const SizedBox(width: 8),
                              Text(value),
                            ],
                          ),
                        ),
                      )
                      .toList(),
              onChanged: (value) => setState(() => color = value ?? color),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (name.text.trim().isEmpty) return;
              Navigator.pop(
                dialogContext,
                Subject(
                  id:
                      subject?.id ??
                      DateTime.now().microsecondsSinceEpoch.toString(),
                  name: name.text.trim(),
                  color: color,
                  classroom: classroom.text.trim(),
                  objectives: subject?.objectives,
                ),
              );
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    ),
  );
  name.dispose();
  classroom.dispose();
  return result;
}

Future<void> showNoteEditor(
  BuildContext context,
  AppState state, {
  String? subjectId,
}) async {
  if (state.subjects.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Crea una asignatura antes de añadir un apunte.'),
      ),
    );
    return;
  }
  final type = await showModalBottomSheet<NoteType>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(
            title: Text(
              'Nuevo apunte',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            subtitle: Text('Elige el formato que quieres guardar'),
          ),
          ListTile(
            leading: const Icon(Icons.notes_rounded),
            title: const Text('Página del cuaderno'),
            onTap: () => Navigator.pop(context, NoteType.text),
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf_rounded),
            title: const Text('PDF'),
            onTap: () => Navigator.pop(context, NoteType.pdf),
          ),
          ListTile(
            leading: const Icon(Icons.image_outlined),
            title: const Text('Imagen'),
            onTap: () => Navigator.pop(context, NoteType.image),
          ),
          ListTile(
            leading: const Icon(Icons.video_library_outlined),
            title: const Text('Vídeo'),
            onTap: () => Navigator.pop(context, NoteType.video),
          ),
          ListTile(
            leading: const Icon(Icons.link_rounded),
            title: const Text('Enlace'),
            onTap: () => Navigator.pop(context, NoteType.link),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Documento'),
            subtitle: const Text('Word, Excel, PowerPoint, texto o CSV'),
            onTap: () => Navigator.pop(context, NoteType.file),
          ),
          const SizedBox(height: 10),
        ],
      ),
    ),
  );
  if (type == null) return;
  if (!context.mounted) return;
  if (type == NoteType.text) {
    await _showTextNoteEditor(context, state, subjectId: subjectId);
  } else if (type == NoteType.link) {
    await _showLinkNoteEditor(context, state, subjectId: subjectId);
  } else {
    await _showFileNoteEditor(context, state, type, subjectId: subjectId);
  }
}

Future<void> showNoteEditorForSubject(
  BuildContext context,
  AppState state, {
  required String subjectId,
}) => showNoteEditor(context, state, subjectId: subjectId);

Future<void> showNotebookEditor(
  BuildContext context,
  AppState state, {
  required Subject subject,
}) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => NotebookPage(state: state, subjectId: subject.id),
  ),
);

class _ThemeSelection {
  const _ThemeSelection({
    required this.background,
    required this.primary,
    required this.text,
    required this.surface,
  });

  final String background;
  final String primary;
  final String text;
  final String surface;
}

Future<void> showPremiumUpsell(
  BuildContext context, {
  required String feature,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const StudiaryMascot(size: 74),
          const SizedBox(height: 12),
          Text(
            'Una ayuda extra para estudiar',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '$feature está incluido en Studiary Premium. Es un único pago de 3 € y lo conservas para siempre.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ver Premium en Perfil'),
          ),
        ],
      ),
    ),
  );
}

Future<void> showThemeCustomizer(BuildContext context, AppState state) async {
  var background = state.backgroundColor;
  var primary = state.primaryColor;
  var text = state.textColor;
  var surface = state.surfaceColor;
  const backgroundOptions = [
    '#FFF8FB',
    '#FFF8EE',
    '#F1FBF7',
    '#F6F2FF',
    '#F2F7FF',
    '#FFF1F0',
  ];
  const primaryOptions = [
    '#FF8FA3',
    '#FFAB91',
    '#82CDB4',
    '#91B4EE',
    '#B29CE5',
    '#E1B75B',
  ];
  const textOptions = ['#26334D', '#3D3042', '#20413E', '#332E50'];
  const surfaceOptions = [
    '#FFFFFF',
    '#FFFDF7',
    '#F7FFFB',
    '#FAF8FF',
    '#F7FAFF',
  ];
  final selection = await _ownedDialog<_ThemeSelection>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Colores y estilo'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Combina colores pastel o escribe tu propio color HEX.',
              ),
              const SizedBox(height: 18),
              _ColorChoices(
                label: 'Fondo',
                selected: background,
                options: backgroundOptions,
                onSelected: (value) => setState(() => background = value),
              ),
              _ColorChoices(
                label: 'Botones y acento',
                selected: primary,
                options: primaryOptions,
                onSelected: (value) => setState(() => primary = value),
              ),
              _ColorChoices(
                label: 'Texto',
                selected: text,
                options: textOptions,
                onSelected: (value) => setState(() => text = value),
              ),
              _ColorChoices(
                label: 'Tarjetas',
                selected: surface,
                options: surfaceOptions,
                onSelected: (value) => setState(() => surface = value),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              const _ThemeSelection(
                background: defaultThemeBackground,
                primary: defaultThemePrimary,
                text: defaultThemeText,
                surface: defaultThemeSurface,
              ),
            ),
            child: const Text('Restaurar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              _ThemeSelection(
                background: background,
                primary: primary,
                text: text,
                surface: surface,
              ),
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    ),
  );
  if (selection == null) return;
  state.setThemeColors(
    background: selection.background,
    primary: selection.primary,
    text: selection.text,
    surface: selection.surface,
  );
}

class _ColorChoices extends StatelessWidget {
  const _ColorChoices({
    required this.label,
    required this.selected,
    required this.options,
    required this.onSelected,
  });

  final String label;
  final String selected;
  final List<String> options;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ...options.map((value) {
                final isSelected = value == selected;
                return Semantics(
                  button: true,
                  selected: isSelected,
                  label: '$label $value',
                  child: InkWell(
                    onTap: () => onSelected(value),
                    customBorder: const CircleBorder(),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 36,
                      height: 36,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colorFromHex(value),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                );
              }),
              ActionChip(
                avatar: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Personalizar'),
                onPressed: () async {
                  final value = await _showHexColorDialog(
                    context,
                    label: label,
                    selected: selected,
                  );
                  if (value != null) onSelected(value);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<String?> _showHexColorDialog(
  BuildContext context, {
  required String label,
  required String selected,
}) async {
  final controller = TextEditingController(text: selected);
  String? error;
  final result = await _ownedDialog<String>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text('Color de $label'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            labelText: 'Código HEX',
            hintText: '#FF8FA3',
            errorText: error,
          ),
          onSubmitted: (_) {
            final value = _validHexColor(controller.text);
            if (value == null) {
              setState(() => error = 'Usa seis caracteres hexadecimales.');
            } else {
              Navigator.pop(dialogContext, value);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final value = _validHexColor(controller.text);
              if (value == null) {
                setState(() => error = 'Usa seis caracteres hexadecimales.');
              } else {
                Navigator.pop(dialogContext, value);
              }
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    ),
  );
  controller.dispose();
  return result;
}

String? _validHexColor(String value) {
  final clean = value.trim().replaceFirst('#', '');
  if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(clean)) return null;
  return '#${clean.toUpperCase()}';
}

Future<void> _showTextNoteEditor(
  BuildContext context,
  AppState state, {
  String? subjectId,
}) async {
  final chosen =
      subjectId ??
      await _ownedDialog<String>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Asignatura del apunte'),
          children: state.subjects
              .map(
                (s) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, s.id),
                  child: Text(s.name),
                ),
              )
              .toList(),
        ),
      );
  if (chosen == null || !context.mounted) return;
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => NotebookPage(state: state, subjectId: chosen),
    ),
  );
}

Future<void> _showFileNoteEditor(
  BuildContext context,
  AppState state,
  NoteType type, {
  String? subjectId,
}) async {
  final title = TextEditingController();
  var selectedSubjectId = state.subjects.any((item) => item.id == subjectId)
      ? subjectId!
      : state.subjects.first.id;
  PlatformFile? selectedFile;
  var saving = false;
  final label = switch (type) {
    NoteType.pdf => 'PDF',
    NoteType.image => 'imagen',
    NoteType.video => 'vídeo',
    NoteType.text || NoteType.link || NoteType.file => 'archivo',
  };

  await _ownedDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => PopScope(
        canPop: !saving,
        child: AlertDialog(
          title: Text('Nuevo apunte de $label'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'Título'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedSubjectId,
                  decoration: const InputDecoration(labelText: 'Asignatura'),
                  items: state.subjects
                      .map(
                        (subject) => DropdownMenuItem(
                          value: subject.id,
                          child: Text(subject.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(
                    () => selectedSubjectId = value ?? selectedSubjectId,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: saving
                      ? null
                      : () async {
                          final file = await FilePicker.pickFile(
                            type: switch (type) {
                              NoteType.pdf || NoteType.file => FileType.custom,
                              NoteType.image => FileType.image,
                              NoteType.video => FileType.video,
                              NoteType.text || NoteType.link => FileType.any,
                            },
                            allowedExtensions: type == NoteType.pdf
                                ? ['pdf']
                                : type == NoteType.file
                                ? [
                                    'doc',
                                    'docx',
                                    'xls',
                                    'xlsx',
                                    'ppt',
                                    'pptx',
                                    'txt',
                                    'csv',
                                    'odt',
                                    'ods',
                                    'odp',
                                  ]
                                : null,
                          );
                          if (file == null || !context.mounted) return;
                          final size = file.lengthSync() ?? await file.length();
                          if (!context.mounted) return;
                          final maxBytes = 50 * 1024 * 1024;
                          if (size > maxBytes) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'El archivo supera los 50 MB. Puedes guardarlo como enlace.',
                                ),
                              ),
                            );
                            return;
                          }
                          setState(() {
                            selectedFile = file;
                            if (title.text.trim().isEmpty) {
                              title.text = file.name;
                            }
                          });
                        },
                  icon: const Icon(Icons.upload_file_rounded),
                  label: Text(selectedFile?.name ?? 'Seleccionar archivo'),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Hasta 50 MB por archivo. Se guardará de forma privada en tu cuenta.',
                  style: TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: saving || selectedFile == null
                  ? null
                  : () async {
                      final file = selectedFile!;
                      if (title.text.trim().isEmpty) return;
                      setState(() => saving = true);
                      try {
                        final bytes = await file.readAsBytes();
                        final user = state.user;
                        if (user == null) {
                          throw StateError('Sesión no disponible');
                        }
                        final noteId = DateTime.now().microsecondsSinceEpoch
                            .toString();
                        final url = await CloudSyncService.uploadNoteFile(
                          user: user,
                          noteId: noteId,
                          fileName: file.name,
                          contentType:
                              lookupMimeType(file.name) ??
                              'application/octet-stream',
                          bytes: bytes,
                        );
                        if (state.user?.id != user.id ||
                            !state.subjects.any(
                              (s) => s.id == selectedSubjectId,
                            )) {
                          await CloudSyncService.deleteNoteFile(url);
                          throw StateError(
                            'La cuenta o la asignatura ha cambiado',
                          );
                        }
                        state.addNote(
                          PlannerNote(
                            id: noteId,
                            title: title.text.trim(),
                            content: '',
                            subjectId: selectedSubjectId,
                            type: type,
                            fileName: file.name,
                            fileUrl: url,
                          ),
                        );
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                      } catch (error) {
                        if (context.mounted) {
                          setState(() => saving = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'No se pudo subir el archivo: $error',
                              ),
                            ),
                          );
                        }
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Guardar'),
            ),
          ],
        ),
      ),
    ),
  );
  title.dispose();
}

Future<void> _showLinkNoteEditor(
  BuildContext context,
  AppState state, {
  String? subjectId,
}) async {
  final title = TextEditingController();
  final url = TextEditingController();
  var selectedSubjectId = state.subjects.any((item) => item.id == subjectId)
      ? subjectId!
      : state.subjects.first.id;
  String? error;
  await _ownedDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Guardar enlace'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: title,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Título'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: url,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: 'URL',
                  hintText: 'https://...',
                  errorText: error,
                  prefixIcon: const Icon(Icons.link_rounded),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedSubjectId,
                decoration: const InputDecoration(labelText: 'Asignatura'),
                items: state.subjects
                    .map(
                      (subject) => DropdownMenuItem(
                        value: subject.id,
                        child: Text(subject.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(
                  () => selectedSubjectId = value ?? selectedSubjectId,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final parsed = Uri.tryParse(url.text.trim());
              final valid =
                  parsed != null &&
                  (parsed.scheme == 'http' || parsed.scheme == 'https') &&
                  parsed.host.isNotEmpty;
              if (title.text.trim().isEmpty || !valid) {
                setState(() => error = 'Escribe una URL válida (https://...)');
                return;
              }
              state.addNote(
                PlannerNote(
                  id: DateTime.now().microsecondsSinceEpoch.toString(),
                  title: title.text.trim(),
                  content: url.text.trim(),
                  subjectId: selectedSubjectId,
                  type: NoteType.link,
                ),
              );
              Navigator.pop(dialogContext);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    ),
  );
  title.dispose();
  url.dispose();
}

Future<void> showNotePreview(
  BuildContext context,
  PlannerNote note, {
  AppState? state,
}) async {
  final fileUrl = await _resolveNoteUrl(note.fileUrl);
  if (note.type == NoteType.video && fileUrl != null) {
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VideoNotePage(title: note.title, url: fileUrl),
      ),
    );
    return;
  }
  if (note.type == NoteType.link) {
    final reference = fileUrl ?? note.content;
    final parsed = Uri.tryParse(reference);
    if (parsed != null &&
        {'http', 'https'}.contains(parsed.scheme) &&
        parsed.host.isNotEmpty &&
        await launchUrl(parsed, mode: LaunchMode.externalApplication)) {
      return;
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir este enlace.')),
      );
    }
    return;
  }
  if ((note.type == NoteType.pdf || note.type == NoteType.file) &&
      fileUrl != null) {
    final opened = await launchUrl(
      Uri.parse(fileUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No se pudo abrir el PDF.')));
    }
    return;
  }
  if (note.type == NoteType.text) {
    if (!context.mounted) return;
    if (state != null) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              NotebookPage(state: state, subjectId: note.subjectId, note: note),
        ),
      );
    } else {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            appBar: AppBar(title: Text(note.title)),
            body: NoteMarkdown(data: note.content),
          ),
        ),
      );
    }
    return;
  }
  if (fileUrl == null && note.fileDataUri == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo cargar el archivo. Comprueba tu conexión.'),
        ),
      );
    }
    return;
  }
  if (note.type != NoteType.image) return;
  Widget image;
  if (fileUrl != null) {
    image = Image.network(fileUrl, fit: BoxFit.contain);
  } else if (note.fileDataUri != null) {
    try {
      final encoded = note.fileDataUri!.split(',').last;
      image = Image.memory(base64Decode(encoded), fit: BoxFit.contain);
    } catch (_) {
      return;
    }
  } else {
    return;
  }
  if (!context.mounted) return;
  await _ownedDialog<void>(
    context: context,
    builder: (context) => Dialog(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: InteractiveViewer(child: image),
      ),
    ),
  );
}

Future<void> confirmDeleteNote(
  BuildContext context,
  AppState state,
  PlannerNote note,
) async {
  final confirmed = await _ownedDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Eliminar apunte'),
      content: Text(
        'Se eliminará «${note.title}» y su archivo de tu cuenta. Esta acción no se puede deshacer.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Eliminar'),
        ),
      ],
    ),
  );
  if (confirmed == true) state.deleteNote(note.id);
}

Future<String?> _resolveNoteUrl(String? fileReference) async {
  if (fileReference == null || fileReference.isEmpty) return null;
  if (fileReference.startsWith('http://') ||
      fileReference.startsWith('https://')) {
    return fileReference;
  }
  try {
    return await CloudSyncService.createSignedUrl(fileReference);
  } catch (error) {
    debugPrint('No se pudo preparar el adjunto: $error');
    return null;
  }
}

Future<String?> showScheduleProfileEditor(BuildContext context) {
  return _textDialog(
    context,
    'Nuevo horario',
    'Ej: Horario del segundo semestre',
  );
}

Future<bool> confirmDeleteScheduleProfile(
  BuildContext context, {
  required String profileName,
  required int classCount,
}) async {
  final classMessage = switch (classCount) {
    0 => 'No tiene clases guardadas.',
    1 => 'También se eliminará su clase guardada.',
    _ => 'También se eliminarán sus $classCount clases guardadas.',
  };
  return await _ownedDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Eliminar horario'),
          content: Text(
            'Se eliminará «$profileName». $classMessage Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Eliminar'),
            ),
          ],
        ),
      ) ??
      false;
}

Future<void> showScheduleEditor(
  BuildContext context,
  AppState state, {
  ScheduleEntry? entry,
  String? profileId,
  int? initialDay,
  TimeOfDay? initialStart,
  TimeOfDay? initialEnd,
}) async {
  if (state.subjects.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Crea una asignatura antes de añadir una clase.'),
      ),
    );
    return;
  }
  TimeOfDay parseTime(String? value, TimeOfDay fallback) {
    final parts = value?.split(':');
    if (parts == null || parts.length != 2) return fallback;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    return TimeOfDay(
      hour: (hour ?? fallback.hour).clamp(0, 23).toInt(),
      minute: (minute ?? fallback.minute).clamp(0, 59).toInt(),
    );
  }

  var day = (entry?.dayOfWeek ?? initialDay ?? 1).clamp(1, 7).toInt();
  final requestedSubjectId = entry?.subjectId ?? state.subjects.first.id;
  var subjectId = state.subjects.any((item) => item.id == requestedSubjectId)
      ? requestedSubjectId
      : state.subjects.first.id;
  final requestedProfileId = entry?.profileId ?? profileId;
  var selectedProfileId =
      state.profiles.any((item) => item.id == requestedProfileId)
      ? requestedProfileId!
      : state.profiles.first.id;
  TimeOfDay start = parseTime(
    entry?.startTime,
    initialStart ?? const TimeOfDay(hour: 8, minute: 0),
  );
  TimeOfDay end = parseTime(
    entry?.endTime,
    initialEnd ?? const TimeOfDay(hour: 9, minute: 0),
  );
  var note = entry?.note ?? '';
  final noteController = TextEditingController(text: note);
  await _ownedDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(entry == null ? 'Añadir clase' : 'Editar clase'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: selectedProfileId,
              decoration: const InputDecoration(labelText: 'Horario'),
              items: state.profiles
                  .map(
                    (profile) => DropdownMenuItem(
                      value: profile.id,
                      child: Text(profile.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(
                () => selectedProfileId = value ?? selectedProfileId,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: day,
              decoration: const InputDecoration(labelText: 'Día'),
              items: List.generate(
                7,
                (index) => DropdownMenuItem(
                  value: index + 1,
                  child: Text(_dayName(index + 1)),
                ),
              ).toList(),
              onChanged: (value) => setState(() => day = value ?? day),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: subjectId,
              decoration: const InputDecoration(labelText: 'Asignatura'),
              items: state.subjects
                  .map(
                    (subject) => DropdownMenuItem(
                      value: subject.id,
                      child: Text(subject.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) =>
                  setState(() => subjectId = value ?? subjectId),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: start,
                      );
                      if (picked != null && context.mounted) {
                        setState(() => start = picked);
                      }
                    },
                    child: Text('Desde ${start.format(context)}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: end,
                      );
                      if (picked != null && context.mounted) {
                        setState(() => end = picked);
                      }
                    },
                    child: Text('Hasta ${end.format(context)}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              onChanged: (value) => note = value,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Nota opcional',
                hintText: 'Ej: Llevar calculadora',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final startMinutes = start.hour * 60 + start.minute;
              final endMinutes = end.hour * 60 + end.minute;
              if (endMinutes <= startMinutes) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'La hora de fin debe ser posterior al inicio.',
                    ),
                  ),
                );
                return;
              }
              final saved = ScheduleEntry(
                id:
                    entry?.id ??
                    DateTime.now().microsecondsSinceEpoch.toString(),
                profileId: selectedProfileId,
                dayOfWeek: day,
                startTime: _time(start),
                endTime: _time(end),
                subjectId: subjectId,
                note: note.trim().isEmpty ? null : note.trim(),
              );
              if (entry == null) {
                state.addScheduleEntry(saved);
              } else {
                state.updateScheduleEntry(saved);
              }
              Navigator.pop(dialogContext);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    ),
  );
  noteController.dispose();
}

Future<String?> _textDialog(
  BuildContext context,
  String title,
  String hint,
) async {
  final controller = TextEditingController();
  final result = await _ownedDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(hintText: hint),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, controller.text),
          child: const Text('Añadir'),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}

String _time(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

String _dayName(int day) => const [
  '',
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
][day.clamp(1, 7)];

// A pop result arrives before Flutter removes the closing dialog. Keep its
// controllers alive until the route animation has finished.
Future<T?> _ownedDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final route = DialogRoute<T>(
    context: context,
    builder: builder,
    barrierDismissible: barrierDismissible,
    themes: InheritedTheme.capture(from: context, to: navigator.context),
  );
  final result = await navigator.push(route);
  await route.completed;
  return result;
}
