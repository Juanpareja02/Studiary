import 'package:collection/collection.dart';

/// Three-way merge: only local changes since the last acknowledged snapshot
/// override the server. Independent additions and removals survive device sync.
Map<String, dynamic> mergeStudyData(
  Map<String, dynamic> base,
  Map<String, dynamic> local,
  Map<String, dynamic> remote,
) {
  const collections = {
    'events',
    'subjects',
    'notes',
    'schedule',
    'profiles',
    'studySessions',
  };
  final result = Map<String, dynamic>.from(remote);
  for (final key in local.keys) {
    if (collections.contains(key)) {
      Map<String, dynamic> byId(Object? value) => {
        if (value is List)
          for (final item in value.whereType<Map>())
            if (item['id'] != null)
              item['id'].toString(): Map<String, dynamic>.from(item),
      };
      final before = byId(base[key]);
      final after = byId(local[key]);
      final combined = byId(remote[key]);
      for (final id in before.keys) {
        if (!after.containsKey(id)) combined.remove(id);
      }
      for (final entry in after.entries) {
        if (!const DeepCollectionEquality().equals(
          before[entry.key],
          entry.value,
        )) {
          combined[entry.key] = entry.value;
        }
      }
      result[key] = combined.values.toList();
    } else if (key == 'focusDays') {
      result[key] = <String>{
        ...((remote[key] as List?) ?? []).map((e) => e.toString()),
        ...((local[key] as List?) ?? []).map((e) => e.toString()),
      }.toList()..sort();
    } else if (key == 'focusMinutes') {
      // Recompute after all collections, regardless of JSON key order.
      continue;
    } else if (!const DeepCollectionEquality().equals(local[key], base[key])) {
      result[key] = local[key];
    }
  }
  if (local.containsKey('focusMinutes')) {
    const key = 'focusMinutes';
    int number(Object? value) => int.tryParse('$value') ?? 0;
    // Session IDs are idempotent, including a retry after a lost response.
    final sessions = (result['studySessions'] as List?) ?? [];
    int sessionMinutes(Object? value) => value is List
        ? value.whereType<Map>().fold(0, (sum, s) => sum + number(s['minutes']))
        : 0;
    final legacy =
        (number(remote[key]) - sessionMinutes(remote['studySessions'])).clamp(
          0,
          2147483647,
        );
    final localLegacy =
        (number(local[key]) - sessionMinutes(local['studySessions'])).clamp(
          0,
          2147483647,
        );
    result[key] =
        (legacy > localLegacy ? legacy : localLegacy) +
        sessionMinutes(sessions);
  }
  return result;
}
