import 'package:flutter_test/flutter_test.dart';
import 'package:tally/core/result/result.dart';

void main() {
  group('Result', () {
    group('Success', () {
      test('holds value', () {
        const result = Success(42);
        expect(result.valueOrNull, 42);
        expect(result.errorOrNull, isNull);
        expect(result.isSuccess, isTrue);
        expect(result.isFailure, isFalse);
      });

      test('map transforms value', () {
        final result = const Success(10).map((v) => v * 2);
        expect(result.valueOrNull, 20);
        expect(result, isA<Success<int>>());
      });

      test('fold returns onSuccess', () {
        const result = Success('hello');
        final out = result.fold(
          onSuccess: (v) => 'got:$v',
          onFailure: (_, __) => 'fail',
        );
        expect(out, 'got:hello');
      });

      test('equality', () {
        expect(const Success(1), equals(const Success(1)));
        expect(const Success(1), isNot(equals(const Success(2))));
      });
    });

    group('Failure', () {
      test('holds error', () {
        const error = 'something went wrong';
        const result = Failure<int>(error);
        expect(result.errorOrNull, error);
        expect(result.valueOrNull, isNull);
        expect(result.isFailure, isTrue);
        expect(result.isSuccess, isFalse);
      });

      test('map preserves failure', () {
        final result = const Failure<int>('err').map((v) => v * 2);
        expect(result.isFailure, isTrue);
      });

      test('fold returns onFailure', () {
        const result = Failure<int>('oops');
        final out = result.fold(
          onSuccess: (_) => 'ok',
          onFailure: (e, _) => 'err:$e',
        );
        expect(out, 'err:oops');
      });
    });
  });
}
