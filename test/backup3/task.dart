import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
enum Priority { low, medium, high }
enum RecurrenceInterval { none, daily, weekly, monthly }
enum FormMode {
  create,
  edit,
}
enum ListMode { 
  all, 
  overdue, 
  today, 
  upcoming,
  completed
}
class Task {
  String id; // UUID will be used here
  String title;
  String description;
  Priority priority;
  DateTime dueDate;
  bool isCompleted;
  DateTime createdAt;
  bool recurring;
  RecurrenceInterval recurrenceInterval;
  int streak;
  TimeOfDay? preferredTime;

  Task({
    String? id,
    required this.title,
    required this.description,
    required this.priority,
    required this.dueDate,
    this.isCompleted = false,
    required this.createdAt,
    this.recurring = false,
    this.recurrenceInterval = RecurrenceInterval.none,
    this.streak = 0,
    required this.preferredTime,
  }) : id = id ?? const Uuid().v4();

  @override
  String toString() {
    return "Task(id: $id, title: $title, priority: $priority, dueDate: $dueDate, isCompleted: $isCompleted, preferredTime: $preferredTime)";
  }

  /// Calculate the duration between createdAt and dueDate
  String getDuration() {
    final duration = dueDate.difference(createdAt);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    return '$hours hours, $minutes minutes';
  }

  /// Convert priority to a readable string
  String getPriorityString() {
    switch (priority) {
      case Priority.low:
        return 'Low';
      case Priority.medium:
        return 'Medium';
      case Priority.high:
        return 'High';
    }
  }

  /// Convert Task to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority.toString(),
      'dueDate': dueDate.toIso8601String(),
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'recurring': recurring,
      'recurrenceInterval': recurrenceInterval.toString(),
      'streak': streak,
      'preferredTime': preferredTime != null
          ? {'hour': preferredTime!.hour, 'minute': preferredTime!.minute}
          : null,
    };
  }

  /// Create Task from JSON
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      priority: Priority.values.firstWhere((e) => e.toString() == json['priority']),
      dueDate: DateTime.parse(json['dueDate']),
      isCompleted: json['isCompleted'],
      createdAt: DateTime.parse(json['createdAt']),
      recurring: json['recurring'],
      recurrenceInterval: RecurrenceInterval.values.firstWhere((e) => e.toString() == json['recurrenceInterval']),
      streak: json['streak'],
      preferredTime: json['preferredTime'] != null
          ? TimeOfDay(hour: json['preferredTime']['hour'], minute: json['preferredTime']['minute'])
          : null,
    );
  }
}

class TaskHistory {
  String id;
  String taskId;
  DateTime completionDate;

  TaskHistory({
    String? id,
    required this.taskId,
    required this.completionDate,
  }) : id = id ?? const Uuid().v4();
}

class Progress {
  int totalTasksCreated;
  int tasksCompleted;
  int streak;
  DateTime? lastCompletionDate;

  Progress({
    this.totalTasksCreated = 0,
    this.tasksCompleted = 0,
    this.streak = 0,
    this.lastCompletionDate,
  });
}

class Quote {
  String id;
  String text;
  String? author;

  Quote({
    String? id,
    required this.text,
    this.author,
  }) : id = id ?? const Uuid().v4();
}

class TaskStorage {
  static const String _tasksKey = 'tasks';

  Future<void> saveTasks(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = tasks.map((task) => jsonEncode(task.toJson())).toList();
    await prefs.setStringList(_tasksKey, tasksJson);
  }

  Future<List<Task>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getStringList(_tasksKey);
    if (tasksJson == null) {
      return [];
    }
    return tasksJson.map((taskJson) => Task.fromJson(jsonDecode(taskJson))).toList();
  }
}
