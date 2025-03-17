import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/task.dart';
import 'screens/dream_ai_screen.dart';
import 'screens/daily_view_screen.dart';
import 'screens/task_edit_screen.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  final Map<DateTime, List<Task>> _tasks = {};
  final DateFormat _dateFormatter = DateFormat('MMMM d, y');
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    super.dispose();
  }

  void _addTask(Task task) {
    setState(() {
      final dateOnly = DateTime(task.date.year, task.date.month, task.date.day);
      if (_tasks[dateOnly] == null) {
        _tasks[dateOnly] = [];
      }
      _tasks[dateOnly]!.add(task);

      if (task.recurrence != null && task.recurrence!.type != TaskRecurrence.none) {
        _addRecurringInstances(task);
      }
    });
  }

  void _addRecurringInstances(Task task) {
    final now = DateTime.now();
    final endDate = task.recurrence!.endDate ?? now.add(const Duration(days: 365));
    DateTime? nextDate = _getNextOccurrence(task, task.date);

    while (nextDate != null && nextDate.isBefore(endDate)) {
      final recurringTask = task.copyWith(date: nextDate);
      final dateOnly = DateTime(nextDate.year, nextDate.month, nextDate.day);
      
      if (_tasks[dateOnly] == null) {
        _tasks[dateOnly] = [];
      }
      _tasks[dateOnly]!.add(recurringTask);

      nextDate = _getNextOccurrence(task, nextDate);
    }
  }

  DateTime? _getNextOccurrence(Task task, DateTime fromDate) {
    if (task.recurrence == null) return null;

    final nextDay = fromDate.add(const Duration(days: 1));
    
    switch (task.recurrence!.type) {
      case TaskRecurrence.daily:
        return nextDay;
        
      case TaskRecurrence.weekly:
        if (task.recurrence!.daysOfWeek == null) return null;
        
        var checkDate = nextDay;
        while (!task.recurrence!.daysOfWeek!.contains(checkDate.weekday)) {
          checkDate = checkDate.add(const Duration(days: 1));
        }
        return checkDate;
        
      case TaskRecurrence.monthly:
        if (task.recurrence!.dayOfMonth == null) return null;
        
        var nextMonth = DateTime(fromDate.year, fromDate.month + 1, 1);
        var targetDay = task.recurrence!.dayOfMonth!;
        
        var lastDayOfMonth = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
        if (targetDay > lastDayOfMonth) {
          targetDay = lastDayOfMonth;
        }
        
        return DateTime(nextMonth.year, nextMonth.month, targetDay);
        
      case TaskRecurrence.custom:
        if (task.recurrence!.occurrences == null) return null;
        return fromDate.add(Duration(days: task.recurrence!.occurrences!));
        
      case TaskRecurrence.none:
        return null;
    }
  }

  List<Task> _getTasksForDay(DateTime day) {
    final dateOnly = DateTime(day.year, day.month, day.day);
    return _tasks[dateOnly] ?? [];
  }

  void _updateTask(Task updatedTask) {
    setState(() {
      if (updatedTask.recurrence != null) {
        _tasks.forEach((date, tasks) {
          tasks.removeWhere((t) => t.id == updatedTask.id);
        });
      }

      _addTask(updatedTask);
    });
  }

  void _deleteTask(String taskId) {
    setState(() {
      _tasks.forEach((date, tasks) {
        tasks.removeWhere((task) => task.id == taskId);
      });

      _tasks.removeWhere((date, tasks) => tasks.isEmpty);
    });
  }

  void _navigateToDreamAI() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DreamAIScreen(
          selectedDate: _selectedDay,
          onTasksGenerated: (tasks) {
            for (final taskTitle in tasks) {
              _addTask(Task(
                title: taskTitle,
                date: _selectedDay,
              ));
            }
          },
        ),
      ),
    );
  }

  void _navigateToTaskEdit() async {
    final task = await Navigator.push<Task>(
      context,
      MaterialPageRoute(
        builder: (context) => TaskEditScreen(
          task: Task(
            title: 'New Task',
            date: _selectedDay,
          ),
        ),
      ),
    );

    if (task != null) {
      _addTask(task);
    }
  }

  void _navigateToDailyView() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DailyViewScreen(
          date: _selectedDay,
          tasks: _getTasksForDay(_selectedDay),
          onTaskUpdated: _updateTask,
          onTaskDeleted: _deleteTask,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasks = _getTasksForDay(_selectedDay);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Dream Calendar',
          style: GoogleFonts.orbitron(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                      _error = null;
                    });
                    _navigateToDailyView();
                  },
                  calendarStyle: CalendarStyle(
                    selectedDecoration: BoxDecoration(
                      color: Colors.black87,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: Colors.black87.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: BoxDecoration(
                      color: Colors.red[400],
                      shape: BoxShape.circle,
                    ),
                    weekendTextStyle: const TextStyle(color: Colors.black54),
                    outsideTextStyle: TextStyle(color: Colors.grey[400]),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: GoogleFonts.orbitron(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.black87),
                    rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.black87),
                  ),
                  eventLoader: _getTasksForDay,
                ),
                const SizedBox(height: 24),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 14,
                      ),
                    ),
                  ),
                Expanded(
                  child: GestureDetector(
                    onTap: _navigateToDailyView,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _dateFormatter.format(_selectedDay),
                                    style: GoogleFonts.chakraPetch(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.open_in_full),
                                  color: Colors.black87,
                                  onPressed: _navigateToDailyView,
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          Expanded(
                            child: tasks.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.calendar_today_outlined,
                                          size: 48,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No tasks for this day\nTap to view details',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: tasks.length,
                                    separatorBuilder: (context, index) =>
                                        const SizedBox(height: 8),
                                    itemBuilder: (context, index) {
                                      final task = tasks[index];
                                      return Row(
                                        children: [
                                          Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color: task.getDisplayColor(),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              task.title,
                                              style: GoogleFonts.inter(
                                                fontSize: 16,
                                                color: Colors.black87,
                                                decoration: task.isCompleted
                                                    ? TextDecoration.lineThrough
                                                    : null,
                                              ),
                                            ),
                                          ),
                                          if (task.startTime != null)
                                            Text(
                                              task.getTimeRange(),
                                              style: GoogleFonts.chakraPetch(
                                                fontSize: 14,
                                                color: Colors.black54,
                                              ),
                                            ),
                                        ],
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.white70,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _navigateToDreamAI,
            heroTag: 'dream_button',
            backgroundColor: Colors.black87,
            child: const Icon(Icons.auto_awesome, color: Colors.white),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _navigateToTaskEdit,
            heroTag: 'add_task_button',
            backgroundColor: Colors.black87,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }
} 