import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:studiary/focus_session.dart';
import 'package:studiary/sync_merge.dart';

void main() {
  final now = DateTime.utc(2026, 9, 5, 10);
  group('Focus session', () {
    test('counts elapsed wall time after background suspension', () {
      final s = FocusSession.start('math', 25, now);
      expect(s.remaining(now.add(const Duration(minutes: 10))), 15 * 60);
      expect(s.remaining(now.add(const Duration(hours: 2))), 0);
    });
    test(
      'paused time does not count; original subject and start survive resume',
      () {
        final s = FocusSession.start('math', 25, now);
        s.pause(now.add(const Duration(minutes: 5)));
        expect(s.remaining(now.add(const Duration(hours: 1))), 20 * 60);
        s.resume(now.add(const Duration(hours: 1)));
        expect(
          s.studiedMinutes(now.add(const Duration(hours: 1, minutes: 10))),
          15,
        );
        expect(s.subjectId, 'math');
        expect(s.startedAt, now);
      },
    );
    test('restores running and paused sessions after process restart', () {
      final s = FocusSession.start('biology', 15, now);
      var restored = FocusSession.fromMap(
        jsonDecode(jsonEncode(s.toMap())) as Map<String, dynamic>,
      );
      expect(restored.id, s.id);
      expect(restored.remaining(now.add(const Duration(minutes: 4))), 660);
      s.pause(now.add(const Duration(minutes: 4)));
      restored = FocusSession.fromMap(s.toMap());
      expect(restored.running, false);
      expect(restored.remaining(now.add(const Duration(days: 1))), 660);
    });
    test('never credits more than target; rejects corrupt duration', () {
      final s = FocusSession.start('math', 25, now);
      expect(s.studiedMinutes(now.add(const Duration(days: 1))), 25);
      expect(
        () => FocusSession.fromMap({...s.toMap(), 'totalSeconds': -1}),
        throwsFormatException,
      );
    });
  });
  group('Three-way synchronization', () {
    Map<String, dynamic> page(String id, String text) => {
      'id': id,
      'content': text,
    };
    test('combines offline additions from two devices', () {
      final result = mergeStudyData(
        {'notes': []},
        {
          'notes': [page('a', 'local')],
        },
        {
          'notes': [page('b', 'remote')],
        },
      );
      expect((result['notes'] as List).length, 2);
    });
    test('does not reintroduce a remotely deleted unchanged item', () {
      final base = {
        'notes': [page('a', 'same')],
      };
      expect(
        mergeStudyData(
          base,
          jsonDecode(jsonEncode(base)) as Map<String, dynamic>,
          {'notes': []},
        )['notes'],
        isEmpty,
      );
    });
    test('local deletion preserves unrelated remote additions', () {
      final result = mergeStudyData(
        {
          'notes': [page('a', 'old')],
        },
        {'notes': []},
        {
          'notes': [page('a', 'old'), page('b', 'new')],
        },
      );
      expect(result['notes'], [page('b', 'new')]);
    });
    test('deep equality preserves remote objective changes', () {
      final base = {
        'subjects': [
          {
            'id': 'math',
            'objectives': [
              {'id': 'o', 'completed': false},
            ],
          },
        ],
      };
      final local = jsonDecode(jsonEncode(base)) as Map<String, dynamic>;
      final remote = {
        'subjects': [
          {
            'id': 'math',
            'objectives': [
              {'id': 'o', 'completed': true},
            ],
          },
        ],
      };
      expect(
        mergeStudyData(base, local, remote)['subjects'],
        remote['subjects'],
      );
    });
    test('lost response retries cannot duplicate study minutes', () {
      final local = {
        'focusMinutes': 50,
        'studySessions': [
          {'id': 'one', 'minutes': 25},
          {'id': 'two', 'minutes': 25},
        ],
      };
      final base = {
        'focusMinutes': 25,
        'studySessions': [
          {'id': 'one', 'minutes': 25},
        ],
      };
      expect(mergeStudyData(base, local, local)['focusMinutes'], 50);
    });
    test('independent sessions add correctly regardless of JSON key order', () {
      final base = {'focusMinutes': 100, 'studySessions': []};
      final local = {
        'focusMinutes': 125,
        'studySessions': [
          {'id': 'one', 'minutes': 25},
        ],
      };
      final remote = {
        'focusMinutes': 115,
        'studySessions': [
          {'id': 'two', 'minutes': 15},
        ],
      };
      expect(mergeStudyData(base, local, remote)['focusMinutes'], 140);
    });
    test(
      'does not overwrite another device appearance when unchanged locally',
      () {
        expect(
          mergeStudyData(
            {'appearanceMode': 'light'},
            {'appearanceMode': 'light'},
            {'appearanceMode': 'dark'},
          )['appearanceMode'],
          'dark',
        );
      },
    );
    test('edits made during a request are rebased on acknowledged data', () {
      final sent = {
        'notes': [page('a', 'first')],
      };
      final current = {
        'notes': [page('a', 'second')],
      };
      final server = {
        'notes': [page('a', 'first'), page('b', 'remote')],
      };
      expect(mergeStudyData(sent, current, server)['notes'], [
        page('a', 'second'),
        page('b', 'remote'),
      ]);
    });
  });
}
