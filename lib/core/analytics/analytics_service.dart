import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final FirebaseAnalyticsObserver _observer;

  AnalyticsService()
    : _observer = FirebaseAnalyticsObserver(
        analytics: FirebaseAnalytics.instance,
      );

  FirebaseAnalytics get analytics => _analytics;

  FirebaseAnalyticsObserver get observer => _observer;

  Future<void> initialize() async {
    await _analytics.setAnalyticsCollectionEnabled(true);
    if (kDebugMode) {
      await _analytics.setUserProperty(name: 'debug_mode', value: 'true');
    }
    debugPrint('Analytics initialized');
  }

  Future<void> setUserId(String userId) async {
    await _analytics.setUserId(id: userId);
  }

  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    await _analytics.setUserProperty(name: name, value: value);
  }

  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    await _analytics.logEvent(name: name, parameters: parameters);
    if (kDebugMode) {
      debugPrint('Analytics event: $name ${parameters ?? {}}');
    }
  }

  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass,
    );
    if (kDebugMode) {
      debugPrint('Analytics screen view: $screenName ($screenClass)');
    }
  }

  Future<void> logLogin({String? method}) async {
    await logEvent(name: 'login', parameters: {'method': method ?? 'unknown'});
  }

  Future<void> logSignUp({String? method}) async {
    await logEvent(
      name: 'sign_up',
      parameters: {'method': method ?? 'unknown'},
    );
  }

  Future<void> logShare({required String contentType, String? itemId}) async {
    await logEvent(
      name: 'share',
      parameters: {'content_type': contentType, 'item_id': itemId ?? ''},
    );
  }

  Future<void> logSearch({required String searchTerm}) async {
    await logEvent(name: 'search', parameters: {'search_term': searchTerm});
  }

  Future<void> logSelectContent({
    required String contentType,
    required String itemId,
  }) async {
    await logEvent(
      name: 'select_content',
      parameters: {'content_type': contentType, 'item_id': itemId},
    );
  }

  Future<void> logViewItem({
    required String itemId,
    required String itemName,
    double? price,
  }) async {
    final params = <String, Object>{'item_id': itemId, 'item_name': itemName};
    if (price != null) params['price'] = price;
    await logEvent(name: 'view_item', parameters: params);
  }

  Future<void> logAddToCart({
    required String itemId,
    required String itemName,
    required double price,
    required int quantity,
  }) async {
    await logEvent(
      name: 'add_to_cart',
      parameters: {
        'item_id': itemId,
        'item_name': itemName,
        'price': price,
        'quantity': quantity,
      },
    );
  }

  Future<void> logBeginCheckout({double? value, String? currency}) async {
    final params = <String, Object>{};
    if (value != null) params['value'] = value;
    if (currency != null) params['currency'] = currency;
    await logEvent(name: 'begin_checkout', parameters: params);
  }

  Future<void> logPurchase({
    required String transactionId,
    required double value,
    required String currency,
    List<Map<String, Object>>? items,
  }) async {
    await logEvent(
      name: 'purchase',
      parameters: {
        'transaction_id': transactionId,
        'value': value,
        'currency': currency,
        if (items != null) ...{'items': items},
      },
    );
  }

  Future<void> logError({
    required String errorCode,
    required String errorMessage,
  }) async {
    await logEvent(
      name: 'app_error',
      parameters: {'error_code': errorCode, 'error_message': errorMessage},
    );
  }

  Future<void> resetAnalyticsData() async {
    await _analytics.resetAnalyticsData();
  }
}
