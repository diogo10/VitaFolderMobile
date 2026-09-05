import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFirebasePlatform extends FirebasePlatform {
  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    return MockFirebaseAppPlatform();
  }

  @override
  Future<void> setAutomaticDataCollectionEnabled(bool enabled) async {}

  @override
  Future<bool> getAutomaticDataCollectionEnabled() async => true;

  @override
  Future<void> setAutomaticResourceManagementEnabled(bool enabled) async {}

  @override
  Future<bool> getAutomaticResourceManagementEnabled() async => true;

  @override
  List<FirebaseAppPlatform> get apps => [MockFirebaseAppPlatform()];

  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) =>
      MockFirebaseAppPlatform();
}

class MockFirebaseAppPlatform extends FirebaseAppPlatform {
  MockFirebaseAppPlatform() : super('mock-app', MockFirebaseOptions());

  @override
  Future<void> delete() async {}

  @override
  FirebaseOptions get options => MockFirebaseOptions();

  @override
  String get name => 'mock-app';

  @override
  bool get isAutomaticDataCollectionEnabled => true;

  @override
  set automaticDataCollectionEnabled(bool enabled) {}

  @override
  Future<void> setAutomaticDataCollectionEnabled(bool enabled) async {}
}

class MockFirebaseOptions extends FirebaseOptions {
  const MockFirebaseOptions()
    : super(
        apiKey: 'mock-api-key',
        appId: 'mock-app-id',
        messagingSenderId: 'mock-sender-id',
        projectId: 'mock-project-id',
      );
}

void setupFirebaseMock() {
  FirebasePlatform.instance = MockFirebasePlatform();
}
