import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/demo_data_provider.dart';
import '../../../data/local/database/app_database.dart';
import '../../../providers/repository_providers.dart';

class DiaryScreen extends ConsumerStatefulWidget {
  const DiaryScreen({super.key});

  @override
  ConsumerState<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends ConsumerState<DiaryScreen> {
  bool _isLoading = true;
  List<DiaryEntry> _entries = [];
  String? _error;
  String? _selectedCategory;

  final List<String> _categories = ['observation', 'expense', 'income', 'note'];

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Check if in developer mode
      if (AppConstants.isDeveloperMode) {
        // Load demo data
        final demoEntries = DemoDataProvider.getDemoDiaryEntries();
        
        setState(() {
          _entries = _selectedCategory == null
              ? demoEntries
              : demoEntries.where((e) => e.category == _selectedCategory).toList();
          _isLoading = false;
        });
      } else {
        // Load from database (real data)
        final database = ref.read(databaseProvider);
        final userId = await ref.read(currentUserIdProvider.future);
        
        if (userId == null || userId.isEmpty) {
          throw Exception('User not logged in');
        }

        final entries = await database.watchDiaryEntriesByUserId(userId).first;
        
        setState(() {
          _entries = _selectedCategory == null
              ? entries
              : entries.where((e) => e.category == _selectedCategory).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteEntry(DiaryEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Are you sure you want to delete this diary entry?'),
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
      await database.deleteDiaryEntry(entry.id);
      await _loadEntries();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entry deleted successfully')),
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

  void _showEntryDetails(DiaryEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          padding: EdgeInsets.all(16.w),
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(entry.title, style: AppTextStyles.h3),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      Navigator.pop(context);
                      _showAddEditDialog(entry: entry);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteEntry(entry);
                    },
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  _buildCategoryChip(entry.category),
                  SizedBox(width: 8.w),
                  Text(
                    DateFormat('MMM dd, yyyy').format(entry.entryDate),
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
              if (entry.amount != null) ...[
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: entry.category == 'income'
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        entry.category == 'income'
                            ? Icons.trending_up
                            : Icons.trending_down,
                        color: entry.category == 'income'
                            ? AppColors.success
                            : AppColors.error,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        '₹${entry.amount!.toStringAsFixed(2)}',
                        style: AppTextStyles.h4.copyWith(
                          color: entry.category == 'income'
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: 16.h),
              Text('Description', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
              SizedBox(height: 8.h),
              Text(entry.content, style: AppTextStyles.bodyMedium),
              if (entry.imagePaths != null) ...[
                SizedBox(height: 16.h),
                Text('Images', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                SizedBox(height: 8.h),
                _buildImageGrid(entry.imagePaths!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showAddEditDialog({DiaryEntry? entry}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEditDiarySheet(
        entry: entry,
        onSaved: _loadEntries,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Farm Diary'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedCategory = value == 'all' ? null : value;
              });
              _loadEntries();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All')),
              ..._categories.map((cat) => PopupMenuItem(
                value: cat,
                child: Text(cat[0].toUpperCase() + cat.substring(1)),
              ),),
            ],
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
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
              onPressed: _loadEntries,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book_outlined, size: 64.sp, color: AppColors.textSecondary),
            SizedBox(height: 16.h),
            const Text('No diary entries yet', style: AppTextStyles.h3),
            SizedBox(height: 8.h),
            const Text('Tap + to add your first entry', style: AppTextStyles.bodyMedium),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEntries,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: _entries.length,
        itemBuilder: (context, index) {
          final entry = _entries[index];
          return _buildEntryCard(entry);
        },
      ),
    );
  }

  Widget _buildEntryCard(DiaryEntry entry) {
    final hasImages = entry.imagePaths != null;
    List<String> imagePaths = [];
    if (hasImages) {
      try {
        imagePaths = List<String>.from(jsonDecode(entry.imagePaths!));
      } catch (_) {}
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      child: InkWell(
        onTap: () => _showEntryDetails(entry),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.title,
                      style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  _buildCategoryChip(entry.category),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                entry.content.length > 100
                    ? '${entry.content.substring(0, 100)}...'
                    : entry.content,
                style: AppTextStyles.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (entry.amount != null) ...[
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Icon(
                      entry.category == 'income'
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      size: 16.sp,
                      color: entry.category == 'income'
                          ? AppColors.success
                          : AppColors.error,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      '₹${entry.amount!.toStringAsFixed(2)}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: entry.category == 'income'
                            ? AppColors.success
                            : AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
              SizedBox(height: 8.h),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14.sp, color: AppColors.textSecondary),
                  SizedBox(width: 4.w),
                  Text(
                    DateFormat('MMM dd, yyyy').format(entry.entryDate),
                    style: AppTextStyles.bodySmall,
                  ),
                  if (imagePaths.isNotEmpty) ...[
                    SizedBox(width: 12.w),
                    Icon(Icons.image, size: 14.sp, color: AppColors.textSecondary),
                    SizedBox(width: 4.w),
                    Text('${imagePaths.length}', style: AppTextStyles.bodySmall),
                  ],
                ],
              ),
              if (imagePaths.isNotEmpty) ...[
                SizedBox(height: 12.h),
                SizedBox(
                  height: 80.h,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: imagePaths.length > 3 ? 3 : imagePaths.length,
                    itemBuilder: (context, i) => Container(
                      width: 80.w,
                      margin: EdgeInsets.only(right: 8.w),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.r),
                        image: DecorationImage(
                          image: FileImage(File(imagePaths[i])),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    Color color;
    IconData icon;
    
    switch (category) {
      case 'expense':
        color = AppColors.error;
        icon = Icons.money_off;
        break;
      case 'income':
        color = AppColors.success;
        icon = Icons.attach_money;
        break;
      case 'observation':
        color = AppColors.info;
        icon = Icons.visibility;
        break;
      default:
        color = AppColors.textSecondary;
        icon = Icons.note;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: color),
          SizedBox(width: 4.w),
          Text(
            category[0].toUpperCase() + category.substring(1),
            style: AppTextStyles.bodySmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid(String imagePaths) {
    List<String> paths = [];
    try {
      paths = List<String>.from(jsonDecode(imagePaths));
    } catch (_) {}

    if (paths.isEmpty) return const SizedBox.shrink();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8.w,
        mainAxisSpacing: 8.h,
      ),
      itemCount: paths.length,
      itemBuilder: (context, index) => ClipRRect(
        borderRadius: BorderRadius.circular(8.r),
        child: Image.file(
          File(paths[index]),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class AddEditDiarySheet extends ConsumerStatefulWidget {
  final DiaryEntry? entry;
  final VoidCallback onSaved;

  const AddEditDiarySheet({
    super.key,
    this.entry,
    required this.onSaved,
  });

  @override
  ConsumerState<AddEditDiarySheet> createState() => _AddEditDiarySheetState();
}

class _AddEditDiarySheetState extends ConsumerState<AddEditDiarySheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _amountController;
  late String _category;
  late DateTime _entryDate;
  final List<String> _imagePaths = [];
  bool _isSubmitting = false;

  final List<String> _categories = ['observation', 'expense', 'income', 'note'];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.entry?.title ?? '');
    _contentController = TextEditingController(text: widget.entry?.content ?? '');
    _amountController = TextEditingController(
      text: widget.entry?.amount?.toString() ?? '',
    );
    _category = widget.entry?.category ?? 'observation';
    _entryDate = widget.entry?.entryDate ?? DateTime.now();

    if (widget.entry?.imagePaths != null) {
      try {
        _imagePaths.addAll(List<String>.from(jsonDecode(widget.entry!.imagePaths!)));
      } catch (_) {}
    }
  }

  Future<void> _pickImages() async {
    try {
      final images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _imagePaths.addAll(images.map((e) => e.path));
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking images: ${e.toString()}')),
      );
    }
  }

  Future<void> _saveEntry() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter content')),
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

      final now = DateTime.now();
      double? amount;
      if (_category == 'expense' || _category == 'income') {
        amount = double.tryParse(_amountController.text.trim());
      }

      final companion = DiaryEntriesCompanion(
        id: Value(widget.entry?.id ?? const Uuid().v4()),
        userId: Value(userId),
        title: Value(_titleController.text.trim()),
        content: Value(_contentController.text.trim()),
        category: Value(_category),
        amount: Value(amount),
        entryDate: Value(_entryDate),
        imagePaths: Value(_imagePaths.isEmpty ? null : jsonEncode(_imagePaths)),
        fieldId: const Value(null),
        createdAt: Value(widget.entry?.createdAt ?? now),
        updatedAt: Value(now),
        isSynced: const Value(false),
        isDeleted: const Value(false),
      );

      if (widget.entry == null) {
        await database.insertDiaryEntry(companion);
      } else {
        await database.updateDiaryEntry(companion);
      }

      if (!mounted) return;
      Navigator.pop(context);
      widget.onSaved();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.entry == null
              ? 'Entry added successfully'
              : 'Entry updated successfully',),
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
                Text(
                  widget.entry == null ? 'Add Entry' : 'Edit Entry',
                  style: AppTextStyles.h3,
                ),
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
                labelText: 'Title',
                prefixIcon: Icon(Icons.title),
              ),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Content',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 5,
            ),
            SizedBox(height: 16.h),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category),
              ),
              items: _categories.map((cat) {
                return DropdownMenuItem(
                  value: cat,
                  child: Text(cat[0].toUpperCase() + cat.substring(1)),
                );
              }).toList(),
              onChanged: (value) => setState(() => _category = value!),
            ),
            if (_category == 'expense' || _category == 'income') ...[
              SizedBox(height: 16.h),
              TextField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount (₹)',
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
            SizedBox(height: 16.h),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Date'),
              trailing: Text(
                DateFormat('MMM dd, yyyy').format(_entryDate),
                style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _entryDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _entryDate = date);
                }
              },
            ),
            SizedBox(height: 16.h),
            OutlinedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.image),
              label: const Text('Add Images'),
            ),
            if (_imagePaths.isNotEmpty) ...[
              SizedBox(height: 12.h),
              SizedBox(
                height: 100.h,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _imagePaths.length,
                  itemBuilder: (context, index) => Stack(
                    children: [
                      Container(
                        width: 100.w,
                        margin: EdgeInsets.only(right: 8.w),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.r),
                          image: DecorationImage(
                            image: FileImage(File(_imagePaths[index])),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 12,
                        child: GestureDetector(
                          onTap: () => setState(() => _imagePaths.removeAt(index)),
                          child: Container(
                            padding: EdgeInsets.all(4.w),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.close, size: 16.sp, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _saveEntry,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.entry == null ? 'Add Entry' : 'Update Entry'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}
