import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_state.dart';
import 'models.dart';

class NotebookPage extends StatefulWidget {
  const NotebookPage({
    super.key,
    required this.state,
    required this.subjectId,
    this.note,
  });
  final AppState state;
  final String subjectId;
  final PlannerNote? note;
  @override
  State<NotebookPage> createState() => _NotebookPageState();
}

class _NotebookPageState extends State<NotebookPage>
    with WidgetsBindingObserver {
  late final title = TextEditingController(text: widget.note?.title ?? '');
  late final content = TextEditingController(text: widget.note?.content ?? '');
  final contentFocus = FocusNode();
  late final String? owner = widget.state.user?.id;
  late DateTime? originalUpdatedAt = widget.note?.updatedAt;
  late String subjectId = widget.subjectId;
  SharedPreferences? prefs;
  Timer? debounce;
  Future<void> writes = Future.value();
  bool loading = true, preview = false, saving = false, saved = false;
  String status = 'Cargando cuaderno…';
  String get draftKey =>
      'studiary-draft-$owner-${widget.note?.id ?? widget.subjectId}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_load());
  }

  Future<void> _load() async {
    prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final raw = prefs!.getString(draftKey);
    try {
      if (raw != null) {
        final draft = jsonDecode(raw) as Map;
        title.text = draft['title'] as String;
        content.text = draft['content'] as String;
        subjectId = draft['subjectId'] as String;
        originalUpdatedAt = DateTime.tryParse(draft['baseUpdatedAt']?.toString() ?? '');
        status = 'Borrador recuperado en este dispositivo';
      } else {
        status = 'El borrador se guarda en este dispositivo';
      }
    } catch (_) {
      status = 'No se pudo recuperar el borrador anterior';
    }
    title.addListener(_changed);
    content.addListener(_changed);
    setState(() => loading = false);
  }

  void _changed() {
    if (saved) return;
    setState(() => status = 'Guardando borrador…');
    debounce?.cancel();
    debounce = Timer(
      const Duration(milliseconds: 450),
      () => unawaited(_draft()),
    );
  }

  Future<void> _draft() {
    if (saved || loading || owner == null) return Future.value();
    final encoded = jsonEncode({
      'title': title.text,
      'content': content.text,
      'subjectId': subjectId,
      'baseUpdatedAt': originalUpdatedAt?.toIso8601String(),
    });
    writes = writes.catchError((Object _) {}).then((_) async {
      try {
        await prefs!.setString(draftKey, encoded);
        if (mounted) {
          setState(() => status = 'Borrador guardado en este dispositivo');
        }
      } catch (_) {
        if (mounted) {
          setState(
            () => status = 'No se pudo guardar el borrador. Libera espacio.',
          );
        }
      }
    });
    return writes;
  }

  void _format(String before, [String after = '']) {
    final selected = content.selection;
    final start = selected.isValid ? selected.start : content.text.length;
    final end = selected.isValid ? selected.end : start;
    final replacement = '$before${content.text.substring(start, end)}$after';
    content.value = TextEditingValue(
      text: content.text.replaceRange(start, end, replacement),
      selection: TextSelection(
        baseOffset: start + before.length,
        extentOffset: end + before.length,
      ),
    );
    contentFocus.requestFocus();
  }

  Future<void> _save() async {
    if (title.text.trim().isEmpty || content.text.trim().isEmpty) {
      _message('Escribe un título y el contenido del apunte.');
      return;
    }
    if (widget.state.user?.id != owner ||
        !widget.state.subjects.any((s) => s.id == subjectId)) {
      _message(
        'La cuenta o la asignatura ha cambiado. Tu borrador sigue guardado.',
      );
      return;
    }
    setState(() => saving = true);
    debounce?.cancel();
    await _draft();
    final current = widget.state.notes
        .where((n) => n.id == widget.note?.id)
        .firstOrNull;
    // A concurrent edit is preserved. Save this version as a separate page.
    final canUpdate = current != null && current.updatedAt == originalUpdatedAt;
    final note = PlannerNote(
      id: canUpdate
          ? current.id
          : DateTime.now().microsecondsSinceEpoch.toString(),
      title: title.text.trim(),
      content: content.text,
      subjectId: subjectId,
      createdAt: canUpdate ? current.createdAt : null,
    );
    try {
      if (canUpdate) {
        widget.state.updateNote(note);
      } else {
        widget.state.addNote(note);
      }
      await widget.state.saveLocally();
      saved = true;
      await writes;
      await prefs?.remove(draftKey);
      if (mounted) {
        _message(
          widget.note != null && !canUpdate
              ? 'Guardado como copia para conservar la otra versión.'
              : 'Apunte guardado. Se sincronizará con tu cuenta.',
        );
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        setState(() => saving = false);
        _message('No se pudo guardar. Conservamos el borrador.');
      }
    }
  }

  void _message(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      debounce?.cancel();
      unawaited(_draft());
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuaderno'),
        actions: [
          IconButton(
            tooltip: preview ? 'Editar' : 'Vista previa',
            onPressed: loading
                ? null
                : () => setState(() => preview = !preview),
            icon: Icon(
              preview ? Icons.edit_outlined : Icons.chrome_reader_mode_outlined,
            ),
          ),
          TextButton(
            onPressed: saving || loading ? null : _save,
            child: Text(saving ? 'Guardando…' : 'Guardar'),
          ),
        ],
      ),
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: Column(
                      children: [
                        TextField(
                          controller: title,
                          maxLength: 120,
                          textCapitalization: TextCapitalization.sentences,
                          style: Theme.of(context).textTheme.headlineSmall,
                          decoration: const InputDecoration(
                            hintText: 'Título del apunte',
                            border: InputBorder.none,
                            counterText: '',
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.cloud_outlined,
                              size: 16,
                              color: scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                status,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!preview)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: 'Título',
                            onPressed: () => _format('\n## '),
                            icon: const Icon(Icons.title),
                          ),
                          IconButton(
                            tooltip: 'Negrita',
                            onPressed: () => _format('**', '**'),
                            icon: const Icon(Icons.format_bold),
                          ),
                          IconButton(
                            tooltip: 'Cursiva',
                            onPressed: () => _format('*', '*'),
                            icon: const Icon(Icons.format_italic),
                          ),
                          IconButton(
                            tooltip: 'Lista',
                            onPressed: () => _format('\n- '),
                            icon: const Icon(Icons.format_list_bulleted),
                          ),
                          IconButton(
                            tooltip: 'Lista de tareas',
                            onPressed: () => _format('\n- [ ] '),
                            icon: const Icon(Icons.checklist),
                          ),
                          IconButton(
                            tooltip: 'Cita',
                            onPressed: () => _format('\n> '),
                            icon: const Icon(Icons.format_quote),
                          ),
                        ],
                      ),
                    ),
                  const Divider(height: 1),
                  Expanded(
                    child: preview
                        ? NoteMarkdown(data: content.text)
                        : TextField(
                            controller: content,
                            focusNode: contentFocus,
                            expands: true,
                            minLines: null,
                            maxLines: null,
                            textAlignVertical: TextAlignVertical.top,
                            textCapitalization: TextCapitalization.sentences,
                            keyboardType: TextInputType.multiline,
                            maxLength: 200000,
                            style: const TextStyle(fontSize: 17, height: 1.75),
                            decoration: const InputDecoration(
                              hintText:
                                  'Empieza por una idea…\n\nPuedes usar títulos, listas y negritas.',
                              contentPadding: EdgeInsets.all(22),
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              counterText: '',
                            ),
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  void dispose() {
    debounce?.cancel();
    unawaited(_draft());
    WidgetsBinding.instance.removeObserver(this);
    title.dispose();
    content.dispose();
    contentFocus.dispose();
    super.dispose();
  }
}

class NoteMarkdown extends StatelessWidget {
  const NoteMarkdown({super.key, required this.data});
  final String data;
  @override
  Widget build(BuildContext context) => Markdown(
    data: data,
    selectable: true,
    padding: const EdgeInsets.all(22),
    // Notes must not read arbitrary local files or silently load tracking pixels.
    imageBuilder: (uri, title, alt) =>
        Text(alt ?? 'Imagen: añade el archivo a la asignatura'),
    onTapLink: (_, href, _) async {
      final uri = Uri.tryParse(href ?? '');
      if (uri == null ||
          !{'https', 'http'}.contains(uri.scheme) ||
          uri.host.isEmpty) {
        return;
      }
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        /* Keep the note open. */
      }
    },
  );
}
