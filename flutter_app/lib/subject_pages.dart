import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'app_state.dart';
import 'brand.dart';
import 'dialogs.dart';
import 'models.dart';
import 'widgets.dart';

class SubjectsPage extends StatelessWidget {
  const SubjectsPage({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final subjects = state.subjects;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Asignaturas',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cada materia tiene su propio espacio de estudio.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Nueva asignatura',
                  onPressed: () => _addSubject(context),
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (subjects.isEmpty)
              EmptyState(
                icon: Icons.menu_book_outlined,
                title: 'Tu lista está vacía',
                message:
                    'Añade una asignatura para organizar tus exámenes, notas y tiempo de estudio.',
                action: 'Añadir asignatura',
                onAction: () => _addSubject(context),
                mascotPose: MascotPose.encourage,
              )
            else
              ...subjects.map(
                (subject) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SubjectCard(
                    state: state,
                    subject: subject,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => SubjectDetailPage(
                          state: state,
                          subjectId: subject.id,
                        ),
                      ),
                    ),
                    onEdit: () => _editSubject(context, subject),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _addSubject(BuildContext context) async {
    final subject = await showSubjectForm(context);
    if (subject != null) state.addSubject(subject);
  }

  Future<void> _editSubject(BuildContext context, Subject subject) async {
    final edited = await showSubjectForm(context, subject: subject);
    if (edited != null) state.updateSubject(edited);
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({
    required this.state,
    required this.subject,
    required this.onTap,
    required this.onEdit,
  });

  final AppState state;
  final Subject subject;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final color = colorFromHex(subject.color);
    final exams = state.examsForSubject(subject.id);
    final notes = state.notesForSubject(subject.id);
    final minutes = state.studyMinutesForSubject(subject.id);
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(StudiaryBrand.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(StudiaryBrand.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .22),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.menu_book_rounded, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subject.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (subject.classroom != null &&
                            subject.classroom!.trim().isNotEmpty)
                          Text(
                            subject.classroom!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Editar asignatura',
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SubjectMetric(
                    icon: Icons.event_note_outlined,
                    value: '${exams.length}',
                    label: exams.length == 1 ? 'examen' : 'exámenes',
                  ),
                  _SubjectMetric(
                    icon: Icons.timer_outlined,
                    value: _formatMinutes(minutes),
                    label: 'de estudio',
                  ),
                  _SubjectMetric(
                    icon: Icons.sticky_note_2_outlined,
                    value: '${notes.length}',
                    label: notes.length == 1 ? 'apunte' : 'apuntes',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubjectMetric extends StatelessWidget {
  const _SubjectMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: .65),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: scheme.primary),
          const SizedBox(width: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class SubjectDetailPage extends StatelessWidget {
  const SubjectDetailPage({
    super.key,
    required this.state,
    required this.subjectId,
  });

  final AppState state;
  final String subjectId;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final subject = state.subjects
            .where((item) => item.id == subjectId)
            .firstOrNull;
        if (subject == null) {
          return const Scaffold(
            body: Center(child: Text('Esta asignatura ya no existe.')),
          );
        }
        final color = colorFromHex(subject.color);
        final exams = state.examsForSubject(subject.id);
        final notes = state.notesForSubject(subject.id);
        final studyMinutes = state.studyMinutesForSubject(subject.id);
        return Scaffold(
          appBar: AppBar(
            title: Text(subject.name),
            actions: [
              IconButton(
                tooltip: 'Editar asignatura',
                onPressed: () async {
                  final edited = await showSubjectForm(
                    context,
                    subject: subject,
                  );
                  if (edited != null) state.updateSubject(edited);
                },
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              _SubjectHero(
                subject: subject,
                color: color,
                studyMinutes: studyMinutes,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _DetailMetric(
                      icon: Icons.event_note_rounded,
                      value: '${exams.length}',
                      label: 'Exámenes',
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DetailMetric(
                      icon: Icons.grade_rounded,
                      value: !exams.any((exam) => exam.grade != null)
                          ? 'Sin nota'
                          : state
                                .averageGradeForSubject(subject.id)
                                .toStringAsFixed(1),
                      label: 'Media',
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DetailMetric(
                      icon: Icons.timer_rounded,
                      value: _formatMinutes(studyMinutes),
                      label: 'Estudio',
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _DetailSectionHeading(
                title: 'Exámenes y calificaciones',
                action: 'Añadir',
                onAction: () => showEventEditor(
                  context,
                  state,
                  initialType: EventType.examen,
                  initialSubjectId: subject.id,
                ),
              ),
              if (exams.isEmpty)
                EmptyState(
                  icon: Icons.event_available_outlined,
                  title: 'Sin exámenes todavía',
                  message:
                      'Añade una fecha y podrás registrar su calificación aquí.',
                  action: 'Añadir examen',
                  onAction: () => showEventEditor(
                    context,
                    state,
                    initialType: EventType.examen,
                    initialSubjectId: subject.id,
                  ),
                  mascotPose: MascotPose.reminder,
                )
              else
                SoftCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Column(
                    children: exams
                        .map(
                          (exam) => _ExamRow(
                            exam: exam,
                            color: color,
                            onTap: () => showEventDetails(context, state, exam),
                          ),
                        )
                        .toList(),
                  ),
                ),
              const SizedBox(height: 24),
              _DetailSectionHeading(
                title: 'Apuntes de ${subject.name}',
                action: 'Añadir',
                onAction: () => showNoteEditorForSubject(
                  context,
                  state,
                  subjectId: subject.id,
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: () =>
                          showNotebookEditor(context, state, subject: subject),
                      icon: const Icon(Icons.auto_stories_rounded),
                      label: const Text('Modo cuaderno'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filledTonal(
                    tooltip: 'Añadir archivo, vídeo o enlace',
                    onPressed: () => showNoteEditorForSubject(
                      context,
                      state,
                      subjectId: subject.id,
                    ),
                    icon: const Icon(Icons.attach_file_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (notes.isEmpty)
                EmptyState(
                  icon: Icons.sticky_note_2_outlined,
                  title: 'Tu cuaderno está listo',
                  message:
                      'Crea una nota o guarda un archivo, vídeo, foto o enlace para esta asignatura.',
                  action: 'Crear apunte',
                  onAction: () =>
                      showNotebookEditor(context, state, subject: subject),
                  mascotPose: MascotPose.encourage,
                )
              else
                SoftCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Column(
                    children: notes
                        .map(
                          (note) => _SubjectNoteRow(
                            note: note,
                            onOpen: () =>
                                showNotePreview(context, note, state: state),
                            onDelete: () =>
                                confirmDeleteNote(context, state, note),
                          ),
                        )
                        .toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SubjectHero extends StatelessWidget {
  const _SubjectHero({
    required this.subject,
    required this.color,
    required this.studyMinutes,
  });

  final Subject subject;
  final Color color;
  final int studyMinutes;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      color: color.withValues(alpha: .17),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Row(
        children: [
          const StudiaryMascot(size: 80, pose: MascotPose.focus),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject.name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  subject.classroom?.trim().isNotEmpty == true
                      ? subject.classroom!
                      : 'Tu espacio de estudio',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${_formatMinutes(studyMinutes)} de estudio acumulado',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailMetric extends StatelessWidget {
  const _DetailMetric({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 9),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _DetailSectionHeading extends StatelessWidget {
  const _DetailSectionHeading({
    required this.title,
    required this.action,
    required this.onAction,
  });

  final String title;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        TextButton(onPressed: onAction, child: Text(action)),
      ],
    );
  }
}

class _ExamRow extends StatelessWidget {
  const _ExamRow({
    required this.exam,
    required this.color,
    required this.onTap,
  });

  final PlannerEvent exam;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: .18),
        foregroundColor: color,
        child: const Icon(Icons.event_note_rounded),
      ),
      title: Text(
        exam.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        DateFormat('EEEE, d MMMM', 'es_ES').format(exam.startDate),
      ),
      trailing: Text(
        exam.grade == null ? 'Sin nota' : exam.grade!.toStringAsFixed(1),
        style: TextStyle(color: color, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _SubjectNoteRow extends StatelessWidget {
  const _SubjectNoteRow({
    required this.note,
    required this.onOpen,
    required this.onDelete,
  });

  final PlannerNote note;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final canOpen =
        note.type == NoteType.text ||
        note.type == NoteType.link ||
        note.fileUrl != null ||
        note.fileDataUri != null;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: canOpen ? onOpen : null,
      leading: Icon(_noteIcon(note.type)),
      title: Text(
        note.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        _noteSubtitle(note),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        tooltip: 'Eliminar apunte',
        onPressed: onDelete,
        icon: const Icon(Icons.delete_outline_rounded),
      ),
    );
  }
}

IconData _noteIcon(NoteType type) => switch (type) {
  NoteType.text => Icons.notes_rounded,
  NoteType.pdf || NoteType.file => Icons.picture_as_pdf_rounded,
  NoteType.image => Icons.image_outlined,
  NoteType.video => Icons.video_library_outlined,
  NoteType.link => Icons.link_rounded,
};

String _noteSubtitle(PlannerNote note) {
  if (note.type == NoteType.text) return note.content;
  if (note.type == NoteType.link) return note.content;
  return note.fileName ??
      switch (note.type) {
        NoteType.pdf || NoteType.file => 'Documento PDF',
        NoteType.image => 'Fotografía',
        NoteType.video => 'Vídeo',
        NoteType.text || NoteType.link => 'Apunte',
      };
}

String _formatMinutes(int minutes) {
  if (minutes < 60) return '$minutes min';
  final hours = minutes ~/ 60;
  final remainder = minutes % 60;
  return remainder == 0 ? '$hours h' : '$hours h $remainder min';
}
