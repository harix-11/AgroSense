import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/demo_data_provider.dart';
import '../../../data/local/database/app_database.dart';
import '../../../providers/repository_providers.dart';
import 'start_crop_dialog.dart';

class FieldsScreen extends ConsumerStatefulWidget {
  const FieldsScreen({super.key});

  @override
  ConsumerState<FieldsScreen> createState() => _FieldsScreenState();
}

class _FieldsScreenState extends ConsumerState<FieldsScreen> {
  bool _isLoading = true;
  List<Field> _fields = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFields();
  }

  Future<void> _loadFields() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Check if in developer mode
      if (AppConstants.isDeveloperMode) {
        // Load demo data
        final demoFields = DemoDataProvider.getDemoFields();

        setState(() {
          _fields = demoFields;
          _isLoading = false;
        });
      } else {
        // Load from database (real data)
        final database = ref.read(databaseProvider);
        final authRepo = ref.read(authRepositoryProvider);

        final userId = await authRepo.getCurrentUserId();
        if (userId == null) {
          throw Exception('User not logged in');
        }

        final fields = await database.getFieldsByUserId(userId);

        setState(() {
          _fields = fields;
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

  Future<void> _deleteField(Field field) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Field'),
        content: const Text('Are you sure you want to delete this field?'),
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
      await database.deleteField(field.id);
      await _loadFields();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Field deleted successfully')),
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

  void _showFieldDetails(Field field) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          padding: EdgeInsets.all(16.w),
          child: FutureBuilder<FieldCrop?>(
            future: ref
                .read(fieldCropRepositoryProvider)
                .getActiveFieldCrop(field.id),
            builder: (context, snapshot) {
              final hasActiveCrop = snapshot.hasData && snapshot.data != null;

              return ListView(
                controller: scrollController,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(field.name, style: AppTextStyles.h3),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          Navigator.pop(context);
                          _showAddEditDialog(field: field);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          Navigator.pop(context);
                          _deleteField(field);
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  // Active Crop Status
                  if (hasActiveCrop) ...[
                    FutureBuilder<Crop?>(
                      future: ref
                          .read(databaseProvider)
                          .getCropById(snapshot.data!.cropId),
                      builder: (context, cropSnapshot) {
                        if (!cropSnapshot.hasData) {
                          return const SizedBox();
                        }

                        final crop = cropSnapshot.data!;
                        final daysSincePlanting = DateTime.now()
                            .difference(snapshot.data!.plantingDate)
                            .inDays;

                        return Container(
                          padding: EdgeInsets.all(12.w),
                          margin: EdgeInsets.only(bottom: 16.h),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(color: AppColors.success),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.eco,
                                      color: AppColors.success, size: 20.sp),
                                  SizedBox(width: 8.w),
                                  Text(
                                    'Active Crop: ${crop.name}',
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                'Stage: ${snapshot.data!.currentStage.replaceAll('_', ' ').toUpperCase()}',
                                style: AppTextStyles.bodyMedium,
                              ),
                              Text(
                                'Day $daysSincePlanting of ${crop.minDurationDays}-${crop.maxDurationDays}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ] else ...[
                    Container(
                      padding: EdgeInsets.all(12.w),
                      margin: EdgeInsets.only(bottom: 16.h),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: AppColors.warning),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: AppColors.warning, size: 20.sp),
                          SizedBox(width: 8.w),
                          Text(
                            'No active crop on this field',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  _buildDetailRow(
                      Icons.straighten, 'Area', '${field.area} acres'),
                  if (field.cropType != null)
                    _buildDetailRow(Icons.grass, 'Crop Type', field.cropType!),
                  if (field.soilType != null)
                    _buildDetailRow(
                        Icons.terrain, 'Soil Type', field.soilType!),
                  _buildDetailRow(
                    Icons.calendar_today,
                    'Created',
                    DateFormat('MMM dd, yyyy').format(field.createdAt),
                  ),
                  SizedBox(height: 16.h),

                  // Action Buttons
                  if (!hasActiveCrop) ...[
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showStartCropDialog(field);
                      },
                      icon: const Icon(Icons.agriculture),
                      label: const Text('Start Crop'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                    ),
                    SizedBox(height: 8.h),
                  ],

                  OutlinedButton.icon(
                    onPressed: () {
                      // View on map functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Map view coming soon')),
                      );
                    },
                    icon: const Icon(Icons.map),
                    label: const Text('View on Map'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showStartCropDialog(Field field) {
    showDialog(
      context: context,
      builder: (context) => StartCropDialog(
        field: field,
        onCropStarted: _loadFields,
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Icon(icon, size: 20.sp, color: AppColors.primary),
          SizedBox(width: 12.w),
          Text('$label:',
              style: AppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.w600)),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(value, style: AppTextStyles.bodyMedium),
          ),
        ],
      ),
    );
  }

  void _showAddEditDialog({Field? field}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEditFieldSheet(
        field: field,
        onSaved: _loadFields,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Fields'),
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
              onPressed: _loadFields,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_fields.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.landscape, size: 64.sp, color: AppColors.textSecondary),
            SizedBox(height: 16.h),
            const Text('No fields added yet', style: AppTextStyles.h3),
            SizedBox(height: 8.h),
            const Text('Tap + to add your first field',
                style: AppTextStyles.bodyMedium),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFields,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: _fields.length,
        itemBuilder: (context, index) {
          final field = _fields[index];
          return _buildFieldCard(field);
        },
      ),
    );
  }

  Widget _buildFieldCard(Field field) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      child: InkWell(
        onTap: () => _showFieldDetails(field),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(Icons.landscape,
                        color: AppColors.primary, size: 24.sp),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          field.name,
                          style: AppTextStyles.bodyLarge
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${field.area} acres',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.map, color: AppColors.primary),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Map view coming soon')),
                      );
                    },
                  ),
                ],
              ),
              if (field.cropType != null || field.soilType != null) ...[
                SizedBox(height: 12.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: [
                    if (field.cropType != null)
                      _buildChip(
                          Icons.grass, field.cropType!, AppColors.success),
                    if (field.soilType != null)
                      _buildChip(
                          Icons.terrain, field.soilType!, AppColors.secondary),
                  ],
                ),
              ],
              SizedBox(height: 8.h),
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 14.sp, color: AppColors.textSecondary),
                  SizedBox(width: 4.w),
                  Text(
                    'Created ${DateFormat('MMM dd, yyyy').format(field.createdAt)}',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String label, Color color) {
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
            label,
            style: AppTextStyles.bodySmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class AddEditFieldSheet extends ConsumerStatefulWidget {
  final Field? field;
  final VoidCallback onSaved;

  const AddEditFieldSheet({
    super.key,
    this.field,
    required this.onSaved,
  });

  @override
  ConsumerState<AddEditFieldSheet> createState() => _AddEditFieldSheetState();
}

class _AddEditFieldSheetState extends ConsumerState<AddEditFieldSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _areaController;
  String? _cropType;
  String? _soilType;
  bool _isSubmitting = false;

  final List<String> _cropTypes = [
    'Rice',
    'Wheat',
    'Cotton',
    'Sugarcane',
    'Maize',
    'Vegetables',
    'Fruits',
    'Pulses',
    'Oilseeds',
    'Other',
  ];

  final List<String> _soilTypes = [
    'Alluvial',
    'Black',
    'Red',
    'Laterite',
    'Desert',
    'Mountain',
    'Clay',
    'Loamy',
    'Sandy',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.field?.name ?? '');
    _areaController =
        TextEditingController(text: widget.field?.area.toString() ?? '');
    _cropType = widget.field?.cropType;
    _soilType = widget.field?.soilType;
  }

  Future<void> _saveField() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter field name')),
      );
      return;
    }

    final area = double.tryParse(_areaController.text.trim());
    if (area == null || area <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid area')),
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

      final companion = FieldsCompanion(
        id: Value(widget.field?.id ?? const Uuid().v4()),
        userId: Value(userId),
        name: Value(_nameController.text.trim()),
        area: Value(area),
        cropType: Value(_cropType),
        soilType: Value(_soilType),
        coordinates: const Value('[]'),
        createdAt: Value(widget.field?.createdAt ?? now),
        updatedAt: Value(now),
        isSynced: const Value(false),
        isDeleted: const Value(false),
      );

      if (widget.field == null) {
        await database.insertField(companion);
      } else {
        await database.updateField(companion);
      }

      if (!mounted) return;
      Navigator.pop(context);
      widget.onSaved();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.field == null
                ? 'Field added successfully'
                : 'Field updated successfully',
          ),
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
                  widget.field == null ? 'Add Field' : 'Edit Field',
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
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Field Name',
                prefixIcon: Icon(Icons.label),
              ),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: _areaController,
              decoration: const InputDecoration(
                labelText: 'Area (acres)',
                prefixIcon: Icon(Icons.straighten),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16.h),
            DropdownButtonFormField<String>(
              initialValue: _cropType,
              decoration: const InputDecoration(
                labelText: 'Crop Type',
                prefixIcon: Icon(Icons.grass),
              ),
              items: _cropTypes.map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (value) => setState(() => _cropType = value),
            ),
            SizedBox(height: 16.h),
            DropdownButtonFormField<String>(
              initialValue: _soilType,
              decoration: const InputDecoration(
                labelText: 'Soil Type',
                prefixIcon: Icon(Icons.terrain),
              ),
              items: _soilTypes.map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (value) => setState(() => _soilType = value),
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _saveField,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.field == null ? 'Add Field' : 'Update Field'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _areaController.dispose();
    super.dispose();
  }
}
