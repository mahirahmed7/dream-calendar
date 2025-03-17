import 'package:flutter/material.dart';

enum TaskPriority {
  low,
  medium,
  high
}

enum TaskRecurrence {
  none,
  daily,
  weekly,
  monthly,
  custom
}

enum ReminderTime {
  none,
  tenMinutes,
  thirtyMinutes,
  oneHour,
  oneDay,
  custom
}

class TaskCategory {
  final String id;
  final String name;
  final Color color;

  const TaskCategory({
    required this.id,
    required this.name,
    required this.color,
  });

  static const List<TaskCategory> defaultCategories = [
    TaskCategory(
      id: 'work',
      name: 'Work',
      color: Color(0xFF4CAF50), // Green
    ),
    TaskCategory(
      id: 'personal',
      name: 'Personal',
      color: Color(0xFF2196F3), // Blue
    ),
    TaskCategory(
      id: 'health',
      name: 'Health',
      color: Color(0xFFF44336), // Red
    ),
    TaskCategory(
      id: 'study',
      name: 'Study',
      color: Color(0xFF9C27B0), // Purple
    ),
  ];
}

class RecurrenceRule {
  final TaskRecurrence type;
  final List<int>? daysOfWeek; // 1-7 for Monday-Sunday
  final int? dayOfMonth;
  final DateTime? endDate;
  final int? occurrences;

  const RecurrenceRule({
    required this.type,
    this.daysOfWeek,
    this.dayOfMonth,
    this.endDate,
    this.occurrences,
  });

  Map<String, dynamic> toJson() => {
    'type': type.index,
    'daysOfWeek': daysOfWeek,
    'dayOfMonth': dayOfMonth,
    'endDate': endDate?.toIso8601String(),
    'occurrences': occurrences,
  };

  factory RecurrenceRule.fromJson(Map<String, dynamic> json) => RecurrenceRule(
    type: TaskRecurrence.values[json['type'] as int],
    daysOfWeek: (json['daysOfWeek'] as List?)?.cast<int>(),
    dayOfMonth: json['dayOfMonth'] as int?,
    endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
    occurrences: json['occurrences'] as int?,
  );
}

class SubTask {
  final String id;
  final String title;
  bool isCompleted;

  SubTask({
    String? id,
    required this.title,
    this.isCompleted = false,
  }) : id = id ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'isCompleted': isCompleted,
  };

  factory SubTask.fromJson(Map<String, dynamic> json) => SubTask(
    id: json['id'] as String,
    title: json['title'] as String,
    isCompleted: json['isCompleted'] as bool,
  );
}

class CustomReminder {
  final int hours;
  final int minutes;

  const CustomReminder({
    required this.hours,
    required this.minutes,
  });

  Duration get duration => Duration(hours: hours, minutes: minutes);

  Map<String, dynamic> toJson() => {
    'hours': hours,
    'minutes': minutes,
  };

  factory CustomReminder.fromJson(Map<String, dynamic> json) => CustomReminder(
    hours: json['hours'] as int,
    minutes: json['minutes'] as int,
  );
}

class Task {
  final String id;
  final String title;
  final DateTime date;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final Duration? duration;
  final TaskPriority priority;
  final String? notes;
  final List<SubTask> subtasks;
  final TaskCategory? category;
  final RecurrenceRule? recurrence;
  final List<ReminderTime> reminders;
  final Map<ReminderTime, CustomReminder> customReminders;
  final String? externalCalendarId; // For sync with Google/Apple Calendar
  bool isCompleted;

  Task({
    String? id,
    required this.title,
    required this.date,
    this.startTime,
    this.endTime,
    this.duration,
    this.priority = TaskPriority.medium,
    this.notes,
    List<SubTask>? subtasks,
    this.category,
    this.recurrence,
    List<ReminderTime>? reminders,
    Map<ReminderTime, CustomReminder>? customReminders,
    this.externalCalendarId,
    this.isCompleted = false,
  }) : 
    id = id ?? DateTime.now().toIso8601String(),
    subtasks = subtasks ?? [],
    reminders = reminders ?? [],
    customReminders = customReminders ?? {};

  // Calculate duration from start and end time
  Duration? calculateDuration() {
    if (startTime == null || endTime == null) return null;

    final start = DateTime(
      date.year,
      date.month,
      date.day,
      startTime!.hour,
      startTime!.minute,
    );

    final end = DateTime(
      date.year,
      date.month,
      date.day,
      endTime!.hour,
      endTime!.minute,
    );

    return end.difference(start);
  }

  // Get color based on priority or category
  Color getDisplayColor() {
    if (category != null) return category!.color;
    
    switch (priority) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red;
    }
  }

  // Format time range
  String getTimeRange() {
    if (startTime == null || endTime == null) return 'No time set';
    
    String formatTime(TimeOfDay time) {
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }

    return '${formatTime(startTime!)} - ${formatTime(endTime!)}';
  }

  // Get next occurrence based on recurrence rule
  DateTime? getNextOccurrence() {
    if (recurrence == null || recurrence!.type == TaskRecurrence.none) return null;

    final now = DateTime.now();
    if (date.isAfter(now)) return date;

    switch (recurrence!.type) {
      case TaskRecurrence.daily:
        return DateTime(now.year, now.month, now.day + 1);
      case TaskRecurrence.weekly:
        if (recurrence!.daysOfWeek == null) return null;
        // Find next day of week
        for (int i = 1; i <= 7; i++) {
          final nextDate = DateTime(now.year, now.month, now.day + i);
          if (recurrence!.daysOfWeek!.contains(nextDate.weekday)) {
            return nextDate;
          }
        }
        return null;
      case TaskRecurrence.monthly:
        if (recurrence!.dayOfMonth == null) return null;
        var nextDate = DateTime(now.year, now.month + 1, recurrence!.dayOfMonth!);
        if (nextDate.day != recurrence!.dayOfMonth) {
          // Handle invalid dates (e.g., Feb 31)
          nextDate = DateTime(now.year, now.month + 2, 1).subtract(const Duration(days: 1));
        }
        return nextDate;
      case TaskRecurrence.custom:
      case TaskRecurrence.none:
        return null;
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'date': date.toIso8601String(),
    'startTime': startTime != null ? '${startTime!.hour}:${startTime!.minute}' : null,
    'endTime': endTime != null ? '${endTime!.hour}:${endTime!.minute}' : null,
    'priority': priority.index,
    'notes': notes,
    'subtasks': subtasks.map((st) => st.toJson()).toList(),
    'category': category?.id,
    'recurrence': recurrence?.toJson(),
    'reminders': reminders.map((r) => r.index).toList(),
    'customReminders': customReminders.map(
      (key, value) => MapEntry(key.index.toString(), value.toJson()),
    ),
    'externalCalendarId': externalCalendarId,
    'isCompleted': isCompleted,
  };

  factory Task.fromJson(Map<String, dynamic> json) {
    TimeOfDay? parseTimeOfDay(String? timeStr) {
      if (timeStr == null) return null;
      final parts = timeStr.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }

    final customRemindersJson = json['customReminders'] as Map<String, dynamic>?;
    final customReminders = <ReminderTime, CustomReminder>{};
    if (customRemindersJson != null) {
      customRemindersJson.forEach((key, value) {
        final reminderTime = ReminderTime.values[int.parse(key)];
        customReminders[reminderTime] = CustomReminder.fromJson(value as Map<String, dynamic>);
      });
    }

    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      date: DateTime.parse(json['date'] as String),
      startTime: parseTimeOfDay(json['startTime'] as String?),
      endTime: parseTimeOfDay(json['endTime'] as String?),
      priority: TaskPriority.values[json['priority'] as int],
      notes: json['notes'] as String?,
      subtasks: (json['subtasks'] as List)
          .map((st) => SubTask.fromJson(st as Map<String, dynamic>))
          .toList(),
      category: json['category'] != null 
          ? TaskCategory.defaultCategories.firstWhere(
              (c) => c.id == json['category'],
              orElse: () => TaskCategory.defaultCategories.first,
            )
          : null,
      recurrence: json['recurrence'] != null
          ? RecurrenceRule.fromJson(json['recurrence'] as Map<String, dynamic>)
          : null,
      reminders: (json['reminders'] as List?)
          ?.map((i) => ReminderTime.values[i as int])
          .toList() ?? [],
      customReminders: customReminders,
      externalCalendarId: json['externalCalendarId'] as String?,
      isCompleted: json['isCompleted'] as bool,
    );
  }

  Task copyWith({
    String? title,
    DateTime? date,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    TaskPriority? priority,
    String? notes,
    List<SubTask>? subtasks,
    TaskCategory? category,
    RecurrenceRule? recurrence,
    List<ReminderTime>? reminders,
    Map<ReminderTime, CustomReminder>? customReminders,
    String? externalCalendarId,
    bool? isCompleted,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      priority: priority ?? this.priority,
      notes: notes ?? this.notes,
      subtasks: subtasks ?? List.from(this.subtasks),
      category: category ?? this.category,
      recurrence: recurrence ?? this.recurrence,
      reminders: reminders ?? List.from(this.reminders),
      customReminders: customReminders ?? Map.from(this.customReminders),
      externalCalendarId: externalCalendarId ?? this.externalCalendarId,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
} 