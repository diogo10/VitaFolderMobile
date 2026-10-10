import 'package:flutter/widgets.dart';
import 'package:house_mira_notes/domain/repository/notes_repository.dart'
    show
        notesFailureGeneric,
        notesFailureNoFamily,
        notesFailureNotFound,
        notesFailureOffline;
import 'package:house_mira_notes/presentation/cubit/notes_state.dart';
import 'package:house_mira_core/generated/app_localizations.dart';

/// Maps a [NotesFailure] message code to its localized display string.
/// Unknown codes fall back to the generic error (never raw English).
/// The free-tier cap is not a failure code: it surfaces as
/// [NotesLimitReached], which renders `notesErrorLimitReached` with an
/// upgrade action directly.
String noteErrorMessage(BuildContext context, String code) {
  final l = AppLocalizations.of(context)!;
  return switch (code) {
    notesFailureNotFound => l.notesErrorNotFound,
    notesFailureOffline => l.notesErrorOffline,
    notesFailureNoFamily => l.notesErrorNoFamily,
    notesFailureGeneric => l.notesErrorGeneric,
    _ => l.notesErrorGeneric,
  };
}
