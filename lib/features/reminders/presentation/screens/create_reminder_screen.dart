import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:vita_folder_mobile/features/reminders/domain/entities/reminder_entity.dart';
import 'package:vita_folder_mobile/features/reminders/domain/entities/reminder_type.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/cubit/create_reminder_cubit.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/cubit/create_reminder_state.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/cubit/reminders_cubit.dart';
import 'package:vita_folder_mobile/generated/app_localizations.dart';

class CreateReminderScreen extends StatefulWidget {
  final ReminderType? initialType;
  final ReminderEntity? reminder;

  const CreateReminderScreen({super.key, this.initialType, this.reminder});

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

  static const _sand50 = Color(0xFFF5F0EB);
  static const _sand100 = Color(0xFFE4DACE);
  static const _sand200 = Color(0xFFC9B99A);
  static const _sand300 = Color(0xFFB8A080);
  static const _sand400 = Color(0xFF8B7355);
  static const _sand500 = Color(0xFF8B7355);
  static const _sand600 = Color(0xFF7A6348);
  static const _sand700 = Color(0xFF634F39);

  final _typeIcons = {
    ReminderType.renewal: Icons.refresh_rounded,
    ReminderType.appointment: Icons.calendar_month_rounded,
    ReminderType.vaccine: Icons.vaccines_rounded,
    ReminderType.reimbursement: Icons.receipt_long_rounded,
    ReminderType.birthday: Icons.cake_rounded,
    ReminderType.chores: Icons.cleaning_services_rounded,
    ReminderType.custom: Icons.star_rounded,
  };

  final _typeColors = {
    ReminderType.renewal: Colors.teal,
    ReminderType.appointment: Colors.blue,
    ReminderType.vaccine: Colors.red,
    ReminderType.reimbursement: Colors.green,
    ReminderType.birthday: Colors.pink,
    ReminderType.chores: Colors.amber,
    ReminderType.custom: Colors.purple,
  };

  @override
  void initState() {
    super.initState();
    final reminder = widget.reminder;
    if (reminder != null) {
      _titleController.text = reminder.title;
      _bodyController.text = reminder.body;
      _selectedType = reminder.type;
      _repeatRule = reminder.repeatRule;
      final parsed = _parseDueDate(reminder.dueDate);
      _dueDate = parsed;
      _dueTime = parsed == null ? null : TimeOfDay.fromDateTime(parsed);
    } else {
      _selectedType = widget.initialType ?? ReminderType.custom;
    }
  }

  bool get _isEditing => widget.reminder != null;

  DateTime? _parseDueDate(String dueDate) {
    final trimmed = dueDate.trim();
    if (trimmed.isEmpty) return null;
    return DateFormat('dd/MM/yyyy HH:mm').tryParse(trimmed) ??
        DateFormat('dd/MM/yyyy').tryParse(trimmed);
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
      final cubit = context.read<CreateReminderCubit>();
      final reminder = widget.reminder;
      if (reminder != null) {
        cubit.updateReminder(
          reminder: reminder,
          title: _titleController.text.trim(),
          body: _bodyController.text.trim(),
          type: _selectedType,
          dueDate: _dueDate,
          repeatRule: _repeatRule,
        );
      } else {
        cubit.createReminder(
          title: _titleController.text.trim(),
          body: _bodyController.text.trim(),
          type: _selectedType,
          dueDate: _dueDate,
          repeatRule: _repeatRule,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _sand50,
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
          if (state is UpdatedReminderSuccess) {
            context.read<RemindersCubit>().getReminders();
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text(l.createReminderUpdatedMessage)),
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

          return SafeArea(
            child: Column(
              children: [
                _buildHeader(l),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          _buildTitleField(l),
                          const SizedBox(height: 24),
                          _buildDescriptionField(l),
                          const SizedBox(height: 24),
                          _buildTypeChips(l),
                          const SizedBox(height: 24),
                          _buildDateTimeFields(l),
                          const SizedBox(height: 24),
                          _buildRepeatSelector(l),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildSaveButton(l, isLoading),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: _sand50,
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
                  border: Border.all(color: _sand200),
                ),
                child: const Icon(
                  Icons.chevron_left_rounded,
                  color: _sand600,
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _isEditing ? l.createReminderTitleEdit : l.createReminderTitle,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: _sand700,
              ),
            ),
          ),
          const SizedBox(width: 56),
        ],
      ),
    );
  }

  Widget _buildTitleField(AppLocalizations l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.createReminderTitleLabel,
          style: TextStyle(
            color: _sand400,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          textCapitalization: TextCapitalization.sentences,
          style: TextStyle(
            color: _sand700,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: 'e.g. Weekly Grocery Run',
            hintStyle: TextStyle(
              color: _sand300,
              fontWeight: FontWeight.normal,
            ),
            filled: true,
            fillColor: _sand100,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: _sand200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: _sand200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: _sand400, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return l.createReminderTitleRequired;
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionField(AppLocalizations l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${l.createReminderBodyLabel} (Optional)',
          style: TextStyle(
            color: _sand400,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _bodyController,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          style: TextStyle(color: _sand600, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Add some notes about this reminder...',
            hintStyle: TextStyle(color: _sand300),
            filled: true,
            fillColor: _sand100,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: _sand200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: _sand200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: _sand400, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeChips(AppLocalizations l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.createReminderTypeLabel,
          style: TextStyle(
            color: _sand400,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: ReminderType.values.map((type) {
            final isSelected = _selectedType == type;
            final color = _typeColors[type] ?? _sand400;
            return InkWell(
              onTap: () => setState(() => _selectedType = type),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? color : _sand200,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _typeIcons[type] ?? Icons.star_rounded,
                      size: 16,
                      color: isSelected ? Colors.white : color,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _typeLabel(type, l),
                      style: TextStyle(
                        color: isSelected ? Colors.white : _sand600,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateTimeFields(AppLocalizations l) {
    return Row(
      children: [
        Expanded(child: _buildDateField(l)),
        const SizedBox(width: 16),
        Expanded(child: _buildTimeField(l)),
      ],
    );
  }

  Widget _buildDateField(AppLocalizations l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Due Date',
          style: TextStyle(
            color: _sand400,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _pickDueDate,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: _sand100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _sand200),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 20, color: _sand300),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _dueDate == null
                          ? 'Due Date'
                          : '${l.createReminderDueDateLabel}: ${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}',
                      style: TextStyle(
                        color: _dueDate == null ? _sand300 : _sand700,
                        fontSize: 14,
                        fontWeight: _dueDate == null
                            ? FontWeight.normal
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeField(AppLocalizations l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Time',
          style: TextStyle(
            color: _sand400,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _pickDueTime,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: _sand100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _sand200),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 20, color: _sand300),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _dueTime == null
                          ? 'Time'
                          : '${l.createReminderTimeLabel}: ${_formatTime(_dueTime!)}',
                      style: TextStyle(
                        color: _dueTime == null ? _sand300 : _sand700,
                        fontSize: 14,
                        fontWeight: _dueTime == null
                            ? FontWeight.normal
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRepeatSelector(AppLocalizations l) {
    const repeatOptions = [
      ('never', 'Never'),
      ('daily', 'Daily'),
      ('weekly', 'Weekly'),
      ('monthly', 'Monthly'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Repeat',
          style: TextStyle(
            color: _sand400,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: _sand100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: repeatOptions.map((option) {
              final isSelected = _repeatRule == option.$1;
              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => setState(() => _repeatRule = option.$1),
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? _sand400 : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          option.$2,
                          style: TextStyle(
                            color: isSelected ? Colors.white : _sand400,
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(AppLocalizations l, bool isLoading) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_sand50.withValues(alpha: 0), _sand50, _sand50],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLoading ? null : _onSave,
            borderRadius: BorderRadius.circular(28),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: isLoading ? _sand400.withValues(alpha: 0.7) : _sand500,
                borderRadius: BorderRadius.circular(28),
                boxShadow: isLoading
                    ? null
                    : [
                        BoxShadow(
                          color: _sand500.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  else ...[
                    const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _isEditing
                          ? l.createReminderSaveButtonEdit
                          : l.createReminderSaveButton,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
