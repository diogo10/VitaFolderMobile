import 'package:flutter/widgets.dart';
import 'package:house_mira/generated/app_localizations.dart';
import 'package:intl/intl.dart';

/// Formats a note timestamp like the design asset (`2m ago`, `1h ago`,
/// `Yesterday`, `Tue`): minutes/hours via localized strings, yesterday
/// localized, older dates via locale-aware [DateFormat].
String formatNoteTimeAgo(
  BuildContext context,
  DateTime date, {
  DateTime? clock,
}) {
  final l = AppLocalizations.of(context)!;
  final now = (clock ?? DateTime.now()).toUtc();
  final value = date.toUtc();
  final diff = now.difference(value);
  if (diff.inMinutes < 1) {
    return l.notesTimeMinutesAgo(1);
  }
  if (diff.inHours < 1) {
    return l.notesTimeMinutesAgo(diff.inMinutes);
  }
  if (diff.inHours < 24) {
    return l.notesTimeHoursAgo(diff.inHours);
  }
  if (diff.inHours < 48) {
    return l.notesTimeYesterday;
  }
  if (diff.inDays < 7) {
    return DateFormat.E(Localizations.localeOf(context).languageCode).format(
      value.toLocal(),
    );
  }
  return DateFormat.yMd(Localizations.localeOf(context).languageCode).format(
    value.toLocal(),
  );
}
