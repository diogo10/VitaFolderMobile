import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira/features/notes/data/models/note_model.dart';
import 'package:house_mira/features/notes/data/repository/notes_repository_impl.dart';
import 'package:house_mira/features/notes/domain/repository/notes_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockQueryBuilder extends Mock implements SupabaseQueryBuilder {}

/// Awaitable fake for bare `update(...).eq(...)` / `delete().eq(...)` writes.
class _FakeWriteFilter extends Fake implements PostgrestFilterBuilder<dynamic> {
  final List<(String, Object)> eqCalls = [];

  @override
  PostgrestFilterBuilder<dynamic> eq(String column, Object value) {
    eqCalls.add((column, value));
    return this;
  }

  Future<dynamic> get _future => Future<dynamic>.value();

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

/// Awaitable fake for verify-by-GET `select(...).eq(...)` reads, resolving
/// `maybeSingle()` to the first row or null.
class _FakeVerifyFilter extends Fake
    implements PostgrestFilterBuilder<PostgrestList> {
  _FakeVerifyFilter(this.rows);

  final PostgrestList rows;
  final List<(String, Object)> eqCalls = [];
  final List<String> selectCalls = [];

  @override
  PostgrestFilterBuilder<PostgrestList> eq(String column, Object value) {
    eqCalls.add((column, value));
    return this;
  }

  @override
  PostgrestTransformBuilder<PostgrestMap?> maybeSingle() =>
      _FakeMaybeSingle(rows.isEmpty ? null : rows.first);
}

/// Terminal `maybeSingle()` step resolving to the row or null.
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

NoteModel _model() => NoteModel(
  id: 'n1',
  familyId: 'f1',
  createdBy: 'u1',
  title: 'Title',
  content: 'Body text',
  color: 'pink',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

void main() {
  setUpAll(() {
    registerFallbackValue(CountOption.exact);
  });

  late _MockSupabaseClient client;
  late _MockQueryBuilder query;
  late NotesRepositoryImpl repository;

  setUp(() {
    client = _MockSupabaseClient();
    query = _MockQueryBuilder();
    repository = NotesRepositoryImpl(client: client);
    when(() => client.from('notes')).thenAnswer((_) => query);
  });

  group('NotesRepositoryImpl.updateNote', () {
    test('reports success when the fresh read matches the payload', () async {
      final write = _FakeWriteFilter();
      final read = _FakeVerifyFilter([
        {'id': 'n1', 'title': 'Title', 'content': 'Body text', 'color': 'pink'},
      ]);
      when(() => query.update(any())).thenAnswer((_) => write);
      when(() => query.select(any())).thenAnswer((_) => read);

      final result = await repository.updateNote(_model());

      expect(result.getRight().toNullable(), isTrue);
      final payload =
          verify(() => query.update(captureAny())).captured.single
              as Map<String, dynamic>;
      expect(payload['color'], 'pink');
      expect(write.eqCalls, [('id', 'n1')]);
      expect(read.eqCalls, [('id', 'n1')]);
    });

    test('reports notFound when the row is gone after the write', () async {
      when(() => query.update(any())).thenAnswer((_) => _FakeWriteFilter());
      when(
        () => query.select(any()),
      ).thenAnswer((_) => _FakeVerifyFilter(const []));

      final result = await repository.updateNote(_model());

      expect(result.isLeft(), isTrue);
      expect(result.getLeft().toNullable()?.message, notesFailureNotFound);
    });

    test('fails instead of fake success when the row is stale', () async {
      when(() => query.update(any())).thenAnswer((_) => _FakeWriteFilter());
      when(() => query.select(any())).thenAnswer(
        (_) => _FakeVerifyFilter([
          {
            'id': 'n1',
            'title': 'Title',
            'content': 'Body text',
            'color': 'yellow',
          },
        ]),
      );

      final result = await repository.updateNote(_model());

      expect(result.isLeft(), isTrue);
    });

    test('maps unexpected errors to the generic failure code', () async {
      when(() => query.update(any())).thenThrow(Exception('db down'));

      final result = await repository.updateNote(_model());

      expect(result.isLeft(), isTrue);
      expect(result.getLeft().toNullable()?.message, notesFailureGeneric);
    });
  });

  group('NotesRepositoryImpl.deleteNote', () {
    test('reports success when the row is gone after the delete', () async {
      final write = _FakeWriteFilter();
      final read = _FakeVerifyFilter(const []);
      when(() => query.delete()).thenAnswer((_) => write);
      when(() => query.select(any())).thenAnswer((_) => read);

      final result = await repository.deleteNote('n1');

      expect(result.getRight().toNullable(), isTrue);
      expect(write.eqCalls, [('id', 'n1')]);
      expect(read.eqCalls, [('id', 'n1')]);
    });

    test('fails when the row is still present after the delete', () async {
      when(() => query.delete()).thenAnswer((_) => _FakeWriteFilter());
      when(() => query.select(any())).thenAnswer(
        (_) => _FakeVerifyFilter([
          {'id': 'n1'},
        ]),
      );

      final result = await repository.deleteNote('n1');

      expect(result.isLeft(), isTrue);
      expect(result.getLeft().toNullable()?.message, notesFailureGeneric);
    });
  });

  group('NotesRepositoryImpl.getNotesCount', () {
    test('returns the head count scoped to the family', () async {
      final filter = _FakeCountFilter(3);
      when(() => query.count(any())).thenAnswer((_) => filter);

      final result = await repository.getNotesCount('f1');

      expect(result.getRight().toNullable(), 3);
      expect(filter.eqCalls, [('family_id', 'f1')]);
    });

    test('maps count errors to a failure', () async {
      when(() => query.count(any())).thenThrow(Exception('db down'));

      final result = await repository.getNotesCount('f1');

      expect(result.isLeft(), isTrue);
    });
  });
}
