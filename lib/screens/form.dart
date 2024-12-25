import 'package:flutter/material.dart';
import '../models/task.dart';

class ReminderForm extends StatefulWidget {
  final Function(Task) onSubmit;
  final Task? task;
  final FormMode mode;

  const ReminderForm({
    super.key,
    required this.onSubmit,
    this.task,
    required this.mode
  });

  @override
  State<ReminderForm> createState() => _ReminderFormState();
}

class _ReminderFormState extends State<ReminderForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  Priority _priority = Priority.medium;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _preferredTime = TimeOfDay.now();
  bool _recurring = false;
  RecurrenceInterval _recurrenceInterval = RecurrenceInterval.none;

  @override
  void initState() {
    super.initState();
    print('Form mode: ${widget.mode}');
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description;
      _priority = widget.task!.priority;
      _dueDate = widget.task!.dueDate;
      _preferredTime = widget.task!.preferredTime!;
      _recurring = widget.task!.recurring;
      _recurrenceInterval = widget.task!.recurrenceInterval;
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _preferredTime,
    );
    if (picked != null) setState(() => _preferredTime = picked);
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final task = Task(
        id: widget.task?.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        priority: _priority,
        dueDate: _dueDate,
        createdAt: widget.task?.createdAt ?? DateTime.now(),
        recurring: _recurring,
        recurrenceInterval: _recurrenceInterval,
        preferredTime: _preferredTime,
      );
    widget.onSubmit(task);
    if (widget.mode == FormMode.edit) {
      Navigator.pop(context, true); // Return to reminder list
    } else {
      Navigator.popUntil(context, (route) => route.isFirst); // Return to home screen
    }
    }
  }

  void _resetForm(){
    _formKey.currentState!.reset();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mode==FormMode.create?'Create New Task':'Edit Mode'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter a title' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Priority>(
              value: _priority,
              decoration: const InputDecoration(
                labelText: 'Priority',
                border: OutlineInputBorder(),
              ),
              items: Priority.values.map((priority) {
                return DropdownMenuItem(
                  value: priority,
                  child: Text(priority.toString().split('.').last),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _priority = value);
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Due Date'),
              subtitle: Text(_dueDate.toString().split(' ')[0]),
              trailing: const Icon(Icons.calendar_today),
              onTap: _selectDate,
            ),
            ListTile(
              title: const Text('Preferred Time'),
              subtitle: Text(_preferredTime.format(context)),
              trailing: const Icon(Icons.access_time),
              onTap: _selectTime,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Recurring'),
              value: _recurring,
              onChanged: (value) {
                setState(() {
                  _recurring = value;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<RecurrenceInterval>(
              value: _recurrenceInterval,
              items: RecurrenceInterval.values.map((interval) {
                return DropdownMenuItem(
                  value: interval,
                  child: Text(interval.toString().split('.').last),
                );
              }).toList(),
              onChanged: _recurring ? (value) {
                if (value != null) setState(() => _recurrenceInterval = value);
              } : null,
              decoration: InputDecoration(
                labelText: 'Recurrence Interval',
                border: OutlineInputBorder(),
                enabled: _recurring,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(onPressed: _resetForm, child: const Text('Reset')),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _submitForm, child: const Text('Submit')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}