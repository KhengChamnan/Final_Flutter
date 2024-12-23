import 'package:flutter/material.dart';
import 'package:reminder_project/screens/form.dart';
import 'package:reminder_project/screens/reminder_list.dart';
import '../models/task.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TaskStorage _taskStorage = TaskStorage();
  List<Task> _tasks = [];

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _addTask(Task task) async {
    setState(() {
      _tasks.add(task);
    });
    await _taskStorage.saveTasks(_tasks);
  }

  Future<void> _loadTasks() async {
    final tasks = await _taskStorage.loadTasks();
    setState(() {
      _tasks = tasks;
    });
  }

  void _deleteTask(String taskId) async {
    setState(() {
      _tasks.removeWhere((task) => task.id == taskId);
    });
    await _taskStorage.saveTasks(_tasks);
  }

  Future<void> _editTask(Task task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      setState(() {
        _tasks[index] = task;
      });
      await _taskStorage.saveTasks(_tasks);
      await _loadTasks(); // Reload tasks after saving
    }
  }

  Future<void> _saveTasks() async {
    await _taskStorage.saveTasks(_tasks);
  }

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

  void _navigateToReminderList(BuildContext context, List<Task> tasks, ListMode mode) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReminderList(
          tasks: tasks,
          onTaskDeleted: (taskId) {
            _deleteTask(taskId);
            _loadTasks();
          },
          onTaskEdited: (editedTask) async {
            await _editTask(editedTask);
            setState(() {
              _loadTasks();
            });
          },
          mode: mode, // Add mode parameter
        ),
      ),
    );
  }

  List<Task> get _overdueTasks {
    final now = DateTime.now();
    return _tasks.where((task) {
      // Convert task's date and preferred time to DateTime
      final taskDateTime = DateTime(
        task.dueDate.year,
        task.dueDate.month,
        task.dueDate.day,
        task.preferredTime?.hour ?? 0,
        task.preferredTime?.minute ?? 0,
      );
      
      // Compare with current date and time
      return taskDateTime.isBefore(now);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Tasks',
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
            Text(
              '${_tasks.length} tasks pending',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
        actions: const [
          CircleAvatar(
            backgroundColor: Colors.blue,
            child: Icon(Icons.person, color: Colors.white),
          ),
          SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      _navigateToReminderList(context, _tasks, ListMode.all);
                    },
                    child: _buildCategoryCard(
                      'All', Icons.list_alt, Colors.blue, _tasks.length),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      final todayTasks = _tasks.where((task) =>
                        task.dueDate.day == DateTime.now().day &&
                        task.dueDate.month == DateTime.now().month &&
                        task.dueDate.year == DateTime.now().year).toList();
                      _navigateToReminderList(context, todayTasks, ListMode.all);
                    },
                    child: _buildCategoryCard(
                      'Today',
                      Icons.today,
                      Colors.orange,
                      _tasks.where((task) =>
                        task.dueDate.day == DateTime.now().day &&
                        task.dueDate.month == DateTime.now().month &&
                        task.dueDate.year == DateTime.now().year).length),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      final upcomingTasks = _tasks.where(
                        (task) => task.dueDate.isAfter(DateTime.now())).toList();
                      _navigateToReminderList(context, upcomingTasks, ListMode.all);
                    },
                    child: _buildCategoryCard(
                      'Upcoming',
                      Icons.calendar_today,
                      Colors.purple,
                      _tasks.where(
                        (task) => task.dueDate.isAfter(DateTime.now())).length),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      final overdueTasks = _overdueTasks;
                      _navigateToReminderList(context, overdueTasks, ListMode.overdue);
                    },
                    child: _buildCategoryCard(
                      "Overdue",
                      Icons.warning,
                      Colors.red,
                      _overdueTasks.length),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  width: 184,
                  height: 96,
                  child: GestureDetector(
                    onTap: () {
                      final completedTasks = _tasks.where(
                        (task) => task.isCompleted).toList();
                      _navigateToReminderList(context, completedTasks, ListMode.all);
                    },
                    child: _buildCategoryCard(
                      'Completed',
                      Icons.check,
                      Colors.green,
                      _tasks.where((task) => task.isCompleted).length,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ReminderForm(onSubmit: _addTask, mode: FormMode.create)),
          );
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.analytics), label: 'Progress'),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
      String title, IconData icon, Color color, int count) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text('$count'),
        ],
      ),
    );
  }
}
