import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:house_mira/core/widgets/sand/sand_header.dart';
import 'package:house_mira/core/widgets/sand/sand_primary_button.dart';
import 'package:house_mira/features/account/presentation/cubit/manage_profile_cubit.dart';
import 'package:house_mira/features/account/presentation/cubit/manage_profile_state.dart';
import 'package:house_mira/generated/app_localizations.dart';
import 'package:house_mira/theme/sand_palette.dart';

class ManageProfileScreen extends StatefulWidget {
  const ManageProfileScreen({super.key, this.initialName, this.onProfileSaved});

  /// Display name captured from the account tab at route-build time.
  /// The manage-profile route no longer shares the account cubit instance,
  /// so the initial value travels as immutable data instead.
  final String? initialName;

  /// Refreshes the account tab after a successful save. Wired by the route
  /// builder to the coordinator's visited-tab refresh; no-op when the
  /// account tab is somehow unbuilt.
  final void Function()? onProfileSaved;

  @override
  State<ManageProfileScreen> createState() => _ManageProfileScreenState();
}

class _ManageProfileScreenState extends State<ManageProfileScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final initial = widget.initialName;
    if (initial != null && initial.isNotEmpty) {
      _nameController.text = initial;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (_formKey.currentState?.validate() ?? false) {
      await context.read<ManageProfileCubit>().saveName(_nameController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: SandPalette.sand50,
      body: BlocConsumer<ManageProfileCubit, ManageProfileState>(
        listener: (context, state) {
          if (state is ManageProfileSuccess) {
            widget.onProfileSaved?.call();
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text(l.manageProfileSuccessMessage)),
              );
            context.pop();
          }
          if (state is ManageProfileError) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          final isLoading = state is ManageProfileLoading;

          return SafeArea(
            child: Column(
              children: [
                SandHeader(title: l.manageProfileTitle),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              labelText: l.manageProfileNameLabel,
                              border: const OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return l.manageProfileNameRequired;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        SandPalette.sand50.withValues(alpha: 0),
                        SandPalette.sand50,
                        SandPalette.sand50,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: SandPrimaryButton(
                      label: l.manageProfileSaveButton,
                      icon: Icons.check_rounded,
                      isLoading: isLoading,
                      onPressed: isLoading ? null : _onSave,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
