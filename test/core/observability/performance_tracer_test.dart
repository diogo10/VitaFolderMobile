import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira/core/observability/performance_tracer.dart';

class _FakeTraceHandle implements TraceHandle {
  final attributes = <String, String>{};
  final metrics = <String, int>{};
  var stops = 0;

  @override
  Future<void> putAttribute(String name, String value) async {
    attributes[name] = value;
  }

  @override
  Future<void> putMetric(String name, int value) async {
    metrics[name] = value;
  }

  @override
  Future<void> stop() async {
    stops++;
  }
}

class _FakeTracer implements PerformanceTracer {
  _FakeTracer(this.handle);
  final _FakeTraceHandle handle;
  final traces = <String>[];
  final initialAttributes = <Map<String, String>?>[];

  @override
  Future<T> trace<T>(
    String name,
    Future<T> Function(TraceHandle trace) action, {
    Map<String, String>? attributes,
  }) async {
    traces.add(name);
    initialAttributes.add(attributes);
    try {
      return await action(handle);
    } finally {
      await handle.stop();
    }
  }

  @override
  Future<TraceHandle> startTrace(String name) async {
    traces.add(name);
    return handle;
  }
}

void main() {
  group('NoOpPerformanceTracer', () {
    test('runs the action and returns its result', () async {
      final tracer = NoOpPerformanceTracer();

      final result = await tracer.trace('name', (trace) async {
        await trace.putAttribute('k', 'v');
        await trace.putMetric('m', 1);
        return 42;
      }, attributes: const {'a': 'b'});

      expect(result, 42);
    });

    test('startTrace returns a usable handle', () async {
      final tracer = NoOpPerformanceTracer();

      final handle = await tracer.startTrace('name');
      await handle.putAttribute('k', 'v');
      await handle.putMetric('m', 1);
      await handle.stop();
    });
  });

  group('PerformanceTracer contract', () {
    test('fake records trace name, attributes and stops', () async {
      final handle = _FakeTraceHandle();
      final tracer = _FakeTracer(handle);

      final result = await tracer.trace(
        'edge-invoke-x',
        (trace) async {
          await trace.putAttribute('success', 'true');
          await trace.putMetric('status', 200);
          return true;
        },
        attributes: const {'function': 'x'},
      );

      expect(result, isTrue);
      expect(tracer.traces, ['edge-invoke-x']);
      expect(tracer.initialAttributes.single, {'function': 'x'});
      expect(handle.attributes['success'], 'true');
      expect(handle.metrics['status'], 200);
      expect(handle.stops, 1);
    });
  });
}
