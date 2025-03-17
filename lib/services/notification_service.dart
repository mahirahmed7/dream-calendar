import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/task.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  NotificationService._();

  Future<void> initialize() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();

    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    // You can navigate to the task details page here
  }

  Future<void> scheduleTaskReminders(Task task) async {
    if (!_isInitialized) await initialize();

    // Cancel existing reminders for this task
    await cancelTaskReminders(task.id);

    if (task.reminders.isEmpty || task.startTime == null) return;

    final taskDateTime = DateTime(
      task.date.year,
      task.date.month,
      task.date.day,
      task.startTime!.hour,
      task.startTime!.minute,
    );

    for (final reminder in task.reminders) {
      if (reminder == ReminderTime.none) continue;

      final Duration reminderOffset = _getReminderOffset(reminder, task);
      final reminderTime = tz.TZDateTime.from(
        taskDateTime.subtract(reminderOffset),
        tz.local,
      );

      if (reminderTime.isBefore(DateTime.now())) continue;

      await _notifications.zonedSchedule(
        '${task.id}_${reminder.index}'.hashCode,
        'Upcoming Task: ${task.title}',
        _getReminderMessage(task, reminder),
        reminderTime,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'task_reminders',
            'Task Reminders',
            channelDescription: 'Notifications for upcoming tasks',
            importance: Importance.high,
            priority: Priority.high,
            color: task.getDisplayColor(),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> cancelTaskReminders(String taskId) async {
    if (!_isInitialized) return;

    // Cancel all notifications for this task
    for (final reminder in ReminderTime.values) {
      await _notifications.cancel('${taskId}_${reminder.index}'.hashCode);
    }
  }

  Duration _getReminderOffset(ReminderTime reminder, Task task) {
    switch (reminder) {
      case ReminderTime.tenMinutes:
        return const Duration(minutes: 10);
      case ReminderTime.thirtyMinutes:
        return const Duration(minutes: 30);
      case ReminderTime.oneHour:
        return const Duration(hours: 1);
      case ReminderTime.oneDay:
        return const Duration(days: 1);
      case ReminderTime.custom:
        final customReminder = task.customReminders[reminder];
        if (customReminder != null) {
          return customReminder.duration;
        }
        return Duration.zero;
      case ReminderTime.none:
        return Duration.zero;
    }
  }

  String _getReminderMessage(Task task, ReminderTime reminder) {
    final timeStr = task.getTimeRange();
    final categoryStr = task.category != null ? ' (${task.category!.name})' : '';
    
    switch (reminder) {
      case ReminderTime.tenMinutes:
        return 'Starting in 10 minutes: $timeStr$categoryStr';
      case ReminderTime.thirtyMinutes:
        return 'Starting in 30 minutes: $timeStr$categoryStr';
      case ReminderTime.oneHour:
        return 'Starting in 1 hour: $timeStr$categoryStr';
      case ReminderTime.oneDay:
        return 'Tomorrow: $timeStr$categoryStr';
      case ReminderTime.custom:
        final customReminder = task.customReminders[reminder];
        if (customReminder != null) {
          final hours = customReminder.hours;
          final minutes = customReminder.minutes;
          final timeText = [
            if (hours > 0) '$hours hour${hours > 1 ? 's' : ''}',
            if (minutes > 0) '$minutes minute${minutes > 1 ? 's' : ''}',
          ].join(' ');
          return 'Starting in $timeText: $timeStr$categoryStr';
        }
        return timeStr;
      case ReminderTime.none:
        return '';
    }
  }
} 