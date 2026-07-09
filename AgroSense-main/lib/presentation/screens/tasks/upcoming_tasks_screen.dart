import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:drift/drift.dart' as drift hide Column;
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/local/database/app_database.dart';
import '../../../providers/repository_providers.dart';

class UpcomingTasksScreen extends ConsumerStatefulWidget {
  const UpcomingTasksScreen({super.key});

  @override
  ConsumerState<UpcomingTasksScreen> createState() => _UpcomingTasksScreenState();
}

class _UpcomingTasksScreenState extends ConsumerState<UpcomingTasksScreen> {
  bool _isLoading = true;
  List<Task> _tasks = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUpcomingTasks();
  }

  Future<void> _loadUpcomingTasks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final database = ref.read(databaseProvider);
      final userId = await ref.read(currentUserIdProvider.future);
      
      if (userId == null || userId.isEmpty) {
        throw Exception('User not logged in');
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final allTasks = await database.watchTasksByUserId(userId).first;
      
      // Filter upcoming tasks (not completed, not deleted, due date is in the future)
      final tasks = allTasks.where((task) => 
        !task.isCompleted && 
        !task.isDeleted && 
        task.dueDate.isAfter(today),
      ).toList();

      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleTaskCompletion(Task task) async {
    try {
      final database = ref.read(databaseProvider);
      
      if (!task.isCompleted) {
        await database.completeTask(task.id);
      } else {
        await database.updateTask(TasksCompanion(
          id: drift.Value(task.id),
          isCompleted: const drift.Value(false),
          completedAt: const drift.Value(null),
          updatedAt: drift.Value(DateTime.now()),
          isSynced: const drift.Value(false),
        ),);
      }
      
      await _loadUpcomingTasks();

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
      // Soft delete - mark as deleted
      await database.updateTask(
        TasksCompanion(
          id: drift.Value(task.id),
          isDeleted: const drift.Value(true),
          updatedAt: drift.Value(DateTime.now()),
        ),
      );
      await _loadUpcomingTasks();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task deleted successfully')),
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

  void _showEditTaskDialog(Task task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditTaskSheet(
        task: task,
        onTaskUpdated: _loadUpcomingTasks,
      ),
    );
  }

  void _showAddTaskDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTaskSheet(
        onTaskAdded: _loadUpcomingTasks,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upcoming Tasks'),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        child: const Icon(Icons.add),
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
            Text('Error: $_error', style: AppTextStyles.bodyMedium),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: _loadUpcomingTasks,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64.sp, color: AppColors.success),
            SizedBox(height: 16.h),
            const Text('No upcoming tasks', style: AppTextStyles.h3),
            SizedBox(height: 8.h),
            const Text('Tap + to add a new task', style: AppTextStyles.bodyMedium),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUpcomingTasks,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: _tasks.length,
        itemBuilder: (context, index) {
          final task = _tasks[index];
          final now = DateTime.now();
          final tomorrow = DateTime(now.year, now.month, now.day + 1);
          final nextWeek = DateTime(now.year, now.month, now.day + 7);
          
          bool showDateHeader = false;
          String? dateHeader;

          if (index == 0 || !_isSameDay(_tasks[index - 1].dueDate, task.dueDate)) {
            showDateHeader = true;
            if (_isSameDay(task.dueDate, tomorrow)) {
              dateHeader = 'Tomorrow';
            } else if (task.dueDate.isBefore(nextWeek)) {
              dateHeader = 'This Week';
            } else {
              dateHeader = 'Later';
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showDateHeader) ...[
                if (index > 0) SizedBox(height: 16.h),
                Padding(
                  padding: EdgeInsets.only(left: 8.w, bottom: 8.h),
                  child: Text(
                    dateHeader!,
                    style: AppTextStyles.h4.copyWith(color: AppColors.primary),
                  ),
                ),
              ],
              _buildTaskCard(task),
            ],
          );
        },
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildTaskCard(Task task) {
    final dateString = DateFormat('MMM dd, yyyy').format(task.dueDate);
    final timeString = DateFormat('HH:mm').format(task.dueDate);

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.only(right: 16.w),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(12.r),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) => showDialog<bool>(
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
      ),
      onDismissed: (direction) => _deleteTask(task),
      child: Card(
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
                    if (task.fieldId != null)
                      Icon(Icons.location_on, size: 16.sp, color: AppColors.textSecondary),
                  ],
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    _buildTaskChip(Icons.calendar_today, dateString),
                    SizedBox(width: 8.w),
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
      ),
    );
  }

  Widget _buildTaskChip(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
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

class AddTaskSheet extends ConsumerStatefulWidget {
  final VoidCallback onTaskAdded;

  const AddTaskSheet({super.key, required this.onTaskAdded});

  @override
  ConsumerState<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends ConsumerState<AddTaskSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _taskType = 'Watering';
  int _priority = 5;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
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

  Future<void> _addTask() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task title')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final database = ref.read(databaseProvider);
      final authRepo = ref.read(authRepositoryProvider);
      
      final userId = await authRepo.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final dueDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final now = DateTime.now();
      final taskCompanion = TasksCompanion(
        id: drift.Value(const Uuid().v4()),
        userId: drift.Value(userId),
        title: drift.Value(_titleController.text.trim()),
        description: drift.Value(_descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim()),
        taskType: drift.Value(_taskType),
        dueDate: drift.Value(dueDate),
        priority: drift.Value(_priority),
        isCompleted: const drift.Value(false),
        createdAt: drift.Value(now),
        updatedAt: drift.Value(now),
        isSynced: const drift.Value(false),
        isDeleted: const drift.Value(false),
      );

      await database.insertTask(taskCompanion);
      
      if (!mounted) return;
      Navigator.pop(context);
      widget.onTaskAdded();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task added successfully')),
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
                const Text('Add Task', style: AppTextStyles.h3),
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
              leading: const Icon(Icons.calendar_today),
              title: const Text('Date'),
              trailing: Text(
                DateFormat('MMM dd, yyyy').format(_selectedDate),
                style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _selectedDate = date);
                }
              },
            ),
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
              onPressed: _isSubmitting ? null : _addTask,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Add Task'),
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
  late DateTime _selectedDate;
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
    _selectedDate = widget.task.dueDate;
    _selectedTime = TimeOfDay.fromDateTime(widget.task.dueDate);
  }

  Future<void> _updateTask() async {
    setState(() => _isSubmitting = true);

    try {
      final database = ref.read(databaseProvider);
      
      final dueDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final updatedTaskCompanion = TasksCompanion(
        id: drift.Value(widget.task.id),
        title: drift.Value(_titleController.text.trim()),
        description: drift.Value(_descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim()),
        taskType: drift.Value(_taskType),
        dueDate: drift.Value(dueDate),
        priority: drift.Value(_priority),
        updatedAt: drift.Value(DateTime.now()),
        isSynced: const drift.Value(false),
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
              leading: const Icon(Icons.calendar_today),
              title: const Text('Date'),
              trailing: Text(
                DateFormat('MMM dd, yyyy').format(_selectedDate),
                style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _selectedDate = date);
                }
              },
            ),
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
