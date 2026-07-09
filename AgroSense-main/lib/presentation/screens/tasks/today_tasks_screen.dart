import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:drift/drift.dart' hide Column;
import '../../../core/theme/app_theme.dart';
import '../../../data/local/database/app_database.dart';
import '../../../providers/repository_providers.dart';

/// Today's Tasks Screen with full CRUD operations
/// Features: Create, Edit, Complete, Delete tasks
/// Auto-filters by date and prioritizes by weather/field conditions
class TodayTasksScreen extends ConsumerStatefulWidget {
  const TodayTasksScreen({super.key});

  @override
  ConsumerState<TodayTasksScreen> createState() => _TodayTasksScreenState();
}

class _TodayTasksScreenState extends ConsumerState<TodayTasksScreen> {
  bool _isLoading = true;
  List<Task> _todayTasks = [];
  List<Task> _prioritizedTasks = [];
  String? _error;
  Map<String, dynamic>? _weatherData;

  @override
  void initState() {
    super.initState();
    _loadTodayTasks();
  }

  Future<void> _loadTodayTasks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final database = ref.read(databaseProvider);
      final authRepo = ref.read(authRepositoryProvider);
      
      final userId = await authRepo.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Load today's tasks
      final today = DateTime.now();
      final tasks = await database.getTasksByDate(userId, today);

      // Load weather data for prioritization
      try {
        final weatherRepo = ref.read(weatherRepositoryProvider);
        // Try to get location - fallback to default if permission denied
        _weatherData = await weatherRepo.getWeatherData(11.0168, 76.9558); // Coimbatore
      } catch (e) {
        // Continue without weather data
        _weatherData = null;
      }

      // Prioritize tasks based on weather and field conditions
      final prioritized = _prioritizeTasks(tasks, _weatherData);

      setState(() {
        _todayTasks = tasks;
        _prioritizedTasks = prioritized;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Prioritize tasks based on weather conditions and field data
  List<Task> _prioritizeTasks(List<Task> tasks, Map<String, dynamic>? weather) {
    final prioritized = List<Task>.from(tasks);
    
    prioritized.sort((a, b) {
      // 1. Completed tasks go to bottom
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }

      // 2. High priority tasks first
      if (a.priority != b.priority) {
        return b.priority.compareTo(a.priority);
      }

      // 3. Weather-dependent tasks prioritization
      if (weather != null) {
        final aWeatherPriority = _getWeatherPriority(a, weather);
        final bWeatherPriority = _getWeatherPriority(b, weather);
        if (aWeatherPriority != bWeatherPriority) {
          return bWeatherPriority.compareTo(aWeatherPriority);
        }
      }

      // 4. Earlier due time first
      return a.dueDate.compareTo(b.dueDate);
    });

    return prioritized;
  }

  /// Calculate weather-based priority for a task
  int _getWeatherPriority(Task task, Map<String, dynamic> weather) {
    final temp = weather['temperature'] as double?;
    final precipitation = weather['precipitation'] as double? ?? 0.0;
    final taskType = task.taskType.toLowerCase();

    // Rain today - prioritize indoor tasks, deprioritize outdoor
    if (precipitation > 0) {
      if (taskType.contains('spray') || taskType.contains('fertilizer')) {
        return -10; // Don't spray in rain
      }
      if (taskType.contains('harvest') || taskType.contains('storage')) {
        return 5; // Good time for indoor work
      }
    }

    // Hot day - prioritize morning watering
    if (temp != null && temp > 32) {
      if (taskType.contains('water') || taskType.contains('irrigation')) {
        return 10; // Critical in hot weather
      }
    }

    // Cool day - good for physical work
    if (temp != null && temp < 25) {
      if (taskType.contains('planting') || taskType.contains('weeding')) {
        return 5; // Pleasant weather for field work
      }
    }

    return 0; // Normal priority
  }

  Future<void> _toggleTaskCompletion(Task task) async {
    try {
      final database = ref.read(databaseProvider);
      
      if (!task.isCompleted) {
        // Mark as completed
        await database.completeTask(task.id);
      } else {
        // Mark as incomplete (reopen)
        await database.updateTask(TasksCompanion(
          id: Value(task.id),
          isCompleted: const Value(false),
          completedAt: const Value(null),
          updatedAt: Value(DateTime.now()),
          isSynced: const Value(false),
        ),);
      }
      
      await _loadTodayTasks();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(!task.isCompleted ? 'Task completed!' : 'Task reopened'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteTask(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final database = ref.read(databaseProvider);
      // Soft delete by updating isDeleted flag
      await database.updateTask(TasksCompanion(
        id: Value(task.id),
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now()),
        isSynced: const Value(false),
      ),);
      await _loadTodayTasks();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task deleted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddTaskDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTaskSheet(
        onTaskAdded: _loadTodayTasks,
      ),
    );
  }

  void _showEditTaskDialog(Task task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditTaskSheet(
        task: task,
        onTaskUpdated: _loadTodayTasks,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Today\'s Tasks'),
        actions: [
          if (_weatherData != null)
            Padding(
              padding: EdgeInsets.only(right: 16.w),
              child: Center(
                child: Text(
                  '${_weatherData!['temperature']?.toStringAsFixed(1) ?? ''}°C',
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTodayTasks,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTaskDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.sp, color: AppColors.error),
            SizedBox(height: 16.h),
            Text(_error!, textAlign: TextAlign.center),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: _loadTodayTasks,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_prioritizedTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64.sp, color: AppColors.success),
            SizedBox(height: 16.h),
            const Text('No tasks for today!', style: AppTextStyles.h3),
            SizedBox(height: 8.h),
            const Text('Tap + to add a new task', style: AppTextStyles.bodyMedium),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTodayTasks,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: _prioritizedTasks.length + (_weatherData != null ? 1 : 0),
        itemBuilder: (context, index) {
          // Weather banner at top
          if (_weatherData != null && index == 0) {
            return _buildWeatherBanner();
          }

          final taskIndex = _weatherData != null ? index - 1 : index;
          final task = _prioritizedTasks[taskIndex];
          return _buildTaskCard(task);
        },
      ),
    );
  }

  Widget _buildWeatherBanner() {
    final temp = _weatherData!['temperature'];
    final desc = _weatherData!['description'] ?? '';
    final icon = _weatherData!['icon'] ?? '☀️';

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.info.withOpacity(0.7), AppColors.info],
        ),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Text(icon, style: TextStyle(fontSize: 32.sp)),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${temp?.toStringAsFixed(1)}°C - $desc',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Tasks prioritized by weather conditions',
                  style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    final timeString = '${task.dueDate.hour.toString().padLeft(2, '0')}:${task.dueDate.minute.toString().padLeft(2, '0')}';
    
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      child: InkWell(
        onTap: () => _showEditTaskDialog(task),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: task.isCompleted,
                    onChanged: (_) => _toggleTaskCompletion(task),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        if (task.description != null)
                          Text(
                            task.description!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: AppColors.error,
                    onPressed: () => _deleteTask(task),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  _buildTaskChip(Icons.access_time, timeString),
                  SizedBox(width: 8.w),
                  _buildTaskChip(Icons.label_outline, task.taskType),
                  if (task.priority > 0) ...[
                    SizedBox(width: 8.w),
                    _buildPriorityChip(task.priority),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskChip(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: AppColors.textSecondary),
          SizedBox(width: 4.w),
          Text(label, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }

  Widget _buildPriorityChip(int priority) {
    final color = priority >= 8 ? AppColors.error : priority >= 5 ? AppColors.warning : AppColors.info;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag, size: 14.sp, color: color),
          SizedBox(width: 4.w),
          Text('P$priority', style: AppTextStyles.bodySmall.copyWith(color: color)),
        ],
      ),
    );
  }
}

/// Add Task Bottom Sheet
class AddTaskSheet extends ConsumerStatefulWidget {
  final VoidCallback onTaskAdded;

  const AddTaskSheet({super.key, required this.onTaskAdded});

  @override
  ConsumerState<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends ConsumerState<AddTaskSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _taskType = 'Watering';
  int _priority = 5;
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isSubmitting = false;

  final List<String> _taskTypes = [
    'Watering',
    'Fertilizing',
    'Pest Control',
    'Weeding',
    'Harvesting',
    'Planting',
    'Pruning',
    'Other',
  ];

  Future<void> _submitTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final database = ref.read(databaseProvider);
      final authRepo = ref.read(authRepositoryProvider);
      final userId = await authRepo.getCurrentUserId();

      if (userId == null) throw Exception('User not logged in');

      final now = DateTime.now();
      final dueDate = DateTime(
        now.year,
        now.month,
        now.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final taskId = DateTime.now().millisecondsSinceEpoch.toString();
      
      final taskCompanion = TasksCompanion(
        id: Value(taskId),
        userId: Value(userId),
        fieldId: const Value(null),
        title: Value(_titleController.text.trim()),
        description: Value(_descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim()),
        taskType: Value(_taskType),
        dueDate: Value(dueDate),
        priority: Value(_priority),
        isCompleted: const Value(false),
        createdAt: Value(now),
        updatedAt: Value(now),
        completedAt: const Value(null),
        isSynced: const Value(false),
        isDeleted: const Value(false),
      );

      await database.insertTask(taskCompanion);
      
      if (!mounted) return;
      Navigator.pop(context);
      widget.onTaskAdded();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task created successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        top: 16.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16.h,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Text('Add New Task', style: AppTextStyles.h3),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Task Title *',
                  hintText: 'e.g., Water Field A',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a task title';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.h),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Additional details',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 16.h),
              DropdownButtonFormField<String>(
                initialValue: _taskType,
                decoration: const InputDecoration(
                  labelText: 'Task Type',
                  prefixIcon: Icon(Icons.category),
                ),
                items: _taskTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) => setState(() => _taskType = value!),
              ),
              SizedBox(height: 16.h),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Time'),
                trailing: Text(
                  _selectedTime.format(context),
                  style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                ),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: _selectedTime,
                  );
                  if (time != null) {
                    setState(() => _selectedTime = time);
                  }
                },
              ),
              SizedBox(height: 16.h),
              Text('Priority: $_priority', style: AppTextStyles.bodyMedium),
              Slider(
                value: _priority.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                label: _priority.toString(),
                onChanged: (value) => setState(() => _priority = value.toInt()),
              ),
              SizedBox(height: 24.h),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitTask,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create Task'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

/// Edit Task Bottom Sheet
class EditTaskSheet extends ConsumerStatefulWidget {
  final Task task;
  final VoidCallback onTaskUpdated;

  const EditTaskSheet({
    super.key,
    required this.task,
    required this.onTaskUpdated,
  });

  @override
  ConsumerState<EditTaskSheet> createState() => _EditTaskSheetState();
}

class _EditTaskSheetState extends ConsumerState<EditTaskSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late String _taskType;
  late int _priority;
  late TimeOfDay _selectedTime;
  bool _isSubmitting = false;

  final List<String> _taskTypes = [
    'Watering',
    'Fertilizing',
    'Pest Control',
    'Weeding',
    'Harvesting',
    'Planting',
    'Pruning',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(text: widget.task.description ?? '');
    _taskType = widget.task.taskType;
    _priority = widget.task.priority;
    _selectedTime = TimeOfDay.fromDateTime(widget.task.dueDate);
  }

  Future<void> _updateTask() async {
    setState(() => _isSubmitting = true);

    try {
      final database = ref.read(databaseProvider);
      
      final now = DateTime.now();
      final dueDate = DateTime(
        now.year,
        now.month,
        now.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final updatedTaskCompanion = TasksCompanion(
        id: Value(widget.task.id),
        title: Value(_titleController.text.trim()),
        description: Value(_descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim()),
        taskType: Value(_taskType),
        dueDate: Value(dueDate),
        priority: Value(_priority),
        updatedAt: Value(now),
        isSynced: const Value(false),
      );

      await database.updateTask(updatedTaskCompanion);
      
      if (!mounted) return;
      Navigator.pop(context);
      widget.onTaskUpdated();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        top: 16.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16.h,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Text('Edit Task', style: AppTextStyles.h3),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Task Title',
                prefixIcon: Icon(Icons.title),
              ),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 16.h),
            DropdownButtonFormField<String>(
              initialValue: _taskType,
              decoration: const InputDecoration(
                labelText: 'Task Type',
                prefixIcon: Icon(Icons.category),
              ),
              items: _taskTypes.map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (value) => setState(() => _taskType = value!),
            ),
            SizedBox(height: 16.h),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Time'),
              trailing: Text(
                _selectedTime.format(context),
                style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              ),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _selectedTime,
                );
                if (time != null) {
                  setState(() => _selectedTime = time);
                }
              },
            ),
            SizedBox(height: 16.h),
            Text('Priority: $_priority', style: AppTextStyles.bodyMedium),
            Slider(
              value: _priority.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: _priority.toString(),
              onChanged: (value) => setState(() => _priority = value.toInt()),
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _updateTask,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Update Task'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
