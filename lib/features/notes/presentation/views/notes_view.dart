import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:house_mira/core/router/app_routes.dart';
import 'package:house_mira/features/notes/domain/entities/note_entity.dart';
import 'package:house_mira/features/notes/presentation/cubit/notes_cubit.dart';
import 'package:house_mira/features/notes/presentation/cubit/notes_state.dart';
import 'package:house_mira/features/notes/presentation/utils/note_error_message.dart';
import 'package:house_mira/features/notes/presentation/views/note_editor_screen.dart';
import 'package:house_mira/features/notes/presentation/widgets/note_card_widget.dart';
import 'package:house_mira/features/notes/presentation/widgets/notes_empty_widget.dart';
import 'package:house_mira/features/notes/presentation/widgets/notes_unauthenticated_widget.dart';
import 'package:house_mira/features/people/presentation/widgets/family_header_widget.dart';
import 'package:house_mira/generated/app_localizations.dart';
import 'package:house_mira/theme/sand_palette.dart';

/// Notes list tab per `designs/html/01-FamilyAdmin - Notes.html`:
/// page heading (`Notes` + `Shared with {family}` + add button),
/// two-column masonry grid of note cards, pull-to-refresh, bottom sheet
/// with Edit + Remove, empty/unauthenticated/error states.
class NotesView extends StatefulWidget {
  const NotesView({super.key, this.onCreateNote});

  /// Test seam for the add-button wiring (defaults to the editor route).
  final Future<void> Function(BuildContext context)? onCreateNote;

  @override
  State<NotesView> createState() => _NotesViewState();
}

class _NotesViewState extends State<NotesView> {
  @override
  void initState() {
    super.initState();
    unawaited(context.read<NotesCubit>().loadNotes());
  }

  Future<void> _handleAdd() async {
    if (widget.onCreateNote != null) {
      await widget.onCreateNote!(context);
      return;
    }
    final cubit = context.read<NotesCubit>();
    if (!cubit.authService.isLoggedIn()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.needToBeLoggedIn),
        ),
      );
      return;
    }
    final hasFamily = await cubit.hasFamily();
    if (!mounted) return;
    if (!hasFamily) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.createReminderErrorNoFamily,
          ),
        ),
      );
      context.go(AppRoutes.people);
      return;
    }
    await const NoteEditorRoute().push(context);
  }

  void _showMenu(BuildContext context, NoteEntity note) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        useRootNavigator: true,
        builder: (sheetContext) => _NoteMenuSheet(
          note: note,
          onEdit: () async {
            Navigator.of(sheetContext).pop();
            await NoteEditorRoute(note: note).push(context);
          },
          onRemove: () async {
            Navigator.of(sheetContext).pop();
            if (!context.mounted) return;
            await _confirmRemove(context, note);
          },
        ),
      ),
    );
  }

  Future<void> _confirmRemove(BuildContext context, NoteEntity note) async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.notesDeleteDialogTitle),
        content: Text(l.notesDeleteDialogMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l.notesDeleteDialogCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l.notesDeleteDialogConfirm),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<NotesCubit>().deleteNote(note.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<NotesCubit>();
    return Scaffold(
      backgroundColor: SandPalette.sand50,
      floatingActionButton: FloatingActionButton(
        onPressed: _handleAdd,
        backgroundColor: SandPalette.sand500,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      body: SafeArea(
        child: BlocBuilder<NotesCubit, NotesState>(
          builder: (context, state) {
            return RefreshIndicator(
              onRefresh: cubit.loadNotes,
              color: SandPalette.sand500,
              child: _body(context, state),
            );
          },
        ),
      ),
    );
  }

  Widget _scrollable(Widget child) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 120),
      children: [child],
    );
  }

  Widget _body(BuildContext context, NotesState state) {
    final l = AppLocalizations.of(context)!;
    final cubit = context.read<NotesCubit>();
    return switch (state) {
      NotesInitial() || NotesLoading() || NoteActionSuccess() => _scrollable(
        const SizedBox(
          height: 400,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      NotesUnauthenticated() => _scrollable(
        NotesUnauthenticatedWidget(
          onSignIn: () => context.go(AppRoutes.account),
          onJoinFamily: () => context.go(AppRoutes.people),
          onCreateAccount: () => context.push(AppRoutes.signUp),
        ),
      ),
      NotesFailure(:final message) => _scrollable(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 96),
          child: Column(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 56,
                color: SandPalette.sand300,
              ),
              const SizedBox(height: 16),
              Text(
                noteErrorMessage(context, message),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: SandPalette.sand700,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: cubit.loadNotes,
                child: Text(l.remindersErrorRetry),
              ),
            ],
          ),
        ),
      ),
      NotesLoaded(:final notes) =>
        notes.isEmpty
            ? SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FamilyHeaderWidget(),
                    NotesEmptyWidget(onCreate: _handleAdd),
                  ],
                ),
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FamilyHeaderWidget(),
                    const SizedBox(height: 22),
                    _Heading(familyName: cubit.familyName),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              for (var i = 0; i < notes.length; i += 2)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: NoteCardWidget(
                                    note: notes[i],
                                    onTap: () => _showMenu(context, notes[i]),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            children: [
                              for (var i = 1; i < notes.length; i += 2)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: NoteCardWidget(
                                    note: notes[i],
                                    onTap: () => _showMenu(context, notes[i]),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
    };
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.familyName});
  final String? familyName;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.notesTitle,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: SandPalette.sand700,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          familyName == null
              ? l.notesSharedWithYourFamily
              : l.notesSharedWith(familyName!),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: SandPalette.sand400,
          ),
        ),
      ],
    );
  }
}

class _NoteMenuSheet extends StatelessWidget {
  const _NoteMenuSheet({
    required this.note,
    required this.onEdit,
    required this.onRemove,
  });
  final NoteEntity note;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      decoration: const BoxDecoration(
        color: SandPalette.sand50,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 24),
              decoration: BoxDecoration(
                color: SandPalette.sand300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                note.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: SandPalette.sand700,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _MenuItem(
              icon: Icons.edit_rounded,
              label: l.notesEditTitle,
              onTap: onEdit,
            ),
            _MenuItem(
              icon: Icons.delete_rounded,
              label: l.notesDeleteDialogConfirm,
              isDestructive: true,
              onTap: onRemove,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });
  final IconData icon;
  final String label;
  final bool isDestructive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? const Color(0xFFD46D8B) : SandPalette.sand700;
    final bgColor = isDestructive
        ? const Color(0xFFFCE4EC)
        : SandPalette.sand100;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Icon(icon, size: 20, color: color)),
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
