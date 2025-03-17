import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/task.dart';
import 'task_edit_screen.dart';

class DailyViewScreen extends StatelessWidget {
  final DateTime date;
  final List<Task> tasks;
  final Function(Task) onTaskUpdated;
  final Function(String) onTaskDeleted;

  const DailyViewScreen({
    super.key,
    required this.date,
    required this.tasks,
    required this.onTaskUpdated,
    required this.onTaskDeleted,
  });

  @override
  Widget build(BuildContext context) {
    // Sort tasks by start time
    final sortedTasks = List<Task>.from(tasks)
      ..sort((a, b) {
        if (a.startTime == null) return 1;
        if (b.startTime == null) return -1;
        return a.startTime!.hour * 60 + a.startTime!.minute -
            (b.startTime!.hour * 60 + b.startTime!.minute);
      });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Schedule for ${_formatDate(date)}',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
      body: sortedTasks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_note_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tasks scheduled',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sortedTasks.length,
              itemBuilder: (context, index) {
                final task = sortedTasks[index];
                return _buildTaskCard(context, task);
              },
            ),
    );
  }

  Widget _buildTaskCard(BuildContext context, Task task) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey[50],
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _editTask(context, task),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[200]!),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: Colors.red[400],
                      onPressed: () => _deleteTask(context, task),
                    ),
                  ],
                ),
                if (task.startTime != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        task.getTimeRange(),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
                if (task.notes?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Text(
                    task.notes!,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
                if (task.subtasks.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  ...task.subtasks.map((subtask) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: subtask.isCompleted,
                            onChanged: (value) {
                              subtask.isCompleted = value!;
                              onTaskUpdated(task);
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
                      ],
                    ),
                  )),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _editTask(BuildContext context, Task task) async {
    final updatedTask = await Navigator.push<Task>(
      context,
      MaterialPageRoute(
        builder: (context) => TaskEditScreen(task: task),
      ),
    );

    if (updatedTask != null) {
      onTaskUpdated(updatedTask);
    }
  }

  void _deleteTask(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Task',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this task?',
          style: GoogleFonts.inter(),
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
              Navigator.pop(context);
              onTaskDeleted(task.id);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red[400],
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
} 