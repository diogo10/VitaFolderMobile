import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vita_folder_mobile/features/reminders/domain/entities/reminder_type.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/cubit/create_reminder_cubit.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/cubit/create_reminder_state.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/cubit/reminders_cubit.dart';
import 'package:vita_folder_mobile/generated/app_localizations.dart';

class CreateReminderScreen extends StatefulWidget {
  final ReminderType? initialType;

  const CreateReminderScreen({super.key, this.initialType});

  @override
  State<CreateReminderScreen> createState() => _CreateReminderScreenState();
}

class _CreateReminderScreenState extends State<CreateReminderScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late ReminderType _selectedType;
  String _repeatRule = 'never';
  DateTime? _dueDate;
  TimeOfDay? _dueTime;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType ?? ReminderType.custom;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  String _typeLabel(ReminderType type, AppLocalizations l) {
    switch (type) {
      case ReminderType.renewal:
        return l.createReminderTypeRenewal;
      case ReminderType.appointment:
        return l.createReminderTypeAppointment;
      case ReminderType.vaccine:
        return l.createReminderTypeVaccine;
      case ReminderType.reimbursement:
        return l.createReminderTypeReimbursement;
      case ReminderType.birthday:
        return l.createReminderTypeBirthday;
      case ReminderType.chores:
        return l.createReminderTypeChores;
      case ReminderType.custom:
        return l.createReminderTypeCustom;
    }
  }

  String _repeatLabel(String repeatRule, AppLocalizations l) {
    switch (repeatRule) {
      case 'daily':
        return l.createReminderRepeatDaily;
      case 'weekly':
        return l.createReminderRepeatWeekly;
      case 'monthly':
        return l.createReminderRepeatMonthly;
      case 'never':
      default:
        return l.createReminderRepeatNever;
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) {
      setState(() => _dueDate = _mergeDateTime(picked, _dueTime));
    }
  }

  Future<void> _pickDueTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      setState(() {
        _dueTime = picked;
        _dueDate = _mergeDateTime(_dueDate ?? DateTime.now(), picked);
      });
    }
  }

  DateTime? _mergeDateTime(DateTime date, TimeOfDay? time) {
    if (time == null) {
      return DateTime(date.year, date.month, date.day);
    }
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  void _onSave() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<CreateReminderCubit>().createReminder(
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        type: _selectedType,
        dueDate: _dueDate,
        repeatRule: _repeatRule,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.createReminderTitle)),
      body: BlocConsumer<CreateReminderCubit, CreateReminderState>(
        listener: (context, state) {
          if (state is CreateReminderSuccess) {
            context.read<RemindersCubit>().getReminders();
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text(l.createReminderSuccessMessage)),
              );
            context.pop();
          }
          if (state is CreateReminderError) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          final isLoading = state is CreateReminderLoading;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _titleController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: l.createReminderTitleLabel,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l.createReminderTitleRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _bodyController,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: l.createReminderBodyLabel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<ReminderType>(
                    initialValue: _selectedType,
                    decoration: InputDecoration(
                      labelText: l.createReminderTypeLabel,
                      border: const OutlineInputBorder(),
                    ),
                    items: ReminderType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(_typeLabel(type, l)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedType = value);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    initialValue: _repeatRule,
                    decoration: InputDecoration(
                      labelText: l.createReminderRepeatRuleLabel,
                      border: const OutlineInputBorder(),
                    ),
                    items: ['never', 'daily', 'weekly', 'monthly'].map((rule) {
                      return DropdownMenuItem(
                        value: rule,
                        child: Text(_repeatLabel(rule, l)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _repeatRule = value);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: isLoading ? null : _pickDueDate,
                    icon: const Icon(Icons.event_rounded),
                    label: Text(
                      _dueDate == null
                          ? l.createReminderDueDateLabel
                          : '${l.createReminderDueDateLabel}: ${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}',
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: isLoading ? null : _pickDueTime,
                    icon: const Icon(Icons.schedule_rounded),
                    label: Text(
                      _dueTime == null
                          ? l.createReminderTimeLabel
                          : '${l.createReminderTimeLabel}: ${_formatTime(_dueTime!)}',
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: isLoading ? null : _onSave,
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l.createReminderSaveButton),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
