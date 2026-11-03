import 'package:flutter/material.dart';

import 'fitTrackDatabase.dart';
import 'newFitTrack.dart';

/// Shows saved workout records and manages workout activities.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const int _pageSize = 10;

  List<Map<String, dynamic>> _workouts = [];
  bool _isLoading = true;
  bool _loadFailed = false;
  int _currentPage = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  // Load workout records from SQLite.
  Future<void> _loadWorkouts({int page = 1}) async {
    setState(() {
      _isLoading = true;
      _loadFailed = false;
    });

    try {
      final count = await FitTrackDatabase.instance.getWorkoutCount();
      final totalPages = (count / _pageSize).ceil().clamp(1, 1 << 31).toInt();

      final targetPage = page.clamp(1, totalPages).toInt();

      final workouts = await FitTrackDatabase.instance.getWorkouts(targetPage);

      if (!mounted) return;

      setState(() {
        _workouts = workouts;
        _isLoading = false;
        _currentPage = targetPage;
        _totalPages = totalPages;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadFailed = true;
      });
    }
  }

  // Open new workout form.
  Future<void> _openNewWorkoutPage() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (context) => const NewFitTrack()),
    );

    if (saved == true) await _loadWorkouts(page: 1);
  }

  // Confirm workout deletion.
  Future<void> _confirmDeleteWorkout(Map<String, dynamic> workout) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete workout?'),
        content: const Text('This workout will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);

    try {
      final deleted = await FitTrackDatabase.instance.deleteWorkout(
        workout['id'] as int,
      );

      if (!mounted) return;

      await _loadWorkouts(page: _currentPage);

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            deleted > 0
                ? 'Workout deleted successfully'
                : 'Workout could not be deleted',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to delete workout')),
      );
    }
  }

  // Show workout details.
  Future<void> _showWorkoutDetails(Map<String, dynamic> workout) async {
    final createdAt = DateTime.tryParse(workout['created_at'] as String);

    final formattedDate = createdAt == null
        ? workout['created_at'] as String
        : createdAt.toLocal().toString().split('.').first;

    final edit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(workout['workout_name'] as String),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Category', workout['category'] as String),
              _detailRow('Duration', '${workout['duration']} minutes'),
              _detailRow('Workout Date', workout['workout_date'] as String),
              _detailRow(
                'Description',
                (workout['notes'] as String?)?.isEmpty ?? true
                    ? 'No description'
                    : workout['notes'] as String,
              ),
              _detailRow('Created', formattedDate),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Edit'),
          ),
        ],
      ),
    );

    if (edit != true || !mounted) return;

    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => NewFitTrack(workout: workout),
      ),
    );

    if (saved == true) {
      await _loadWorkouts(page: _currentPage);
    }
  }

  // Display workout details.
  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student FitTrack'),
        actions: [
          IconButton(
            tooltip: 'Refresh workouts',
            onPressed: _isLoading
                ? null
                : () => _loadWorkouts(page: _currentPage),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildBody()),
          if (!_isLoading && !_loadFailed && _workouts.isNotEmpty)
            _buildPaginationControls(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openNewWorkoutPage,
        child: const Icon(Icons.add),
      ),
    );
  }

  // Bottom pagination controls.
  Widget _buildPaginationControls() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: 'Previous page',
              onPressed: _currentPage > 1 && !_isLoading
                  ? () => _loadWorkouts(page: _currentPage - 1)
                  : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Text('Page $_currentPage of $_totalPages'),
            IconButton(
              tooltip: 'Next page',
              onPressed: _currentPage < _totalPages && !_isLoading
                  ? () => _loadWorkouts(page: _currentPage + 1)
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }

  // Display loading, error, empty state or workout list.
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadFailed) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Could not load workouts.'),
            TextButton(
              onPressed: () => _loadWorkouts(page: _currentPage),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_workouts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center, size: 80, color: Color(0xFF2E6B4F)),

            const SizedBox(height: 15),

            const Text('No Workouts Yet'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _workouts.length,
      itemBuilder: (context, index) {
        final workout = _workouts[index];

        return ListTile(
          onTap: () => _showWorkoutDetails(workout),
          onLongPress: () => _confirmDeleteWorkout(workout),

          leading: const CircleAvatar(
            backgroundColor: Color.fromARGB(255, 198, 231, 201),
            child: Icon(Icons.fitness_center, color: Color(0xFF00695C)),
          ),

          title: Text(
            workout['workout_name'] as String,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color.fromARGB(255, 0, 0, 0),
            ),
          ),

          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                workout['category'] as String,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color.fromARGB(255, 51, 87, 56),
                ),
              ),

              Text(
                (workout['notes'] as String?)?.isNotEmpty == true
                    ? workout['notes'] as String
                    : 'No description',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color.fromARGB(255, 114, 115, 112),
                ),
              ),
            ],
          ),

          trailing: Text(
            '${workout['duration']} min',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF00796B),
            ),
          ),
        );
      },
    );
  }
}
