import 'package:flutter/widgets.dart';
import 'package:house_mira/features/notes/domain/repository/notes_repository.dart';
import 'package:house_mira/features/notes/presentation/cubit/notes_state.dart';
import 'package:house_mira/generated/app_localizations.dart';

/// Maps a [NotesFailure] message code to its localized display string.
/// Unknown codes fall back to the generic error (never raw English).
String noteErrorMessage(BuildContext context, String code) {
  final l = AppLocalizations.of(context)!;
  return switch (code) {
    notesFailureNotFound => l.notesErrorNotFound,
    notesFailureOffline => l.notesErrorOffline,
    notesFailureNoFamily => l.notesErrorNoFamily,
    _ => l.notesErrorGeneric,
  };
}
