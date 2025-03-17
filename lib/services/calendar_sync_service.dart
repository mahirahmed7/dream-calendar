import 'package:device_calendar/device_calendar.dart';
import '../models/task.dart';

class CalendarSyncService {
  static final CalendarSyncService _instance = CalendarSyncService._();
  factory CalendarSyncService() => _instance;

  final DeviceCalendarPlugin _deviceCalendar = DeviceCalendarPlugin();
  List<Calendar>? _availableCalendars;
  bool _isInitialized = false;

  CalendarSyncService._();

  Future<void> initialize() async {
    if (_isInitialized) return;

    final permissionsGranted = await _deviceCalendar.hasPermissions();
    if (!permissionsGranted.isSuccess || !permissionsGranted.data!) {
      final requestResult = await _deviceCalendar.requestPermissions();
      if (!requestResult.isSuccess || !requestResult.data!) {
        throw Exception('Calendar permissions not granted');
      }
    }

    final calendarsResult = await _deviceCalendar.retrieveCalendars();
    _availableCalendars = calendarsResult.data;
    _isInitialized = true;
  }

  Future<List<Calendar>> getAvailableCalendars() async {
    if (!_isInitialized) await initialize();
    return _availableCalendars ?? [];
  }

  Future<String?> syncTaskToCalendar(Task task, String calendarId) async {
    if (!_isInitialized) await initialize();

    if (task.startTime == null || task.endTime == null) {
      throw Exception('Task must have start and end times to sync with calendar');
    }

    final startDate = DateTime(
      task.date.year,
      task.date.month,
      task.date.day,
      task.startTime!.hour,
      task.startTime!.minute,
    );

    final endDate = DateTime(
      task.date.year,
      task.date.month,
      task.date.day,
      task.endTime!.hour,
      task.endTime!.minute,
    );

    final event = Event(
      calendarId,
      title: task.title,
      description: task.notes,
      start: startDate,
      end: endDate,
    );

    if (task.recurrenceSettings.type != RecurrenceType.none) {
      event.recurrenceRule = _createRecurrenceRule(task.recurrenceSettings);
    }

    final createResult = await _deviceCalendar.createOrUpdateEvent(event);
    if (!createResult.isSuccess) {
      throw Exception('Failed to sync task with calendar');
    }

    return createResult.data;
  }

  String? _createRecurrenceRule(RecurrenceSettings settings) {
    if (settings.type == RecurrenceType.none) return null;

    String frequency;
    switch (settings.type) {
      case RecurrenceType.daily:
        frequency = 'FREQ=DAILY';
        break;
      case RecurrenceType.weekly:
        frequency = 'FREQ=WEEKLY';
        if (settings.selectedDays != null && settings.selectedDays!.isNotEmpty) {
          final days = settings.selectedDays!
              .map((day) => _getWeekDay(day))
              .join(',');
          frequency += ';BYDAY=$days';
        }
        break;
      case RecurrenceType.monthly:
        frequency = 'FREQ=MONTHLY';
        break;
      case RecurrenceType.custom:
        if (settings.customDays != null) {
          frequency = 'FREQ=DAILY;INTERVAL=${settings.customDays}';
        } else {
          return null;
        }
        break;
      default:
        return null;
    }

    if (settings.endDate != null) {
      frequency += ';UNTIL=${settings.endDate!.toIso8601String()}';
    }

    return frequency;
  }

  String _getWeekDay(int day) {
    const days = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];
    return days[(day - 1) % 7];
  }

  Future<void> deleteCalendarEvent(String calendarId, String eventId) async {
    if (!_isInitialized) await initialize();
    await _deviceCalendar.deleteEvent(calendarId, eventId);
  }

  Future<void> updateCalendarEvent(Task task) async {
    if (task.externalCalendarId == null) return;

    final parts = task.externalCalendarId!.split('|');
    if (parts.length != 2) return;

    final calendarId = parts[0];
    final eventId = parts[1];

    await deleteCalendarEvent(calendarId, eventId);
    await syncTaskToCalendar(task, calendarId);
  }
} 