import 'package:shared_preferences/shared_preferences.dart';

class PeopleLocalDatasource {
  static const _inviteCodeCardDismissedKey = 'people_invite_code_card_dismissed';

  Future<List<Map<String, dynamic>>> getPeople() async {
    return [
      {'id': 1, 'name': 'John Doe', 'email': 'john@example.com', 'phone': '+1 555-0101'},
      {'id': 2, 'name': 'Jane Smith', 'email': 'jane@example.com', 'phone': '+1 555-0102'},
      {'id': 3, 'name': 'Bob Johnson', 'email': 'bob@example.com', 'phone': '+1 555-0103'},
      {'id': 4, 'name': 'Alice Brown', 'email': 'alice@example.com', 'phone': '+1 555-0104'},
      {'id': 5, 'name': 'Charlie Wilson', 'email': 'charlie@example.com', 'phone': '+1 555-0105'},
    ];
  }

  Future<bool> isInviteCodeCardDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_inviteCodeCardDismissedKey) ?? false;
  }

  Future<void> dismissInviteCodeCard() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_inviteCodeCardDismissedKey, true);
  }
}
