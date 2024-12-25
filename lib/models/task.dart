import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

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


class Quote {
  String id;
  String text;
  String? author;

  Quote({
    String? id,
    required this.text,
    this.author,
  }) : id = id ?? const Uuid().v4();

  // Static list of motivational quotes
  static final List<Quote> quotes = [
    Quote(text: "The only way to do great work is to love what you do.", author: "Steve Jobs"),
    Quote(text: "Don't watch the clock; do what it does. Keep going.", author: "Sam Levenson"),
    Quote(text: "Success is not final, failure is not fatal.", author: "Winston Churchill"),
    Quote(text: "The future depends on what you do today.", author: "Mahatma Gandhi"),
    Quote(text: "Your time is limited, don't waste it living someone else's life.", author: "Steve Jobs"),
    Quote(text: "The way to get started is to quit talking and begin doing.", author: "Walt Disney"),
    Quote(text: "Everything you've ever wanted is on the other side of fear.", author: "George Addair"),
    Quote(text: "Success usually comes to those who are too busy to be looking for it.", author: "Henry David Thoreau"),
    Quote(text: "The only limit to our realization of tomorrow will be our doubts of today.", author: "Franklin D. Roosevelt"),
    Quote(text: "Do what you can, with what you have, where you are.", author: "Theodore Roosevelt"),
  ];

  // Method to get random quote
  static Quote getRandomQuote() {
    final random = Random();
    return quotes[random.nextInt(quotes.length)];
  }
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
