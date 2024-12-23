import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:reminder_project/screens/form.dart';
import '../models/task.dart';
import 'package:intl/intl.dart';

Color _getPriorityColor(Priority priority) {
  switch (priority) {
    case Priority.high:
      return Colors.red;
    case Priority.medium:
      return Colors.orange;
    case Priority.low:
      return Colors.green;
  }
}

class ReminderList extends StatefulWidget {
  final List<Task> tasks;
  final Function(String) onTaskDeleted;
  final Function(Task) onTaskEdited;

  const ReminderList({
    super.key,
    required this.tasks,
    required this.onTaskDeleted,
    required this.onTaskEdited,
  });

   bool _isOverdue(Task task) {
    final now = DateTime.now();
    final taskDateTime = DateTime(
      task.dueDate.year,
      task.dueDate.month,
      task.dueDate.day,
      task.preferredTime?.hour ?? 0,
      task.preferredTime?.minute ?? 0,
    );
    return taskDateTime.isBefore(now);
  }


  @override
  State<ReminderList> createState() => _ReminderListState();
}

class _ReminderListState extends State<ReminderList> {
  void _deleteTask(String taskId) {
    setState(() {
      widget.tasks.removeWhere((task) => task.id == taskId);
    });
    widget.onTaskDeleted(taskId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reminder List"),
        backgroundColor: Colors.blue,
      ),
      body: widget.tasks.isEmpty
          ? const Center(child: Text("No tasks available"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.tasks.length,
              itemBuilder: (context, index) {
                final task = widget.tasks[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Slidable(
                    key: Key(task.id),
                    endActionPane: ActionPane(
                      motion: const ScrollMotion(),
                      children: [
                        SlidableAction(
                          onPressed: (context) async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ReminderForm(
                                  task: task,
                                  onSubmit: (editedTask) {
                                    widget.onTaskEdited(editedTask);
                                    // Update local state
                                    setState(() {
                                      final index = widget.tasks.indexWhere((t) => t.id == editedTask.id);
                                      if (index != -1) {
                                        widget.tasks[index] = editedTask;
                                      }
                                    });
                                   
                                  },
                                  mode: FormMode.edit,
                                ),
                              ),
                            );
                            if (result == true) {
                              setState(() {}); // Force refresh UI
                            }
                          },
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          icon: Icons.edit,
                          label: 'Edit',
                        ),
                        SlidableAction(
                          onPressed: (context) {
                            _deleteTask(task.id);
                          },
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          icon: Icons.delete,
                          label: 'Delete',
                        ),
                      ],
                    ),
                    child: Remind_Card(task: task),
                  ),
                );
              },
            ),
    );
  }
}

class Remind_Card extends StatelessWidget {
  const Remind_Card({
    super.key,
    required this.task,
  });

  final Task task;

  @override
  Widget build(BuildContext context) {
    final String formattedDate = DateFormat('dd/MM/yyyy').format(task.dueDate);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 80, // Adjust the height as needed
            color: _getPriorityColor(task.priority),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ListTile(
              title: Text(task.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 20)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (task.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(task.description),
                  ],
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16),
                      const SizedBox(width: 4),
                      Text(formattedDate),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16),
                      const SizedBox(width: 4),
                      Text(task.preferredTime != null
                          ? task.preferredTime!.format(context)
                          : 'No time set'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
