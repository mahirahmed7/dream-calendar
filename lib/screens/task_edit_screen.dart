import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/task.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';

class TaskEditScreen extends StatefulWidget {
  final Task? task;

  const TaskEditScreen({
    super.key,
    this.task,
  });

  @override
  State<TaskEditScreen> createState() => _TaskEditScreenState();
}

class _TaskEditScreenState extends State<TaskEditScreen> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _subtaskController = TextEditingController();
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  TaskPriority _priority = TaskPriority.medium;
  TaskCategory? _category;
  final List<ReminderTime> _reminders = [];
  final Map<ReminderTime, CustomReminder> _customReminders = {};
  RecurrenceRule? _recurrence;
  final List<SubTask> _subtasks = [];

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _notesController.text = widget.task!.notes ?? '';
      _startTime = widget.task!.startTime;
      _endTime = widget.task!.endTime;
      _priority = widget.task!.priority;
      _category = widget.task!.category;
      _reminders.addAll(widget.task!.reminders);
      _customReminders.addAll(widget.task!.customReminders);
      _recurrence = widget.task!.recurrence;
      _subtasks.addAll(widget.task!.subtasks);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _subtaskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.task == null ? 'New Task' : 'Edit Task',
          style: GoogleFonts.orbitron(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saveTask,
            child: Text(
              'Save',
              style: GoogleFonts.chakraPetch(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Task Title',
                labelStyle: GoogleFonts.inter(color: Colors.black54),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black87),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Time',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectTime(context, true),
                    icon: const Icon(Icons.access_time),
                    label: Text(
                      _startTime == null
                          ? 'Start Time'
                          : _formatTime(_startTime!),
                      style: GoogleFonts.inter(),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectTime(context, false),
                    icon: const Icon(Icons.access_time),
                    label: Text(
                      _endTime == null ? 'End Time' : _formatTime(_endTime!),
                      style: GoogleFonts.inter(),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Priority',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _priority = TaskPriority.low),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: _priority == TaskPriority.low ? Colors.black87 : Colors.transparent,
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(32)),
                        ),
                        child: Center(
                          child: Text(
                            'Low',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: _priority == TaskPriority.low ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _priority = TaskPriority.medium),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: _priority == TaskPriority.medium ? Colors.black87 : Colors.transparent,
                        ),
                        child: Center(
                          child: Text(
                            'Medium',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: _priority == TaskPriority.medium ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _priority = TaskPriority.high),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: _priority == TaskPriority.high ? Colors.black87 : Colors.transparent,
                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(32)),
                        ),
                        child: Center(
                          child: Text(
                            'High',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: _priority == TaskPriority.high ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Category',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: TaskCategory.defaultCategories.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: Colors.grey[200],
                ),
                itemBuilder: (context, index) {
                  final category = TaskCategory.defaultCategories[index];
                  return ListTile(
                    onTap: () => setState(() => _category = category),
                    leading: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: category.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(
                      category.name,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    trailing: _category?.id == category.id
                        ? const Icon(Icons.check, color: Colors.black87)
                        : null,
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Reminders',
              style: GoogleFonts.orbitron(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  ...ReminderTime.values.where((r) => r != ReminderTime.none).map((reminder) {
                    final isSelected = _reminders.contains(reminder);
                    return Column(
                      children: [
                        ListTile(
                          onTap: () {
                            if (reminder == ReminderTime.custom) {
                              _showCustomReminderDialog();
                            } else {
                              setState(() {
                                if (isSelected) {
                                  _reminders.remove(reminder);
                                } else {
                                  _reminders.add(reminder);
                                }
                              });
                            }
                          },
                          title: Text(
                            _getReminderText(reminder),
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check, color: Colors.black87)
                              : null,
                        ),
                        if (reminder != ReminderTime.values.last)
                          Divider(height: 1, color: Colors.grey[200]),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Repeat',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  ListTile(
                    onTap: () => setState(() {
                      _recurrence = _recurrence?.type == TaskRecurrence.none
                          ? null
                          : RecurrenceRule(type: TaskRecurrence.none);
                    }),
                    title: Text(
                      'Never',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    trailing: _recurrence == null || _recurrence?.type == TaskRecurrence.none
                        ? const Icon(Icons.check, color: Colors.black87)
                        : null,
                  ),
                  Divider(height: 1, color: Colors.grey[200]),
                  ListTile(
                    onTap: () => setState(() {
                      _recurrence = RecurrenceRule(type: TaskRecurrence.daily);
                    }),
                    title: Text(
                      'Daily',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    trailing: _recurrence?.type == TaskRecurrence.daily
                        ? const Icon(Icons.check, color: Colors.black87)
                        : null,
                  ),
                  Divider(height: 1, color: Colors.grey[200]),
                  ListTile(
                    onTap: () => _showWeeklyRecurrenceDialog(),
                    title: Text(
                      'Weekly',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: _recurrence?.type == TaskRecurrence.weekly && _recurrence?.daysOfWeek != null
                        ? Text(
                            _getWeekDaysText(_recurrence!.daysOfWeek!),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          )
                        : null,
                    trailing: _recurrence?.type == TaskRecurrence.weekly
                        ? const Icon(Icons.check, color: Colors.black87)
                        : null,
                  ),
                  Divider(height: 1, color: Colors.grey[200]),
                  ListTile(
                    onTap: () => _showMonthlyRecurrenceDialog(),
                    title: Text(
                      'Monthly',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: _recurrence?.type == TaskRecurrence.monthly && _recurrence?.dayOfMonth != null
                        ? Text(
                            'Day ${_recurrence!.dayOfMonth}',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          )
                        : null,
                    trailing: _recurrence?.type == TaskRecurrence.monthly
                        ? const Icon(Icons.check, color: Colors.black87)
                        : null,
                  ),
                  Divider(height: 1, color: Colors.grey[200]),
                  ListTile(
                    onTap: () => _showCustomRecurrenceDialog(),
                    title: Text(
                      'Custom',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: _recurrence?.type == TaskRecurrence.custom && _recurrence?.occurrences != null
                        ? Text(
                            'Every ${_recurrence!.occurrences} days',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          )
                        : null,
                    trailing: _recurrence?.type == TaskRecurrence.custom
                        ? const Icon(Icons.check, color: Colors.black87)
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Notes (Optional)',
                labelStyle: GoogleFonts.inter(color: Colors.black54),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black87),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Subtasks',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addSubtask,
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _subtaskController,
              decoration: InputDecoration(
                hintText: 'Add a subtask',
                hintStyle: GoogleFonts.inter(color: Colors.black54),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black87),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _addSubtask,
                ),
              ),
              onSubmitted: (_) => _addSubtask(),
            ),
            const SizedBox(height: 16),
            ..._subtasks.map((subtask) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: subtask.isCompleted,
                      onChanged: (value) {
                        setState(() {
                          subtask.isCompleted = value!;
                        });
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      subtask.title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.black87,
                        decoration: subtask.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    color: Colors.red[400],
                    onPressed: () => _removeSubtask(subtask),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime ?? TimeOfDay.now() : _endTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _addSubtask() {
    if (_subtaskController.text.trim().isEmpty) return;

    setState(() {
      _subtasks.add(SubTask(title: _subtaskController.text.trim()));
      _subtaskController.clear();
    });
  }

  void _removeSubtask(SubTask subtask) {
    setState(() {
      _subtasks.remove(subtask);
    });
  }

  void _saveTask() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a task title',
            style: GoogleFonts.inter(),
          ),
        ),
      );
      return;
    }

    final task = Task(
      id: widget.task?.id,
      title: _titleController.text.trim(),
      date: widget.task?.date ?? DateTime.now(),
      startTime: _startTime,
      endTime: _endTime,
      priority: _priority,
      notes: _notesController.text.trim(),
      subtasks: _subtasks,
      isCompleted: widget.task?.isCompleted ?? false,
      category: _category,
      reminders: _reminders,
      customReminders: _customReminders,
      recurrence: _recurrence,
    );

    // Schedule notifications for the task
    if (_reminders.isNotEmpty && _startTime != null) {
      await NotificationService().scheduleTaskReminders(task);
    }

    Navigator.pop(context, task);
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _getReminderText(ReminderTime reminder) {
    switch (reminder) {
      case ReminderTime.tenMinutes:
        return '10 minutes before';
      case ReminderTime.thirtyMinutes:
        return '30 minutes before';
      case ReminderTime.oneHour:
        return '1 hour before';
      case ReminderTime.oneDay:
        return '1 day before';
      case ReminderTime.custom:
        final customReminder = _customReminders[reminder];
        if (customReminder != null) {
          final hours = customReminder.hours;
          final minutes = customReminder.minutes;
          final parts = [
            if (hours > 0) '$hours hour${hours > 1 ? 's' : ''}',
            if (minutes > 0) '$minutes minute${minutes > 1 ? 's' : ''}',
          ];
          return '${parts.join(' ')} before';
        }
        return 'Custom';
      case ReminderTime.none:
        return 'None';
    }
  }

  void _showWeeklyRecurrenceDialog() {
    final selectedDays = _recurrence?.daysOfWeek ?? [DateTime.now().weekday];
    var endDate = _recurrence?.endDate;
    
    showDialog(
      context: context,
      barrierDismissible: true,  // Allow tapping outside to dismiss
      builder: (context) => AlertDialog(
        title: Text(
          'Repeat Weekly',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select days',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: List.generate(7, (index) {
                  final weekday = index + 1;
                  final isSelected = selectedDays.contains(weekday);
                  return FilterChip(
                    label: Text(
                      _getWeekdayShort(weekday),
                      style: GoogleFonts.inter(
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (value) {
                      setState(() {
                        if (value) {
                          selectedDays.add(weekday);
                        } else {
                          selectedDays.remove(weekday);
                        }
                      });
                    },
                    backgroundColor: Colors.grey[50],
                    selectedColor: Colors.black87,
                    checkmarkColor: Colors.white,
                    side: BorderSide(color: Colors.grey[300]!),
                  );
                }),
              ),
              const SizedBox(height: 24),
              Text(
                'End Date (Optional)',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: endDate ?? DateTime.now().add(const Duration(days: 365)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() => endDate = picked);
                  }
                },
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  endDate != null 
                      ? DateFormat('MMM d, y').format(endDate!)
                      : 'Select End Date',
                  style: GoogleFonts.inter(),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _recurrence = RecurrenceRule(
                  type: TaskRecurrence.weekly,
                  daysOfWeek: selectedDays..sort(),
                  endDate: endDate,
                );
              });
              Navigator.pop(context);
            },
            child: Text(
              'Save',
              style: GoogleFonts.inter(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMonthlyRecurrenceDialog() {
    var selectedDay = _recurrence?.dayOfMonth ?? widget.task?.date.day ?? DateTime.now().day;
    var endDate = _recurrence?.endDate;
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Text(
          'Repeat Monthly',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (context, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select day of month',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: 31,
                    itemBuilder: (context, index) {
                      final day = index + 1;
                      final isSelected = day == selectedDay;
                      return GestureDetector(
                        onTap: () => setState(() => selectedDay = day),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.black87 : Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Center(
                            child: Text(
                              day.toString(),
                              style: GoogleFonts.inter(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontWeight: isSelected ? FontWeight.w600 : null,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'End Date (Optional)',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: endDate ?? DateTime.now().add(const Duration(days: 365)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setState(() => endDate = picked);
                    }
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    endDate != null 
                        ? DateFormat('MMM d, y').format(endDate!)
                        : 'Select End Date',
                    style: GoogleFonts.inter(),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _recurrence = RecurrenceRule(
                  type: TaskRecurrence.monthly,
                  dayOfMonth: selectedDay,
                  endDate: endDate,
                );
              });
              Navigator.pop(context);
            },
            child: Text(
              'Save',
              style: GoogleFonts.inter(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomRecurrenceDialog() {
    var days = _recurrence?.occurrences ?? 1;
    var endDate = _recurrence?.endDate;
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Text(
          'Custom Recurrence',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Repeat every',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            if (days > 1) {
                              setState(() => days--);
                            }
                          },
                        ),
                        Text(
                          days.toString(),
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            setState(() => days++);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'days',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'End Date (Optional)',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: endDate ?? DateTime.now().add(const Duration(days: 365)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() => endDate = picked);
                  }
                },
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  endDate != null 
                      ? DateFormat('MMM d, y').format(endDate!)
                      : 'Select End Date',
                  style: GoogleFonts.inter(),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _recurrence = RecurrenceRule(
                  type: TaskRecurrence.custom,
                  occurrences: days,
                  endDate: endDate,
                );
              });
              Navigator.pop(context);
            },
            child: Text(
              'Save',
              style: GoogleFonts.inter(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomReminderDialog() {
    int hours = 0;
    int minutes = 0;
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Text(
          'Custom Reminder',
          style: GoogleFonts.orbitron(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Remind me',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hours before',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () {
                                  if (hours > 0) {
                                    setState(() => hours--);
                                  }
                                },
                              ),
                              Text(
                                hours.toString(),
                                style: GoogleFonts.chakraPetch(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  setState(() => hours++);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Minutes before',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () {
                                  if (minutes > 0) {
                                    setState(() => minutes--);
                                  }
                                },
                              ),
                              Text(
                                minutes.toString(),
                                style: GoogleFonts.chakraPetch(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  setState(() => minutes++);
                                },
                              ),
                            ],
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(),
            ),
          ),
          TextButton(
            onPressed: () {
              final totalMinutes = (hours * 60) + minutes;
              if (totalMinutes > 0) {
                setState(() {
                  if (!_reminders.contains(ReminderTime.custom)) {
                    _reminders.add(ReminderTime.custom);
                  }
                  _customReminders[ReminderTime.custom] = CustomReminder(
                    hours: hours,
                    minutes: minutes,
                  );
                });
              }
              Navigator.pop(context);
            },
            child: Text(
              'Save',
              style: GoogleFonts.chakraPetch(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getWeekDaysText(List<int> daysOfWeek) {
    final days = daysOfWeek.map((d) => _getWeekdayShort(d)).join(', ');
    return 'Every $days';
  }

  String _getWeekdayShort(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Mon';
      case DateTime.tuesday:
        return 'Tue';
      case DateTime.wednesday:
        return 'Wed';
      case DateTime.thursday:
        return 'Thu';
      case DateTime.friday:
        return 'Fri';
      case DateTime.saturday:
        return 'Sat';
      case DateTime.sunday:
        return 'Sun';
      default:
        return '';
    }
  }
} 