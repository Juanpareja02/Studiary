import 'package:flutter/material.dart';

import 'brand.dart';
import 'models.dart';
import 'widgets.dart';

/// Encabezado compartido para las dos vistas semanales.
///
/// La referencia visual se traduce a una papelería cálida usando el patrón
/// oficial de Studiary como textura. El contenido sigue usando Material 3
/// para mantener contraste, semántica y tamaños táctiles accesibles.
class WeeklyPaperHeader extends StatelessWidget {
  const WeeklyPaperHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.calendar_month_rounded,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(StudiaryBrand.cardRadius),
      child: Container(
        constraints: const BoxConstraints(minHeight: 112),
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: .7),
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: isDark ? .05 : .16,
                child: Image.asset(BrandAssets.pattern, fit: BoxFit.cover),
              ),
            ),
            Positioned(
              top: -12,
              right: 18,
              child: Icon(
                Icons.local_florist_outlined,
                size: 76,
                color: StudiaryBrand.coral.withValues(alpha: .22),
              ),
            ),
            Positioned(
              bottom: -16,
              left: 92,
              child: Icon(
                Icons.auto_awesome_outlined,
                size: 64,
                color: StudiaryBrand.lavender.withValues(alpha: .22),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: StudiaryBrand.coral.withValues(alpha: .3),
                      borderRadius: BorderRadius.circular(
                        StudiaryBrand.controlRadius,
                      ),
                    ),
                    child: Icon(icon, color: scheme.onSurface, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -.2,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: scheme.onSurfaceVariant,
                                height: 1.25,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SchoolScheduleHeader extends StatelessWidget {
  const SchoolScheduleHeader({super.key, required this.subtitle});

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(StudiaryBrand.cardRadius),
      child: Container(
        constraints: const BoxConstraints(minHeight: 142),
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            const Color(0xFFFFF8F1).withValues(
              alpha: Theme.of(context).brightness == Brightness.dark ? .08 : .7,
            ),
            scheme.surface,
          ),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: .7),
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final title = Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Horario escolar',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            );
            final leftIcons = _SchoolIconCluster(
              icons: const [
                Icons.straighten_rounded,
                Icons.calculate_rounded,
                Icons.edit_rounded,
              ],
              colors: const [
                Color(0xFF9ED6E5),
                Color(0xFFFFD35C),
                Color(0xFFE36B8C),
              ],
            );
            final rightIcons = _SchoolIconCluster(
              icons: const [
                Icons.backpack_rounded,
                Icons.apple_rounded,
                Icons.menu_book_rounded,
              ],
              colors: const [
                Color(0xFFB9DCD2),
                Color(0xFFE96B93),
                Color(0xFF8A63B8),
              ],
            );
            if (constraints.maxWidth < 470) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    title,
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        leftIcons,
                        const SizedBox(width: 10),
                        rightIcons,
                      ],
                    ),
                  ],
                ),
              );
            }
            return Stack(
              alignment: Alignment.center,
              children: [
                Positioned(left: 18, child: leftIcons),
                Positioned(right: 18, child: rightIcons),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 150,
                    vertical: 28,
                  ),
                  child: title,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SchoolIconCluster extends StatelessWidget {
  const _SchoolIconCluster({required this.icons, required this.colors});

  final List<IconData> icons;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < icons.length; index++)
          Padding(
            padding: EdgeInsets.only(right: index == icons.length - 1 ? 0 : 6),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colors[index].withValues(alpha: .72),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icons[index],
                size: 21,
                color: const Color(0xFF5B454E),
              ),
            ),
          ),
      ],
    );
  }
}

class WeeklyScheduleBoard extends StatefulWidget {
  const WeeklyScheduleBoard({
    super.key,
    required this.entries,
    required this.subjects,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    this.showHeader = true,
  });

  final List<ScheduleEntry> entries;
  final List<Subject> subjects;
  final void Function(int day, int hour) onAdd;
  final ValueChanged<ScheduleEntry> onEdit;
  final ValueChanged<String> onDelete;
  final bool showHeader;

  @override
  State<WeeklyScheduleBoard> createState() => _WeeklyScheduleBoardState();
}

class _WeeklyScheduleBoardState extends State<WeeklyScheduleBoard> {
  int selectedDay = DateTime.now().weekday <= 6 ? DateTime.now().weekday : 1;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showHeader) ...[
          SchoolScheduleHeader(
            subtitle: widget.entries.isEmpty
                ? 'Organiza tus clases de lunes a sábado.'
                : '${widget.entries.length} ${widget.entries.length == 1 ? 'clase programada' : 'clases programadas'}',
          ),
          const SizedBox(height: 12),
        ],
        SoftCard(
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
          color: _paperTint(context),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Horario de clases',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Toca una celda vacía para añadir una clase.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Añadir clase',
                onPressed: () => widget.onAdd(selectedDay, 8),
                style: IconButton.styleFrom(
                  backgroundColor: StudiaryBrand.coral.withValues(alpha: .3),
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                ),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SchoolWeekTable(
          entries: widget.entries,
          subjects: widget.subjects,
          selectedDay: selectedDay,
          onSelectDay: (day) => setState(() => selectedDay = day),
          onAdd: widget.onAdd,
          onEdit: widget.onEdit,
          onDelete: widget.onDelete,
        ),
        const SizedBox(height: 12),
        _SelectedScheduleDay(
          day: selectedDay,
          entries: _entriesForDay(selectedDay),
          subjects: widget.subjects,
          onAdd: widget.onAdd,
          onEdit: widget.onEdit,
          onDelete: widget.onDelete,
        ),
      ],
    );
  }

  List<ScheduleEntry> _entriesForDay(int day) =>
      widget.entries.where((entry) => entry.dayOfWeek == day).toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
}

class _SchoolWeekTable extends StatelessWidget {
  const _SchoolWeekTable({
    required this.entries,
    required this.subjects,
    required this.selectedDay,
    required this.onSelectDay,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final List<ScheduleEntry> entries;
  final List<Subject> subjects;
  final int selectedDay;
  final ValueChanged<int> onSelectDay;
  final void Function(int day, int hour) onAdd;
  final ValueChanged<ScheduleEntry> onEdit;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    final days = entries.any((entry) => entry.dayOfWeek == 7)
        ? const [1, 2, 3, 4, 5, 6, 7]
        : const [1, 2, 3, 4, 5, 6];
    final firstHour = _gridFirstHour(entries);
    final lastHour = _gridLastHour(entries, firstHour);
    return _GridPanel(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: _SchoolWeekGrid(
          days: days,
          firstHour: firstHour,
          lastHour: lastHour,
          entries: entries,
          subjects: subjects,
          selectedDay: selectedDay,
          onSelectDay: onSelectDay,
          onAdd: onAdd,
          onEdit: onEdit,
          onDelete: onDelete,
        ),
      ),
    );
  }
}

class _SchoolWeekGrid extends StatelessWidget {
  const _SchoolWeekGrid({
    required this.days,
    required this.firstHour,
    required this.lastHour,
    required this.entries,
    required this.subjects,
    required this.selectedDay,
    required this.onSelectDay,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  static const _timeWidth = 62.0;
  static const _dayWidth = 136.0;
  static const _headerHeight = 64.0;
  static const _rowHeight = 70.0;

  final List<int> days;
  final int firstHour;
  final int lastHour;
  final List<ScheduleEntry> entries;
  final List<Subject> subjects;
  final int selectedDay;
  final ValueChanged<int> onSelectDay;
  final void Function(int day, int hour) onAdd;
  final ValueChanged<ScheduleEntry> onEdit;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: _timeWidth + (_dayWidth * days.length),
      child: Column(
        children: [
          SizedBox(
            height: _headerHeight,
            child: Row(
              children: [
                _SchoolTimeCell(
                  label: 'HORA',
                  width: _timeWidth,
                  height: _headerHeight,
                  header: true,
                ),
                for (final day in days)
                  _SchoolDayHeader(
                    day: day,
                    width: _dayWidth,
                    height: _headerHeight,
                    selected: day == selectedDay,
                    count: entries
                        .where((entry) => entry.dayOfWeek == day)
                        .length,
                    today: day == DateTime.now().weekday,
                    onTap: () => onSelectDay(day),
                  ),
              ],
            ),
          ),
          for (var hour = firstHour; hour <= lastHour; hour++)
            SizedBox(
              height: _rowHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SchoolTimeCell(
                    label: '${hour.toString().padLeft(2, '0')}:00',
                    width: _timeWidth,
                    height: _rowHeight,
                  ),
                  for (final day in days)
                    _SchoolGridCell(
                      day: day,
                      hour: hour,
                      width: _dayWidth,
                      height: _rowHeight,
                      selected: day == selectedDay,
                      entries: entries
                          .where(
                            (entry) =>
                                entry.dayOfWeek == day &&
                                _timeHour(entry.startTime) == hour,
                          )
                          .toList(),
                      subjects: subjects,
                      onAdd: onAdd,
                      onEdit: onEdit,
                      onDelete: onDelete,
                    ),
                ],
              ),
            ),
          Container(height: 8, color: scheme.surface),
        ],
      ),
    );
  }
}

class _SchoolTimeCell extends StatelessWidget {
  const _SchoolTimeCell({
    required this.label,
    required this.width,
    required this.height,
    this.header = false,
  });

  final String label;
  final double width;
  final double height;
  final bool header;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: header
            ? scheme.surfaceContainerHighest.withValues(alpha: .78)
            : scheme.surfaceContainerHighest.withValues(alpha: .34),
        border: Border(
          right: BorderSide(color: scheme.outline.withValues(alpha: .35)),
          bottom: BorderSide(color: scheme.outline.withValues(alpha: .28)),
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          maxLines: 1,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w900,
            letterSpacing: header ? .7 : 0,
          ),
        ),
      ),
    );
  }
}

class _SchoolDayHeader extends StatelessWidget {
  const _SchoolDayHeader({
    required this.day,
    required this.width,
    required this.height,
    required this.selected,
    required this.count,
    required this.today,
    required this.onTap,
  });

  final int day;
  final double width;
  final double height;
  final bool selected;
  final int count;
  final bool today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: '${_dayNames[day - 1]}, $count clases',
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: width,
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(
            color: weeklyDayTint(
              context,
              day,
              header: true,
              selected: selected,
            ),
            border: Border(
              right: BorderSide(color: scheme.outline.withValues(alpha: .35)),
              bottom: BorderSide(color: scheme.outline.withValues(alpha: .28)),
              top: BorderSide(
                color: today ? StudiaryBrand.coral : Colors.transparent,
                width: today ? 3 : 0,
              ),
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _dayNames[day - 1].toUpperCase(),
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$count ${count == 1 ? 'clase' : 'clases'}',
                  maxLines: 1,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SchoolGridCell extends StatelessWidget {
  const _SchoolGridCell({
    required this.day,
    required this.hour,
    required this.width,
    required this.height,
    required this.selected,
    required this.entries,
    required this.subjects,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final int day;
  final int hour;
  final double width;
  final double height;
  final bool selected;
  final List<ScheduleEntry> entries;
  final List<Subject> subjects;
  final void Function(int day, int hour) onAdd;
  final ValueChanged<ScheduleEntry> onEdit;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final entry = entries.firstOrNull;
    final label = entry == null
        ? '${_dayNames[day - 1]}, ${hour.toString().padLeft(2, '0')}:00, añadir clase'
        : '${_dayNames[day - 1]}, ${entry.startTime}, ${_subjectFor(subjects, entry)?.name ?? 'Asignatura'}';
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: entry == null ? () => onAdd(day, hour) : () => onEdit(entry),
        child: Container(
          width: width,
          height: height,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: weeklyDayTint(context, day, selected: selected),
            border: Border(
              right: BorderSide(color: scheme.outline.withValues(alpha: .3)),
              bottom: BorderSide(color: scheme.outline.withValues(alpha: .3)),
            ),
          ),
          child: entry == null
              ? Icon(
                  Icons.add_rounded,
                  size: 17,
                  color: scheme.outline.withValues(alpha: .62),
                )
              : _SchoolClassTile(
                  entry: entry,
                  subject: _subjectFor(subjects, entry),
                  extraCount: entries.length - 1,
                  onTap: () => onEdit(entry),
                  onDelete: () => onDelete(entry.id),
                ),
        ),
      ),
    );
  }
}

class _SchoolClassTile extends StatelessWidget {
  const _SchoolClassTile({
    required this.entry,
    required this.subject,
    required this.extraCount,
    required this.onTap,
    required this.onDelete,
  });

  final ScheduleEntry entry;
  final Subject? subject;
  final int extraCount;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = subject == null
        ? scheme.primary
        : colorFromHex(subject!.color);
    return Material(
      color: accent.withValues(alpha: .2),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 42,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject?.name ?? 'Asignatura',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${entry.startTime} - ${entry.endTime}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (extraCount > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 3),
                  child: Text(
                    '+$extraCount',
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 10,
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedScheduleDay extends StatelessWidget {
  const _SelectedScheduleDay({
    required this.day,
    required this.entries,
    required this.subjects,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final int day;
  final List<ScheduleEntry> entries;
  final List<Subject> subjects;
  final void Function(int day, int hour) onAdd;
  final ValueChanged<ScheduleEntry> onEdit;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _dayNames[day - 1],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${entries.length} ${entries.length == 1 ? 'clase' : 'clases'}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 6, 5),
              child: Text(
                'Este día está libre. Pulsa una celda con + para añadir una clase.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            )
          else
            ...entries.map(
              (entry) => _ScheduleDetailTile(
                entry: entry,
                subject: _subjectFor(subjects, entry),
                onEdit: () => onEdit(entry),
                onDelete: () => onDelete(entry.id),
              ),
            ),
          if (entries.isEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => onAdd(day, 8),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Añadir clase'),
              ),
            ),
        ],
      ),
    );
  }
}

class _ScheduleDetailTile extends StatelessWidget {
  const _ScheduleDetailTile({
    required this.entry,
    required this.subject,
    required this.onEdit,
    required this.onDelete,
  });

  final ScheduleEntry entry;
  final Subject? subject;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final accent = subject == null
        ? Theme.of(context).colorScheme.primary
        : colorFromHex(subject!.color);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Container(
        width: 4,
        height: 34,
        decoration: BoxDecoration(
          color: accent,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      title: Text(
        subject?.name ?? 'Asignatura',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        '${entry.startTime} - ${entry.endTime}${entry.note == null || entry.note!.trim().isEmpty ? '' : ' · ${entry.note}'}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: onEdit,
      trailing: PopupMenuButton<String>(
        tooltip: 'Opciones de ${subject?.name ?? 'clase'}',
        onSelected: (value) {
          if (value == 'edit') onEdit();
          if (value == 'delete') onDelete();
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'edit', child: Text('Editar')),
          PopupMenuItem(value: 'delete', child: Text('Eliminar')),
        ],
      ),
    );
  }
}

class _GridPanel extends StatelessWidget {
  const _GridPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(StudiaryBrand.cardRadius),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: .8),
          ),
        ),
        child: child,
      ),
    );
  }
}

class _GridTimeLabel extends StatelessWidget {
  const _GridTimeLabel({
    required this.label,
    required this.width,
    this.header = false,
  });

  final String label;
  final double width;
  final bool header;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: header
            ? _coralHeader(context)
            : StudiaryBrand.coral.withValues(alpha: .13),
        border: Border(
          right: BorderSide(color: scheme.outline.withValues(alpha: .32)),
          bottom: BorderSide(color: scheme.outline.withValues(alpha: .25)),
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w900,
            letterSpacing: header ? .8 : 0,
          ),
        ),
      ),
    );
  }
}

// Kept for compatibility with old persisted screenshots and test fixtures.
// ignore: unused_element
class _GridDayHeader extends StatelessWidget {
  const _GridDayHeader({
    required this.day,
    required this.width,
    required this.selected,
    required this.onTap,
  });

  final int day;
  final double width;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        width: width,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: weeklyDayTint(context, day, header: true, selected: selected),
          border: Border(
            right: BorderSide(color: scheme.outline.withValues(alpha: .32)),
            bottom: BorderSide(color: scheme.outline.withValues(alpha: .25)),
          ),
        ),
        child: Text(
          _dayNames[day - 1].toUpperCase(),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _GridSlot extends StatelessWidget {
  const _GridSlot({
    required this.day,
    required this.hour,
    required this.width,
    required this.selected,
    required this.entries,
    required this.subjects,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final int day;
  final int hour;
  final double width;
  final bool selected;
  final List<ScheduleEntry> entries;
  final List<Subject> subjects;
  final void Function(int day, int hour) onAdd;
  final ValueChanged<ScheduleEntry> onEdit;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => onAdd(day, hour),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: weeklyDayTint(context, day, selected: selected),
          border: Border(
            right: BorderSide(color: scheme.outline.withValues(alpha: .25)),
            bottom: BorderSide(color: scheme.outline.withValues(alpha: .25)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: entries
              .map(
                (entry) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: _GridScheduleBlock(
                      entry: entry,
                      subject: _subjectFor(subjects, entry),
                      onTap: () => onEdit(entry),
                      onDelete: () => onDelete(entry.id),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _TimeColumn extends StatelessWidget {
  const _TimeColumn({
    required this.day,
    required this.firstHour,
    required this.lastHour,
    required this.entries,
    required this.subjects,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final int day;
  final int firstHour;
  final int lastHour;
  final List<ScheduleEntry> entries;
  final List<Subject> subjects;
  final void Function(int day, int hour) onAdd;
  final ValueChanged<ScheduleEntry> onEdit;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        for (var hour = firstHour; hour < lastHour; hour++)
          InkWell(
            onTap: () => onAdd(day, hour),
            child: Container(
              constraints: const BoxConstraints(minHeight: 58),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: hour.isEven
                    ? scheme.surface
                    : StudiaryBrand.coral.withValues(alpha: .035),
                border: Border(
                  top: BorderSide(color: scheme.outline.withValues(alpha: .2)),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 52,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 7),
                      child: Text(
                        '${hour.toString().padLeft(2, '0')}:00',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: entries
                          .where((entry) => _timeHour(entry.startTime) == hour)
                          .map(
                            (entry) => _ScheduleBlock(
                              entry: entry,
                              subject: _subjectFor(subjects, entry),
                              onTap: () => onEdit(entry),
                              onDelete: () => onDelete(entry.id),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _GridScheduleBlock extends StatelessWidget {
  const _GridScheduleBlock({
    required this.entry,
    required this.subject,
    required this.onTap,
    required this.onDelete,
  });

  final ScheduleEntry entry;
  final Subject? subject;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = subject == null
        ? scheme.primary
        : colorFromHex(subject!.color);
    return Material(
      color: accent.withValues(alpha: .2),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 30,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      subject?.name ?? 'Asignatura',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${entry.startTime} - ${entry.endTime}',
                      style: TextStyle(
                        fontSize: 10,
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Opciones',
                padding: EdgeInsets.zero,
                iconSize: 17,
                onSelected: (value) {
                  if (value == 'edit') onTap();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Editar')),
                  PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScheduleBlock extends StatelessWidget {
  const _ScheduleBlock({
    required this.entry,
    required this.subject,
    required this.onTap,
    required this.onDelete,
  });

  final ScheduleEntry entry;
  final Subject? subject;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = subject == null
        ? scheme.primary
        : colorFromHex(subject!.color);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 190, maxWidth: 440),
      child: Material(
        color: accent.withValues(alpha: .17),
        borderRadius: BorderRadius.circular(StudiaryBrand.controlRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(StudiaryBrand.controlRadius),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 3,
                  height: 45,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject?.name ?? 'Asignatura',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${entry.startTime} - ${entry.endTime}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      if (entry.note != null && entry.note!.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            entry.note!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Opciones',
                  padding: EdgeInsets.zero,
                  iconSize: 20,
                  onSelected: (value) {
                    if (value == 'edit') onTap();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Editar')),
                    PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class WeeklyAgendaGrid extends StatelessWidget {
  const WeeklyAgendaGrid({
    super.key,
    required this.weekStart,
    required this.events,
    required this.selectedDay,
    required this.onSelectDay,
    required this.onEventTap,
    required this.onSlotTap,
  });

  final DateTime weekStart;
  final List<PlannerEvent> events;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onSelectDay;
  final ValueChanged<PlannerEvent> onEventTap;
  final ValueChanged<DateTime> onSlotTap;

  static const _timeWidth = 64.0;
  static const _dayWidth = 132.0;
  static const _rowHeight = 64.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final width = _timeWidth + (_dayWidth * 7);
    return _GridPanel(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: width,
          child: Column(
            children: [
              SizedBox(
                height: 76,
                child: Row(
                  children: [
                    _GridTimeLabel(
                      label: 'HORA',
                      width: _timeWidth,
                      header: true,
                    ),
                    for (var index = 0; index < 7; index++)
                      _AgendaDayHeader(
                        day: weekStart.add(Duration(days: index)),
                        width: _dayWidth,
                        selected: DateUtils.isSameDay(
                          weekStart.add(Duration(days: index)),
                          selectedDay,
                        ),
                        events: events
                            .where(
                              (event) =>
                                  event.isAllDay &&
                                  plannerEventOccursOn(
                                    event,
                                    weekStart.add(Duration(days: index)),
                                  ),
                            )
                            .toList(),
                        onTap: () =>
                            onSelectDay(weekStart.add(Duration(days: index))),
                        onEventTap: onEventTap,
                      ),
                  ],
                ),
              ),
              for (var hour = _firstHour; hour <= _lastHour; hour++)
                SizedBox(
                  height: _rowHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _GridTimeLabel(
                        label: '${hour.toString().padLeft(2, '0')}:00',
                        width: _timeWidth,
                      ),
                      for (var index = 0; index < 7; index++)
                        _AgendaSlot(
                          day: weekStart.add(Duration(days: index)),
                          hour: hour,
                          width: _dayWidth,
                          selected: DateUtils.isSameDay(
                            weekStart.add(Duration(days: index)),
                            selectedDay,
                          ),
                          events: events
                              .where(
                                (event) =>
                                    !event.isAllDay &&
                                    plannerEventOccursOn(
                                      event,
                                      weekStart.add(Duration(days: index)),
                                    ) &&
                                    event.startDate.hour == hour,
                              )
                              .toList(),
                          onSlotTap: () =>
                              onSlotTap(weekStart.add(Duration(days: index))),
                          onEventTap: onEventTap,
                        ),
                    ],
                  ),
                ),
              Container(height: 8, color: scheme.surface),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgendaDayHeader extends StatelessWidget {
  const _AgendaDayHeader({
    required this.day,
    required this.width,
    required this.selected,
    required this.events,
    required this.onTap,
    required this.onEventTap,
  });

  final DateTime day;
  final double width;
  final bool selected;
  final List<PlannerEvent> events;
  final VoidCallback onTap;
  final ValueChanged<PlannerEvent> onEventTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
        decoration: BoxDecoration(
          color: weeklyDayTint(
            context,
            day.weekday,
            header: true,
            selected: selected,
          ),
          border: Border(
            right: BorderSide(color: scheme.outline.withValues(alpha: .32)),
            bottom: BorderSide(color: scheme.outline.withValues(alpha: .25)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                _dayNames[day.weekday - 1].toUpperCase(),
                maxLines: 1,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '${day.day} ${_monthShort(day.month)}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (events.isNotEmpty)
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: _AgendaEventChip(
                    event: events.first,
                    extraCount: events.length - 1,
                    onTap: () => onEventTap(events.first),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AgendaSlot extends StatelessWidget {
  const _AgendaSlot({
    required this.day,
    required this.hour,
    required this.width,
    required this.selected,
    required this.events,
    required this.onSlotTap,
    required this.onEventTap,
  });

  final DateTime day;
  final int hour;
  final double width;
  final bool selected;
  final List<PlannerEvent> events;
  final VoidCallback onSlotTap;
  final ValueChanged<PlannerEvent> onEventTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final event = events.firstOrNull;
    return InkWell(
      onTap: onSlotTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: weeklyDayTint(context, day.weekday, selected: selected),
          border: Border(
            right: BorderSide(color: scheme.outline.withValues(alpha: .25)),
            bottom: BorderSide(color: scheme.outline.withValues(alpha: .25)),
          ),
        ),
        child: event == null
            ? const SizedBox.shrink()
            : _AgendaEventChip(
                event: event,
                extraCount: events.length - 1,
                onTap: () => onEventTap(event),
              ),
      ),
    );
  }
}

class _AgendaEventChip extends StatelessWidget {
  const _AgendaEventChip({
    required this.event,
    required this.onTap,
    this.extraCount = 0,
  });

  final PlannerEvent event;
  final VoidCallback onTap;
  final int extraCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = eventTypeColor(event.type);
    final time = event.isAllDay
        ? 'Todo el día'
        : '${event.startDate.hour.toString().padLeft(2, '0')}:${event.startDate.minute.toString().padLeft(2, '0')}';
    return Material(
      color: accent.withValues(alpha: .2),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 28,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      event.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      time,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (extraCount > 0)
                Text(
                  '+$extraCount',
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 9,
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w900,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _paperTint(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return Color.alphaBlend(
    StudiaryBrand.coral.withValues(alpha: .06),
    scheme.surface,
  );
}

Color weeklyPaperTint(BuildContext context) => _paperTint(context);

Color weeklyDayTint(
  BuildContext context,
  int day, {
  bool header = false,
  bool selected = false,
}) {
  const colors = [
    Color(0xFFFFE8B8),
    Color(0xFFFFCEDA),
    Color(0xFFBFE2DF),
    Color(0xFFFFE0C8),
    Color(0xFFCFE3FA),
    Color(0xFFDCD6FA),
    Color(0xFFE4D8F4),
  ];
  final scheme = Theme.of(context).colorScheme;
  final safeDay = (day - 1).clamp(0, colors.length - 1);
  final alpha = header ? (selected ? .9 : .64) : (selected ? .34 : .2);
  return Color.alphaBlend(
    colors[safeDay].withValues(alpha: alpha),
    scheme.surface,
  );
}

Color _coralHeader(BuildContext context, [double alpha = .72]) {
  final scheme = Theme.of(context).colorScheme;
  return Color.alphaBlend(
    StudiaryBrand.coral.withValues(alpha: alpha),
    scheme.surface,
  );
}

int _gridFirstHour(List<ScheduleEntry> entries) {
  if (entries.isEmpty) return 8;
  final starts = entries.map((entry) => _timeHour(entry.startTime));
  return starts.reduce((a, b) => a < b ? a : b).clamp(0, 23);
}

int _gridLastHour(List<ScheduleEntry> entries, int firstHour) {
  if (entries.isEmpty) return 14;
  final ends = entries.map((entry) => _timeHour(entry.endTime));
  final last = ends.reduce((a, b) => a > b ? a : b).clamp(0, 23);
  return last < firstHour ? firstHour : last;
}

Subject? _subjectFor(List<Subject> subjects, ScheduleEntry entry) {
  for (final subject in subjects) {
    if (subject.id == entry.subjectId) return subject;
  }
  return null;
}

int _timeHour(String value) {
  final match = RegExp(r'^(\d{1,2})').firstMatch(value.trim());
  return int.tryParse(match?.group(1) ?? '') ?? _firstHour;
}

String _monthShort(int month) {
  const months = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];
  return months[(month - 1).clamp(0, 11)];
}

const _firstHour = 7;
const _lastHour = 22;
// ignore: unused_element
const _dayLetters = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
const _dayNames = [
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];
