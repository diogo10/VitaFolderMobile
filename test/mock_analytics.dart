import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseAnalytics extends Fake implements FirebaseAnalytics {
  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
    List<AnalyticsEventItem>? items,
    AnalyticsCallOptions? callOptions,
  }) async {}

  @override
  Future<void> setUserId({
    String? id,
    AnalyticsCallOptions? callOptions,
  }) async {}

  @override
  Future<void> setUserProperty({
    required String name,
    required String? value,
    AnalyticsCallOptions? callOptions,
  }) async {}

  @override
  Future<void> setAnalyticsCollectionEnabled(bool enabled) async {}

  @override
  Future<void> logScreenView({
    String? screenClass,
    String? screenName,
    Map<String, Object>? parameters,
    AnalyticsCallOptions? callOptions,
  }) async {}

  @override
  Future<void> resetAnalyticsData() async {}
}

class MockAnalyticsService {
  final MockFirebaseAnalytics mockAnalytics = MockFirebaseAnalytics();

  late final FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(
    analytics: mockAnalytics,
  );

  Future<void> initialize() async {}

  Future<void> setUserId(String userId) async {}

  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {}

  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {}

  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {}

  Future<void> logLogin({String? method}) async {}

  Future<void> logSignUp({String? method}) async {}

  Future<void> logShare({required String contentType, String? itemId}) async {}

  Future<void> logSearch({required String searchTerm}) async {}

  Future<void> logSelectContent({
    required String contentType,
    required String itemId,
  }) async {}

  Future<void> logViewItem({
    required String itemId,
    required String itemName,
    double? price,
  }) async {}

  Future<void> logAddToCart({
    required String itemId,
    required String itemName,
    required double price,
    required int quantity,
  }) async {}

  Future<void> logBeginCheckout({double? value, String? currency}) async {}

  Future<void> logPurchase({
    required String transactionId,
    required double value,
    required String currency,
    List<Map<String, Object>>? items,
  }) async {}

  Future<void> logError({
    required String errorCode,
    required String errorMessage,
  }) async {}

  Future<void> resetAnalyticsData() async {}
}
