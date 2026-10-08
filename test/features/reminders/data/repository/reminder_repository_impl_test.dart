import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira/core/errors/failure.dart';
import 'package:house_mira/features/reminders/data/models/reminder_model.dart';
import 'package:house_mira/features/reminders/data/repository/reminder_repository_impl.dart';
import 'package:house_mira/features/reminders/domain/entities/reminder_type.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockQueryBuilder extends Mock implements SupabaseQueryBuilder {}

/// Awaitable fake for `select().eq(...)` list queries.
class _FakeListFilter extends Fake
    implements PostgrestFilterBuilder<PostgrestList> {
  _FakeListFilter(this.rows);

  final PostgrestList rows;
  final List<(String, Object)> eqCalls = [];

  @override
  PostgrestFilterBuilder<PostgrestList> eq(String column, Object value) {
    eqCalls.add((column, value));
    return this;
  }

  @override
  PostgrestTransformBuilder<PostgrestMap?> maybeSingle() =>
      _FakeMaybeSingle(rows.isEmpty ? null : rows.first);

  Future<PostgrestList> get _future => Future<PostgrestList>.value(rows);

  @override
  Future<R> then<R>(
    FutureOr<R> Function(PostgrestList value) onValue, {
    Function? onError,
  }) => _future.then(onValue, onError: onError);

  @override
  Future<PostgrestList> catchError(
    Function onError, {
    bool Function(Object error)? test,
  }) => _future.catchError(onError, test: test);

  @override
  Future<PostgrestList> whenComplete(FutureOr<void> Function() action) =>
      _future.whenComplete(action);

  @override
  Future<PostgrestList> timeout(
    Duration timeLimit, {
    FutureOr<PostgrestList> Function()? onTimeout,
  }) => _future.timeout(timeLimit, onTimeout: onTimeout);

  @override
  Stream<PostgrestList> asStream() => _future.asStream();
}

/// Terminal `maybeSingle()` step of verify-by-GET chains, resolving to the
/// first row or null when the row is absent.
class _FakeMaybeSingle extends Fake
    implements PostgrestTransformBuilder<PostgrestMap?> {
  _FakeMaybeSingle(this.value);

  final PostgrestMap? value;

  Future<PostgrestMap?> get _future => Future<PostgrestMap?>.value(value);

  @override
  Future<R> then<R>(
    FutureOr<R> Function(PostgrestMap? value) onValue, {
    Function? onError,
  }) => _future.then(onValue, onError: onError);

  @override
  Future<PostgrestMap?> catchError(
    Function onError, {
    bool Function(Object error)? test,
  }) => _future.catchError(onError, test: test);

  @override
  Future<PostgrestMap?> whenComplete(FutureOr<void> Function() action) =>
      _future.whenComplete(action);

  @override
  Future<PostgrestMap?> timeout(
    Duration timeLimit, {
    FutureOr<PostgrestMap?> Function()? onTimeout,
  }) => _future.timeout(timeLimit, onTimeout: onTimeout);

  @override
  Stream<PostgrestMap?> asStream() => _future.asStream();
}

/// Awaitable fake for `update(...).eq(...)` / `delete().eq(...)` calls.
/// The write itself is bare (no select); verification reads go through
/// `query.select()` fakes instead.
class _FakeVoidFilter extends Fake implements PostgrestFilterBuilder<dynamic> {
  final List<(String, Object)> eqCalls = [];

  @override
  PostgrestFilterBuilder<dynamic> eq(String column, Object value) {
    eqCalls.add((column, value));
    return this;
  }

  Future<dynamic> get _future => Future<dynamic>.value(<String, dynamic>{});

  @override
  Future<R> then<R>(
    FutureOr<R> Function(dynamic value) onValue, {
    Function? onError,
  }) => _future.then(onValue, onError: onError);

  @override
  Future<dynamic> catchError(
    Function onError, {
    bool Function(Object error)? test,
  }) => _future.catchError(onError, test: test);

  @override
  Future<dynamic> whenComplete(FutureOr<void> Function() action) =>
      _future.whenComplete(action);

  @override
  Future<dynamic> timeout(
    Duration timeLimit, {
    FutureOr<dynamic> Function()? onTimeout,
  }) => _future.timeout(timeLimit, onTimeout: onTimeout);

  @override
  Stream<dynamic> asStream() => _future.asStream();
}

/// Terminal `single()` step of the `insert(...).select('id').single()` chain.
class _FakeSingleResult extends Fake
    implements PostgrestTransformBuilder<PostgrestMap> {
  _FakeSingleResult(this.value);

  final PostgrestMap value;

  Future<PostgrestMap> get _future => Future<PostgrestMap>.value(value);

  @override
  Future<R> then<R>(
    FutureOr<R> Function(PostgrestMap value) onValue, {
    Function? onError,
  }) => _future.then(onValue, onError: onError);

  @override
  Future<PostgrestMap> catchError(
    Function onError, {
    bool Function(Object error)? test,
  }) => _future.catchError(onError, test: test);

  @override
  Future<PostgrestMap> whenComplete(FutureOr<void> Function() action) =>
      _future.whenComplete(action);

  @override
  Future<PostgrestMap> timeout(
    Duration timeLimit, {
    FutureOr<PostgrestMap> Function()? onTimeout,
  }) => _future.timeout(timeLimit, onTimeout: onTimeout);

  @override
  Stream<PostgrestMap> asStream() => _future.asStream();
}

/// Middle `select('id')` step of the insert chain.
class _FakeInsertSelect extends Fake
    implements PostgrestTransformBuilder<PostgrestList> {
  _FakeInsertSelect(this.singleValue, this.selectColumns);

  final PostgrestMap singleValue;
  final String selectColumns;
  final List<String> calls = [];

  bool get singleCalled => calls.contains('single');

  @override
  PostgrestTransformBuilder<PostgrestMap> single() {
    calls.add('single');
    return _FakeSingleResult(singleValue);
  }

  Future<PostgrestList> get _future =>
      Future<PostgrestList>.value(<PostgrestMap>[]);

  @override
  Future<R> then<R>(
    FutureOr<R> Function(PostgrestList value) onValue, {
    Function? onError,
  }) => _future.then(onValue, onError: onError);

  @override
  Future<PostgrestList> catchError(
    Function onError, {
    bool Function(Object error)? test,
  }) => _future.catchError(onError, test: test);

  @override
  Future<PostgrestList> whenComplete(FutureOr<void> Function() action) =>
      _future.whenComplete(action);

  @override
  Future<PostgrestList> timeout(
    Duration timeLimit, {
    FutureOr<PostgrestList> Function()? onTimeout,
  }) => _future.timeout(timeLimit, onTimeout: onTimeout);

  @override
  Stream<PostgrestList> asStream() => _future.asStream();
}

/// `insert(...)` step of the create chain; captures the payload.
class _FakeInsertFilter extends Fake
    implements PostgrestFilterBuilder<dynamic> {
  _FakeInsertFilter({required this.singleValue});

  final PostgrestMap singleValue;
  final List<_FakeInsertSelect> selectSteps = [];

  String? get selectColumns =>
      selectSteps.isEmpty ? null : selectSteps.last.selectColumns;
  _FakeInsertSelect? get selectStep =>
      selectSteps.isEmpty ? null : selectSteps.last;

  @override
  PostgrestTransformBuilder<PostgrestList> select([String columns = '*']) {
    final step = _FakeInsertSelect(singleValue, columns);
    selectSteps.add(step);
    return step;
  }

  Future<dynamic> get _future => Future<dynamic>.value(<String, dynamic>{});

  @override
  Future<R> then<R>(
    FutureOr<R> Function(dynamic value) onValue, {
    Function? onError,
  }) => _future.then(onValue, onError: onError);

  @override
  Future<dynamic> catchError(
    Function onError, {
    bool Function(Object error)? test,
  }) => _future.catchError(onError, test: test);

  @override
  Future<dynamic> whenComplete(FutureOr<void> Function() action) =>
      _future.whenComplete(action);

  @override
  Future<dynamic> timeout(
    Duration timeLimit, {
    FutureOr<dynamic> Function()? onTimeout,
  }) => _future.timeout(timeLimit, onTimeout: onTimeout);

  @override
  Stream<dynamic> asStream() => _future.asStream();
}

Map<String, dynamic> _row({
  Object? id = '1',
  String type = 'appointment',
  String? dueAt = '2026-08-22T15:00:00.000',
  String? repeatRule = 'never',
}) => {
  'id': id,
  'title': 'Dentist',
  'body': 'Checkup',
  'type': type,
  'due_at': dueAt,
  'repeat_rule': repeatRule,
  'status': 'pending',
  'created_by': 'mom',
  'created_at': '2026-08-01',
};

ReminderModel _model({
  String id = '1',
  String dueDate = '22/08/2026 15:00',
  String repeatRule = 'never',
}) => ReminderModel(
  title: 'Dentist',
  body: 'Checkup',
  id: id,
  type: ReminderType.appointment,
  dueDate: dueDate,
  repeatRule: repeatRule,
  status: 'pending',
  createdBy: 'u1',
  createdAt: '2026-08-01',
);

/// Awaitable fake for head-count `count(...).eq(...)` queries.
class _FakeCountFilter extends Fake implements PostgrestFilterBuilder<int> {
  _FakeCountFilter(this.value);

  final int value;
  final List<(String, Object)> eqCalls = [];

  @override
  PostgrestFilterBuilder<int> eq(String column, Object value) {
    eqCalls.add((column, value));
    return this;
  }

  Future<int> get _future => Future<int>.value(value);

  @override
  Future<R> then<R>(
    FutureOr<R> Function(int value) onValue, {
    Function? onError,
  }) => _future.then(onValue, onError: onError);

  @override
  Future<int> catchError(
    Function onError, {
    bool Function(Object error)? test,
  }) => _future.catchError(onError, test: test);

  @override
  Future<int> whenComplete(FutureOr<void> Function() action) =>
      _future.whenComplete(action);

  @override
  Future<int> timeout(
    Duration timeLimit, {
    FutureOr<int> Function()? onTimeout,
  }) => _future.timeout(timeLimit, onTimeout: onTimeout);

  @override
  Stream<int> asStream() => _future.asStream();
}

void main() {
  late _MockSupabaseClient client;
  late _MockQueryBuilder query;
  late ReminderRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(<dynamic, dynamic>{});
    registerFallbackValue(CountOption.exact);
  });

  setUp(() {
    client = _MockSupabaseClient();
    query = _MockQueryBuilder();
    repository = ReminderRepositoryImpl(client: client);
    when(() => client.from('reminders')).thenAnswer((_) => query);
  });

  group('getReminders', () {
    test(
      'maps rows to entities with display dates and filters by family',
      () async {
        final filter = _FakeListFilter([
          _row(),
          _row(id: '2', dueAt: null),
        ]);
        when(() => query.select()).thenAnswer((_) => filter);

        final result = await repository.getReminders('f1');

        final list = result.getRight().toNullable()!;
        expect(list, hasLength(2));
        // ISO due date from Supabase is mapped to the display format.
        expect(list.first.dueDate, '22/08/2026 15:00');
        expect(list.first.type, ReminderType.appointment);
        // Null due_at maps to '' (dateless) instead of a fallback value.
        expect(list.last.dueDate, '');
        expect(
          filter.eqCalls,
          [('family_id', 'f1')],
        );
      },
    );

    test('returns an empty list when there are no rows', () async {
      when(() => query.select()).thenAnswer((_) => _FakeListFilter([]));

      final result = await repository.getReminders('f1');

      expect(result.getRight().toNullable(), isEmpty);
    });

    test('preserves Failure messages from the data source', () async {
      when(() => query.select()).thenThrow(Failure(message: 'db boom'));

      final result = await repository.getReminders('f1');

      expect(result.isLeft(), isTrue);
      expect(result.getLeft().toNullable()?.message, 'db boom');
    });

    test('maps unexpected errors to a generic Failure', () async {
      when(() => query.select()).thenThrow(Exception('db down'));

      final result = await repository.getReminders('f1');

      expect(result.isLeft(), isTrue);
      expect(
        result.getLeft().toNullable()?.message,
        Failure().message,
      );
    });
  });

  group('getRemindersCount', () {
    test('returns the head count scoped to the family', () async {
      final filter = _FakeCountFilter(10);
      when(() => query.count(any())).thenAnswer((_) => filter);

      final result = await repository.getRemindersCount('f1');

      expect(result.getRight().toNullable(), 10);
      expect(filter.eqCalls, [('family_id', 'f1')]);
    });

    test('maps count errors to a failure', () async {
      when(() => query.count(any())).thenThrow(Exception('db down'));

      final result = await repository.getRemindersCount('f1');

      expect(result.isLeft(), isTrue);
    });
  });

  group('getRemindersByTypeAndFamily', () {
    test('filters by type and family and maps the rows', () async {
      final filter = _FakeListFilter([_row(type: 'chores')]);
      when(() => query.select()).thenAnswer((_) => filter);

      final result = await repository.getRemindersByTypeAndFamily(
        type: ReminderType.chores,
        familyId: 'f1',
      );

      final list = result.getRight().toNullable()!;
      expect(list, hasLength(1));
      expect(list.single.type, ReminderType.chores);
      expect(
        filter.eqCalls,
        [
          ('type', 'chores'),
          ('family_id', 'f1'),
        ],
      );
    });

    test('maps unexpected errors to a generic Failure', () async {
      when(() => query.select()).thenThrow(Exception('db down'));

      final result = await repository.getRemindersByTypeAndFamily(
        type: ReminderType.chores,
        familyId: 'f1',
      );

      expect(result.isLeft(), isTrue);
      expect(
        result.getLeft().toNullable()?.message,
        Failure().message,
      );
    });
  });

  group('createReminder', () {
    test(
      'sends the toCreate payload with family id and returns the new id',
      () async {
        final insert = _FakeInsertFilter(
          singleValue: {'id': 'new-id'},
        );
        when(() => query.insert(any())).thenAnswer((_) => insert);

        final result = await repository.createReminder(_model(), 'fam-1');

        expect(result.getRight().toNullable(), 'new-id');
        final payload =
            verify(() => query.insert(captureAny())).captured.single
                as Map<String, dynamic>;
        expect(payload['family_id'], 'fam-1');
        expect(payload['title'], 'Dentist');
        expect(payload['type'], 'appointment');
        expect(payload['due_at'], '22/08/2026 15:00');
        expect(insert.selectColumns, 'id');
        expect(insert.selectStep?.singleCalled, isTrue);
      },
    );

    test('sends null due_at for dateless reminders', () async {
      final insert = _FakeInsertFilter(
        singleValue: {'id': 'new-id'},
      );
      when(() => query.insert(any())).thenAnswer((_) => insert);

      await repository.createReminder(_model(dueDate: ''), 'fam-1');

      final payload =
          verify(() => query.insert(captureAny())).captured.single
              as Map<String, dynamic>;
      expect(payload['due_at'], isNull);
    });

    test('coerces non-string ids to string', () async {
      final insert = _FakeInsertFilter(
        singleValue: {'id': 42},
      );
      when(() => query.insert(any())).thenAnswer((_) => insert);

      final result = await repository.createReminder(_model(), 'fam-1');

      expect(result.getRight().toNullable(), '42');
    });

    test('returns Failure when the created id is missing', () async {
      when(() => query.insert(any())).thenAnswer(
        (_) => _FakeInsertFilter(singleValue: <String, dynamic>{}),
      );

      final result = await repository.createReminder(_model(), 'fam-1');

      expect(result.isLeft(), isTrue);
    });

    test('returns Failure when the created id is empty', () async {
      when(() => query.insert(any())).thenAnswer(
        (_) => _FakeInsertFilter(singleValue: {'id': ''}),
      );

      final result = await repository.createReminder(_model(), 'fam-1');

      expect(result.isLeft(), isTrue);
    });

    test('preserves Failure messages from the data source', () async {
      when(() => query.insert(any())).thenThrow(Failure(message: 'db boom'));

      final result = await repository.createReminder(_model(), 'fam-1');

      expect(result.getLeft().toNullable()?.message, 'db boom');
    });

    test('maps unexpected errors to a generic Failure', () async {
      when(() => query.insert(any())).thenThrow(Exception('db down'));

      final result = await repository.createReminder(_model(), 'fam-1');

      expect(result.isLeft(), isTrue);
      expect(
        result.getLeft().toNullable()?.message,
        Failure().message,
      );
    });
  });

  group('updateReminder', () {
    test(
      'sends the toUpdate payload and verifies the persisted echo',
      () async {
        final write = _FakeVoidFilter();
        final echo = _FakeListFilter([
          {
            'id': '1',
            'title': 'Dentist',
            'type': 'appointment',
            'body': 'Checkup',
            'repeat_rule': 'never',
          },
        ]);
        when(() => query.update(any())).thenAnswer((_) => write);
        when(() => query.select(any())).thenAnswer((_) => echo);

        final result = await repository.updateReminder(_model());

        expect(result.getRight().toNullable(), isTrue);
        final payload =
            verify(() => query.update(captureAny())).captured.single
                as Map<String, dynamic>;
        expect(payload['title'], 'Dentist');
        expect(payload['type'], 'appointment');
        expect(payload['due_at'], '22/08/2026 15:00');
        expect(payload['repeat_rule'], 'never');
        expect(payload.keys, isNot(contains('family_id')));
        expect(payload.keys, isNot(contains('status')));
        expect(payload.keys, isNot(contains('created_by')));
        expect(write.eqCalls, [('id', '1')]);
        expect(echo.eqCalls, [('id', '1')]);
      },
    );

    test('preserves Failure messages from the data source', () async {
      when(() => query.update(any())).thenThrow(Failure(message: 'db boom'));

      final result = await repository.updateReminder(_model());

      expect(result.getLeft().toNullable()?.message, 'db boom');
    });

    test(
      'reports stale echoes as blocked instead of success',
      () async {
        when(() => query.update(any())).thenAnswer((_) => _FakeVoidFilter());
        when(() => query.select(any())).thenAnswer(
          (_) => _FakeListFilter([
            {
              'id': '1',
              'title': 'Dentist',
              'type': 'appointment',
              'body': 'Checkup',
              'repeat_rule': 'weekly',
            },
          ]),
        );

        final result = await repository.updateReminder(_model());

        expect(result.isLeft(), isTrue);
        expect(
          result.getLeft().toNullable(),
          isA<WriteBlockedFailure>(),
        );
      },
    );

    test(
      'reports absent rows as blocked instead of success',
      () async {
        when(() => query.update(any())).thenAnswer((_) => _FakeVoidFilter());
        when(
          () => query.select(any()),
        ).thenAnswer((_) => _FakeListFilter(const []));

        final result = await repository.updateReminder(_model());

        expect(result.isLeft(), isTrue);
        expect(
          result.getLeft().toNullable(),
          isA<WriteBlockedFailure>(),
        );
      },
    );

    test('maps unexpected errors to a generic Failure', () async {
      when(() => query.update(any())).thenThrow(Exception('db down'));

      final result = await repository.updateReminder(_model());

      expect(result.isLeft(), isTrue);
      expect(
        result.getLeft().toNullable()?.message,
        Failure().message,
      );
    });
  });

  group('removeReminder', () {
    test('deletes the reminder matching the id', () async {
      final write = _FakeVoidFilter();
      when(() => query.delete()).thenAnswer((_) => write);
      when(
        () => query.select(any()),
      ).thenAnswer((_) => _FakeListFilter(const []));

      final result = await repository.removeReminder('r1');

      expect(result.getRight().toNullable(), isTrue);
      expect(write.eqCalls, [('id', 'r1')]);
    });

    test('preserves Failure messages from the data source', () async {
      when(() => query.delete()).thenThrow(Failure(message: 'db boom'));

      final result = await repository.removeReminder('r1');

      expect(result.getLeft().toNullable()?.message, 'db boom');
    });

    test(
      'reports still-present rows as blocked instead of success',
      () async {
        when(() => query.delete()).thenAnswer((_) => _FakeVoidFilter());
        when(
          () => query.select(any()),
        ).thenAnswer(
          (_) => _FakeListFilter([
            {'id': 'r1'},
          ]),
        );

        final result = await repository.removeReminder('r1');

        expect(result.isLeft(), isTrue);
        expect(
          result.getLeft().toNullable(),
          isA<WriteBlockedFailure>(),
        );
      },
    );

    test('maps unexpected errors to a generic Failure', () async {
      when(() => query.delete()).thenThrow(Exception('db down'));

      final result = await repository.removeReminder('r1');

      expect(result.isLeft(), isTrue);
      expect(
        result.getLeft().toNullable()?.message,
        Failure().message,
      );
    });
  });
}
