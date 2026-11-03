import 'package:flutter/material.dart';

import 'fitTrackDatabase.dart';

/// Collects, validates, confirms, and saves a workout record.
class NewFitTrack extends StatefulWidget {
  final Map<String, dynamic>? workout;

  const NewFitTrack({super.key, this.workout});

  @override
  State<NewFitTrack> createState() => _NewFitTrackState();
}

class _NewFitTrackState extends State<NewFitTrack> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _durationController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _workoutCategory;
  DateTime? _workoutDate;
  bool _isSaving = false;

  bool get _isEditing => widget.workout != null;

  static const List<String> _workoutCategories = [
    'Cardio',
    'Strength Training',
    'HIIT',
    'Yoga',
    'Pilates',
    'Flexibility',
    'Bodyweight',
    'Cycling',
    'Walking',
    'Sports',
    'Other',
  ];

  @override
  void initState() {
    super.initState();

    // Fill in existing workout information when editing.
    if (_isEditing) {
      _nameController.text = widget.workout!['workout_name'];
      _workoutCategory = widget.workout!['category'];
      _durationController.text = widget.workout!['duration'].toString();
      _workoutDate = DateTime.parse(widget.workout!['workout_date']);
      _descriptionController.text = widget.workout!['notes'] ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Select workout date.
  Future<void> _selectWorkoutDate(FormFieldState<DateTime> field) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _workoutDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (selectedDate == null) return;

    setState(() => _workoutDate = selectedDate);
    field.didChange(selectedDate);
  }

  Future<void> _confirmWorkoutEntry() async {
    // Do not ask for confirmation until required fields pass validation.
    if (!_formKey.currentState!.validate()) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _isEditing ? 'Confirm workout update' : 'Confirm workout entry',
        ),
        content: Text(
          _isEditing
              ? 'Update this workout record?'
              : 'Save this workout record?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Save workout information into SQLite.
    setState(() => _isSaving = true);

    var saved = false;

    try {
      final workout = {
        'workout_name': _nameController.text.trim(),
        'category': _workoutCategory!,
        'duration': int.parse(_durationController.text.trim()),
        'workout_date':
            '${_workoutDate!.year.toString().padLeft(4, '0')}-'
            '${_workoutDate!.month.toString().padLeft(2, '0')}-'
            '${_workoutDate!.day.toString().padLeft(2, '0')}',
        'notes': _descriptionController.text.trim(),
      };

      if (_isEditing) {
        await FitTrackDatabase.instance.updateWorkout(
          widget.workout!['id'],
          workout,
        );
      } else {
        await FitTrackDatabase.instance.insertWorkout(workout);
      }

      saved = true;
    } catch (_) {
      saved = false;
    }

    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);

    Navigator.of(context).pop(saved);

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? _isEditing
                    ? 'Workout updated successfully'
                    : 'Workout saved successfully'
              : 'Failed to save workout',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Workout' : 'New Workout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Workout Information',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 16),

              // Workout name.
              TextFormField(
                controller: _nameController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter workout name';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'Workout name',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              // Workout category.
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Workout category',
                  border: OutlineInputBorder(),
                ),
                value: _workoutCategory,
                validator: (value) =>
                    value == null ? 'Select a workout category' : null,
                items: _workoutCategories
                    .map(
                      (category) => DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() => _workoutCategory = value);
                },
              ),

              const SizedBox(height: 16),

              // Workout duration.
              TextFormField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  final duration = int.tryParse(value?.trim() ?? '');

                  if (duration == null) {
                    return 'Enter a valid duration';
                  }

                  if (duration <= 0) {
                    return 'Duration must be greater than zero';
                  }

                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'Duration (Minutes)',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              // Workout date.
              FormField<DateTime>(
                validator: (value) {
                  if (value == null) {
                    return 'Select a workout date';
                  }
                  return null;
                },
                initialValue: _workoutDate,
                builder: (field) => InkWell(
                  onTap: () => _selectWorkoutDate(field),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Workout date',
                      border: const OutlineInputBorder(),
                      errorText: field.errorText,
                      suffixIcon: const Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _workoutDate == null
                          ? 'Select date'
                          : '${_workoutDate!.day}/'
                                '${_workoutDate!.month}/'
                                '${_workoutDate!.year}',
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Optional description.
              TextFormField(
                controller: _descriptionController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 24),

              // Add or update workout button.
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Color(0xFF2E6B4F),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _isSaving ? null : _confirmWorkoutEntry,
                  child: Text(
                    _isSaving
                        ? 'Saving...'
                        : _isEditing
                        ? 'Update Workout'
                        : 'Add Workout',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
