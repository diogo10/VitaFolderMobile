import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:house_mira/core/router/app_routes.dart';
import 'package:house_mira/core/widgets/sand/sand_primary_button.dart';
import 'package:house_mira/features/notes/domain/entities/note_color.dart';
import 'package:house_mira/features/notes/domain/entities/note_entity.dart';
import 'package:house_mira/features/notes/domain/repository/notes_repository.dart';
import 'package:house_mira/features/notes/presentation/cubit/notes_cubit.dart';
import 'package:house_mira/features/notes/presentation/cubit/notes_state.dart';
import 'package:house_mira/features/notes/presentation/utils/note_error_message.dart';
import 'package:house_mira/features/notes/presentation/widgets/note_color_picker_widget.dart';
import 'package:house_mira/generated/app_localizations.dart';
import 'package:house_mira/theme/sand_palette.dart';

/// Typed wrapper for the create/edit note screen.
///
/// Editing travels via `extra` ([NoteEntity]); unknown extras are ignored
/// (fresh create form) instead of crashing.
@immutable
class NoteEditorRoute {
  const NoteEditorRoute({this.note});

  factory NoteEditorRoute.fromState(GoRouterState state) {
    final extra = state.extra;
    if (extra is NoteEntity) return NoteEditorRoute(note: extra);
    return const NoteEditorRoute();
  }

  final NoteEntity? note;

  String get location => AppRoutes.noteEditor;

  Object? get extra => note;

  Future<T?> push<T extends Object?>(BuildContext context) =>
      context.push<T>(location, extra: extra);
}

/// Create/edit form per `designs/html/01-FamilyAdmin - Notes (Create).html`
/// (reused as-is for edit): borderless title/body fields, `NOTE COLOR`
/// swatches tinting the canvas, bottom toolbar with exactly two buttons
/// (bold, list per FR-109) inserting `**` / `- ` markers; markers count
/// toward the length limit. Save stays disabled until both fields are
/// non-empty; length violations surface as localized inline errors.
class NoteEditorScreen extends StatefulWidget {
  const NoteEditorScreen({super.key, this.note, this.onSaved});

  /// Note to edit; `null` creates a new note.
  final NoteEntity? note;

  /// Refresh callback invoked after a successful save (route wiring).
  /// The screen always returns to the list afterwards.
  final void Function()? onSaved;

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late String _color;
  bool _saving = false;
  bool _canSave = false;

  bool get _isEdit => widget.note != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(
      text: widget.note?.content ?? '',
    );
    _color = widget.note?.color ?? noteColorAllowlist.first;
    _titleController.addListener(_refreshCanSave);
    _contentController.addListener(_refreshCanSave);
    _refreshCanSave();
  }

  @override
  void dispose() {
    _titleController
      ..removeListener(_refreshCanSave)
      ..dispose();
    _contentController
      ..removeListener(_refreshCanSave)
      ..dispose();
    super.dispose();
  }

  void _refreshCanSave() {
    final canSave =
        _titleController.text.trim().isNotEmpty &&
        _contentController.text.trim().isNotEmpty;
    if (canSave != _canSave && mounted) {
      setState(() => _canSave = canSave);
    }
  }

  String? _validateTitle(String? value, AppLocalizations l) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) return l.notesTitleRequired;
    if (trimmed.length > NoteEntity.maxTitleLength) {
      return l.notesTitleTooLong;
    }
    return null;
  }

  String? _validateContent(String? value, AppLocalizations l) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) return l.notesContentRequired;
    if (trimmed.length > NoteEntity.maxContentLength) {
      return l.notesContentTooLong;
    }
    return null;
  }

  void _insertMarker(String marker, {bool linePrefix = false}) {
    final controller = _contentController;
    final selection = controller.selection;
    final text = controller.text;
    final start = selection.start >= 0 ? selection.start : text.length;
    final end = selection.end >= 0 ? selection.end : text.length;
    if (linePrefix) {
      final lineStart = text.lastIndexOf('\n', start - 1) + 1;
      final updated =
          '${text.substring(0, lineStart)}$marker${text.substring(lineStart)}';
      controller.value = TextEditingValue(
        text: updated,
        selection: TextSelection.collapsed(offset: start + marker.length),
      );
    } else if (start == end) {
      final updated =
          '${text.substring(0, start)}$marker$marker${text.substring(end)}';
      controller.value = TextEditingValue(
        text: updated,
        selection: TextSelection.collapsed(offset: start + marker.length),
      );
    } else {
      final selected = text.substring(start, end);
      final updated =
          '${text.substring(0, start)}$marker$selected$marker'
          '${text.substring(end)}';
      controller.value = TextEditingValue(
        text: updated,
        selection: TextSelection.collapsed(offset: end + marker.length * 2),
      );
    }
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    setState(() => _saving = true);
    try {
      final cubit = context.read<NotesCubit>();
      final title = _titleController.text.trim();
      final content = _contentController.text.trim();
      if (_isEdit) {
        await cubit.updateNote(
          note: widget.note!,
          title: title,
          content: content,
          color: _color,
        );
      } else {
        await cubit.createNote(title: title, content: content, color: _color);
      }
      if (!mounted) return;
      final state = cubit.state;
      if (state is NotesLimitReached) {
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(noteErrorMessage(context, notesFailureLimitReached)),
            action: SnackBarAction(
              label: l.limitReachedUpgrade,
              onPressed: () => context.push(AppRoutes.paywall),
            ),
          ),
        );
        return;
      }
      if (state is NotesFailure) {
        final l = AppLocalizations.of(context)!;
        final isLimit = state.message == notesFailureLimitReached;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(noteErrorMessage(context, state.message)),
            action: isLimit
                ? SnackBarAction(
                    label: l.limitReachedUpgrade,
                    onPressed: () => context.push(AppRoutes.paywall),
                  )
                : null,
          ),
        );
        return;
      }
      widget.onSaved?.call();
      if (!mounted) return;
      await Navigator.of(context).maybePop();
    } on Object catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.notesErrorGeneric),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _colorName(AppLocalizations l) {
    return switch (_color) {
      'pink' => l.notesColorPink,
      'blue' => l.notesColorBlue,
      'green' => l.notesColorGreen,
      'orange' => l.notesColorOrange,
      _ => l.notesColorYellow,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final canvas = _color == noteColorAllowlist.first
        ? SandPalette.sand50
        : noteColorPalette[_color] ?? SandPalette.sand50;
    return Scaffold(
      backgroundColor: canvas,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(l, canvas),
            Expanded(
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  children: [
                    Semantics(
                      label: l.notesTitleLabel,
                      textField: true,
                      child: TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: l.notesTitleHint,
                          hintStyle: const TextStyle(
                            color: SandPalette.sand200,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          counterText: '',
                        ),
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 27,
                          fontWeight: FontWeight.w700,
                          color: SandPalette.sand700,
                          height: 1.2,
                        ),
                        maxLength: NoteEntity.maxTitleLength + 20,
                        validator: (v) => _validateTitle(v, l),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Semantics(
                      label: l.notesContentLabel,
                      textField: true,
                      child: TextFormField(
                        controller: _contentController,
                        decoration: InputDecoration(
                          hintText: l.notesContentHint,
                          hintStyle: const TextStyle(
                            color: SandPalette.sand200,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          counterText: '',
                        ),
                        style: const TextStyle(
                          fontSize: 17,
                          color: SandPalette.sand600,
                          height: 1.6,
                        ),
                        maxLines: null,
                        minLines: 8,
                        maxLength: NoteEntity.maxContentLength + 20,
                        validator: (v) => _validateContent(v, l),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      l.notesNoteColor,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: SandPalette.sand400,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    NoteColorPickerWidget(
                      selected: _color,
                      onSelected: (c) => setState(() => _color = c),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _colorName(l),
                      style: const TextStyle(
                        fontSize: 12,
                        color: SandPalette.sand400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildToolbar(l, canvas),
            _buildSaveButton(l, canvas),
          ],
        ),
      ),
    );
  }

  /// Top bar mirroring `CreateReminderScreen`: back tile, left-aligned
  /// title, balance spacer. Tinted with the canvas so it blends with the
  /// selected note color.
  Widget _buildHeader(AppLocalizations l, Color canvas) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: canvas,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => context.pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: SandPalette.sand200),
                ),
                child: const Icon(
                  Icons.chevron_left_rounded,
                  color: SandPalette.sand600,
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _isEdit ? l.notesEditTitle : l.notesCreateTitle,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: SandPalette.sand700,
              ),
            ),
          ),
          const SizedBox(width: 56),
        ],
      ),
    );
  }

  Widget _buildToolbar(AppLocalizations l, Color canvas) {
    return Container(
      color: canvas,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ToolButton(
            tooltip: l.notesToolbarBold,
            icon: Icons.format_bold_rounded,
            onPressed: () => _insertMarker('**'),
          ),
          _ToolButton(
            tooltip: l.notesToolbarList,
            icon: Icons.format_list_bulleted_rounded,
            onPressed: () => _insertMarker('- ', linePrefix: true),
          ),
        ],
      ),
    );
  }

  /// Bottom save mirroring `CreateReminderScreen`: gradient fade into a
  /// full-width primary button, disabled until both fields are non-empty.
  Widget _buildSaveButton(AppLocalizations l, Color canvas) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [canvas.withValues(alpha: 0), canvas, canvas],
        ),
      ),
      child: SafeArea(
        top: false,
        child: SandPrimaryButton(
          label: l.notesSave,
          icon: Icons.check_rounded,
          isLoading: _saving,
          onPressed: _saving || !_canSave ? null : _save,
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
          child: Center(
            child: Tooltip(
              message: tooltip,
              child: Icon(icon, size: 24, color: SandPalette.sand400),
            ),
          ),
        ),
      ),
    );
  }
}
