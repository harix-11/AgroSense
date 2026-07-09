import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/local/database/app_database.dart';
import '../../../providers/repository_providers.dart';

/// Dialog for starting a new crop on a field
class StartCropDialog extends ConsumerStatefulWidget {
  final Field field;
  final VoidCallback onCropStarted;

  const StartCropDialog({
    super.key,
    required this.field,
    required this.onCropStarted,
  });

  @override
  ConsumerState<StartCropDialog> createState() => _StartCropDialogState();
}

class _StartCropDialogState extends ConsumerState<StartCropDialog> {
  List<Crop> _crops = [];
  bool _isLoadingCrops = true;
  Crop? _selectedCrop;
  DateTime _plantingDate = DateTime.now();
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadCrops();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadCrops() async {
    try {
      final cropRepo = ref.read(cropCatalogRepositoryProvider);
      final crops = await cropRepo.getAllCrops();

      setState(() {
        _crops = crops;
        _isLoadingCrops = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCrops = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading crops: $e')),
        );
      }
    }
  }

  List<String> get _categories {
    return _crops.map((c) => c.category).toSet().toList()..sort();
  }

  List<Crop> get _filteredCrops {
    if (_selectedCategory == null) return _crops;
    return _crops.where((c) => c.category == _selectedCategory).toList();
  }

  Future<void> _startCrop() async {
    if (_selectedCrop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a crop')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final userId = await authRepo.getCurrentUserId();

      if (userId == null) {
        throw Exception('User not logged in');
      }

      final fieldCropRepo = ref.read(fieldCropRepositoryProvider);
      final fieldCropId = await fieldCropRepo.startCrop(
        fieldId: widget.field.id,
        cropId: _selectedCrop!.id,
        userId: userId,
        plantingDate: _plantingDate,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (fieldCropId == null) {
        throw Exception('Field already has an active crop');
      }

      if (!mounted) return;

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_selectedCrop!.name} started successfully! 🌱',
          ),
          backgroundColor: AppColors.success,
        ),
      );

      widget.onCropStarted();
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Container(
        constraints: BoxConstraints(maxHeight: 600.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(16.r),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.agriculture, color: Colors.white, size: 28.sp),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Start New Crop',
                          style: AppTextStyles.h3.copyWith(color: Colors.white),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          widget.field.name,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: _isLoadingCrops
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: EdgeInsets.all(20.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category Filter
                          Text('Crop Category', style: AppTextStyles.h4),
                          SizedBox(height: 8.h),
                          Wrap(
                            spacing: 8.w,
                            runSpacing: 8.h,
                            children: [
                              _buildCategoryChip(
                                  'All', _selectedCategory == null),
                              ..._categories.map(
                                (cat) => _buildCategoryChip(
                                  cat,
                                  _selectedCategory == cat,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 20.h),

                          // Crop Selection
                          Text('Select Crop', style: AppTextStyles.h4),
                          SizedBox(height: 12.h),
                          ..._filteredCrops.map((crop) => _buildCropCard(crop)),

                          SizedBox(height: 20.h),

                          // Planting Date
                          Text('Planting Date', style: AppTextStyles.h4),
                          SizedBox(height: 8.h),
                          InkWell(
                            onTap: () => _selectDate(),
                            borderRadius: BorderRadius.circular(8.r),
                            child: Container(
                              padding: EdgeInsets.all(16.w),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.border),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    color: AppColors.primary,
                                    size: 20.sp,
                                  ),
                                  SizedBox(width: 12.w),
                                  Text(
                                    DateFormat('MMM dd, yyyy')
                                        .format(_plantingDate),
                                    style: AppTextStyles.bodyLarge,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: 20.h),

                          // Notes
                          Text('Notes (Optional)', style: AppTextStyles.h4),
                          SizedBox(height: 8.h),
                          TextField(
                            controller: _notesController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Add any notes about this planting...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),

            // Footer
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSubmitting || _selectedCrop == null
                          ? null
                          : _startCrop,
                      child: _isSubmitting
                          ? SizedBox(
                              height: 20.h,
                              width: 20.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Start Crop'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedCategory = selected && label != 'All' ? label : null;
        });
      },
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
    );
  }

  Widget _buildCropCard(Crop crop) {
    final isSelected = _selectedCrop?.id == crop.id;

    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedCrop = crop;
          });
        },
        borderRadius: BorderRadius.circular(8.r),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  _getCropIcon(crop.category),
                  color: AppColors.primary,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(crop.name,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        )),
                    if (crop.scientificName != null)
                      Text(
                        crop.scientificName!,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontStyle: FontStyle.italic,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(Icons.schedule,
                            size: 14.sp, color: AppColors.textSecondary),
                        SizedBox(width: 4.w),
                        Text(
                          '${crop.minDurationDays}-${crop.maxDurationDays} days',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Icon(Icons.water_drop,
                            size: 14.sp, color: AppColors.textSecondary),
                        SizedBox(width: 4.w),
                        Text(
                          crop.waterRequirement ?? 'Medium',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: AppColors.primary, size: 24.sp),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCropIcon(String category) {
    switch (category.toLowerCase()) {
      case 'cereal':
        return Icons.grass;
      case 'cash crop':
        return Icons.attach_money;
      case 'vegetable':
        return Icons.eco;
      case 'fruit':
        return Icons.apple;
      case 'pulse':
        return Icons.grain;
      case 'oilseed':
        return Icons.water_drop_outlined;
      case 'spice':
        return Icons.set_meal;
      case 'millet':
        return Icons.grass_outlined;
      case 'plantation':
        return Icons.forest;
      default:
        return Icons.agriculture;
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _plantingDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _plantingDate = picked;
      });
    }
  }
}
