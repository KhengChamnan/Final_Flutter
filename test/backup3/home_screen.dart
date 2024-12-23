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

  Future<void> _markTaskAsCompleted(Task task) async {
  final index = _tasks.indexWhere((t) => t.id == task.id);
  if (index != -1) {
    setState(() {
      _tasks[index] = task;
    });
    await _taskStorage.saveTasks(_tasks);
  }
}

void _navigateToReminderList(BuildContext context, List<Task> tasks, ListMode mode) {
  List<Task> filteredTasks;
  switch (mode) {
    case ListMode.overdue:
      filteredTasks = _getOverdueTasks();
      break;
    case ListMode.completed:
      filteredTasks = tasks.where((task) => task.isCompleted).toList();
      break;
    case ListMode.today:
      filteredTasks = tasks.where((task) => 
        !task.isCompleted && 
        _isToday(task) && 
        !_getOverdueTasks().any((t) => t.id == task.id)
      ).toList();
      break;
    case ListMode.upcoming:
      filteredTasks = tasks.where((task) => !task.isCompleted && _isUpcoming(task)).toList();
      break;
    case ListMode.all:
      filteredTasks = tasks.where((task) => !task.isCompleted).toList();
      break;
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ReminderList(
        tasks: filteredTasks,
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
        onTaskCompleted: (completedTask) async {
          await _markTaskAsCompleted(completedTask);
          setState(() {
            _loadTasks();
          });
        },
        mode: mode,
      ),
    ),
  );
}

// Add helper methods for date checking
bool _isOverdue(Task task) {
  final now = DateTime.now();
  return task.dueDate.isBefore(DateTime(now.year, now.month, now.day));
}

bool _isToday(Task task) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final taskDate = DateTime(
    task.dueDate.year,
    task.dueDate.month,
    task.dueDate.day,
  );
  return taskDate.isAtSameMomentAs(today);
}

bool _isUpcoming(Task task) {
  final now = DateTime.now();
  return task.dueDate.isAfter(DateTime(now.year, now.month, now.day));
}

List<Task> _getOverdueTasks() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return _tasks.where((task) {
    if (task.isCompleted) return false;
    final taskDate = DateTime(
      task.dueDate.year,
      task.dueDate.month,
      task.dueDate.day,
    );
    return taskDate.isBefore(today);
  }).toList();
}

  List<Task> _getTodayTasks() {
    final now = DateTime.now();
    return _tasks.where((task) =>
      task.dueDate.year == now.year &&
      task.dueDate.month == now.month &&
      task.dueDate.day == now.day
    ).toList();
  }

  List<Task> _getUpcomingTasks() {
    final now = DateTime.now();
    return _tasks.where((task) {
      final taskDateTime = DateTime(
        task.dueDate.year,
        task.dueDate.month,
        task.dueDate.day,
        task.preferredTime?.hour ?? 0,
        task.preferredTime?.minute ?? 0,
      );
      return taskDateTime.isAfter(now);
    }).toList();
  }

  // Add this helper method alongside other filter methods
  List<Task> _getCompletedTasks() {
    return _tasks.where((task) => task.isCompleted).toList();
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
                      'All', Icons.list_alt, Colors.blue, _tasks.where((task) => !task.isCompleted).length),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      _navigateToReminderList(context, _getTodayTasks(), ListMode.today);
                    },
                    child: _buildCategoryCard(
                      'Today',
                      Icons.today,
                      Colors.orange,
                      _getTodayTasks().where((task) => !task.isCompleted).length),
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
                      _navigateToReminderList(context, _getUpcomingTasks(), ListMode.upcoming);
                    },
                    child: _buildCategoryCard(
                      'Upcoming',
                      Icons.calendar_today,
                      Colors.purple,
                      _getUpcomingTasks().where((task) => !task.isCompleted).length),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      _navigateToReminderList(context, _getOverdueTasks(), ListMode.overdue);
                    },
                    child: _buildCategoryCard(
                      "Overdue",
                      Icons.warning,
                      Colors.red,
                      _getOverdueTasks().where((task) => !task.isCompleted).length),
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
  onTap: () => _navigateToReminderList(
    context,
    _getCompletedTasks(),
    ListMode.completed
  ),
  child: _buildCategoryCard(
    'Completed',
    Icons.done_all,
    Colors.green,
    _getCompletedTasks().length
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
