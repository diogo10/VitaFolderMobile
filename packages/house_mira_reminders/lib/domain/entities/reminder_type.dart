enum ReminderType {
  renewal('renewal'),
  appointment('appointment'),
  vaccine('vaccine'),
  reimbursement('reimbursement'),
  birthday('birthday'),
  chores('chores'),
  custom('custom')
  ;

  const ReminderType(this.value);

  final String value;

  static ReminderType? fromString(String? value) {
    for (final type in ReminderType.values) {
      if (type.value == value) {
        return type;
      }
    }
    return null;
  }
}
