import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira/core/config/app_flavor.dart';
import 'package:house_mira/core/config/firebase_options_provider.dart';
import 'package:house_mira/firebase_options.dart';

void main() {
  group('firebaseOptionsFor', () {
    setUpAll(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
    });

    tearDownAll(() {
      debugDefaultTargetPlatformOverride = null;
    });

    test('resolves options for every flavor', () {
      for (final flavor in AppFlavor.values) {
        final options = firebaseOptionsFor(flavor);
        expect(
          options.projectId,
          DefaultFirebaseOptions.currentPlatform.projectId,
          reason: 'flavor: ${flavor.name}',
        );
      }
    });
  });
}
