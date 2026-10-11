import 'package:shared_preferences/shared_preferences.dart';

class OnboardingLocalDatasource {
  static const _key = 'onboarding_completed';

  Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}
