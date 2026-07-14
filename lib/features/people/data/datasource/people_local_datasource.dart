class PeopleLocalDatasource {
  Future<List<Map<String, dynamic>>> getPeople() async {
    return [
      {'id': 1, 'name': 'John Doe', 'email': 'john@example.com', 'phone': '+1 555-0101'},
      {'id': 2, 'name': 'Jane Smith', 'email': 'jane@example.com', 'phone': '+1 555-0102'},
      {'id': 3, 'name': 'Bob Johnson', 'email': 'bob@example.com', 'phone': '+1 555-0103'},
      {'id': 4, 'name': 'Alice Brown', 'email': 'alice@example.com', 'phone': '+1 555-0104'},
      {'id': 5, 'name': 'Charlie Wilson', 'email': 'charlie@example.com', 'phone': '+1 555-0105'},
    ];
  }
}
