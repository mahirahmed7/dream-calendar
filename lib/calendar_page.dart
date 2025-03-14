import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'services/deepseek_service.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  final Map<DateTime, List<String>> _tasks = {};
  final TextEditingController _taskController = TextEditingController();
  final DateFormat _dateFormatter = DateFormat('MMMM d, y');
  bool _isLoading = false;
  String? _error;
  
  // Initialize DeepSeek service with your API key
  final _deepSeekService = DeepSeekService(apiKey: 'YOUR_API_KEY');

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  void _addTasks(List<String> tasks) {
    if (tasks.isEmpty) return;

    setState(() {
      final dateOnly = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
      if (_tasks[dateOnly] == null) {
        _tasks[dateOnly] = [];
      }
      _tasks[dateOnly]!.addAll(tasks);
    });
  }

  void _addTask(String task) {
    if (task.isEmpty) return;
    _addTasks([task]);
    _taskController.clear();
  }

  void _deleteTask(int index) {
    setState(() {
      final dateOnly = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
      _tasks[dateOnly]!.removeAt(index);
      if (_tasks[dateOnly]!.isEmpty) {
        _tasks.remove(dateOnly);
      }
    });
  }

  List<String> _getTasksForDay(DateTime day) {
    final dateOnly = DateTime(day.year, day.month, day.day);
    return _tasks[dateOnly] ?? [];
  }

  Future<void> _generateAITasks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tasks = await _deepSeekService.generateTasks(_selectedDay);
      _addTasks(tasks);
    } catch (e) {
      setState(() {
        _error = 'Failed to generate tasks. Please try again later.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showAddTaskSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add Task for ${_dateFormatter.format(_selectedDay)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _taskController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Enter task',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (value) {
                  _addTask(value);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _addTask(_taskController.text);
                        Navigator.pop(context);
                      },
                      child: const Text('Add Task'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _generateAITasks();
                      },
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Generate AI Tasks'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                        foregroundColor: Theme.of(context).colorScheme.onSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasks = _getTasksForDay(_selectedDay);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dream Calendar'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
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
                  },
                  calendarStyle: const CalendarStyle(
                    selectedDecoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      opacity: 0.5,
                    ),
                    markerDecoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                  eventLoader: _getTasksForDay,
                ),
                const SizedBox(height: 20),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tasks for ${_dateFormatter.format(_selectedDay)}:',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: tasks.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.task_alt,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No tasks for this day',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextButton.icon(
                                      onPressed: _generateAITasks,
                                      icon: const Icon(Icons.auto_awesome),
                                      label: const Text('Generate AI Tasks'),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: tasks.length,
                                itemBuilder: (context, index) {
                                  return Card(
                                    elevation: 2,
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    child: ListTile(
                                      title: Text(
                                        tasks[index],
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        onPressed: () => _deleteTask(index),
                                        color: Colors.red[400],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskSheet,
        child: const Icon(Icons.add),
      ),
    );
  }
} 