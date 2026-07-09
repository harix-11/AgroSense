import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/demo_data_provider.dart';
import '../../../data/local/database/app_database.dart';
import '../../../providers/repository_providers.dart';

class SchemesScreen extends ConsumerStatefulWidget {
  const SchemesScreen({super.key});

  @override
  ConsumerState<SchemesScreen> createState() => _SchemesScreenState();
}

class _SchemesScreenState extends ConsumerState<SchemesScreen> {
  bool _isLoading = true;
  List<Scheme> _schemes = [];
  List<Scheme> _filteredSchemes = [];
  String? _error;
  String _selectedLanguage = 'en';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSchemes();
  }

  Future<void> _loadSchemes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Check if in developer mode
      if (AppConstants.isDeveloperMode) {
        // Load demo data
        final demoSchemes = DemoDataProvider.getDemoSchemes(language: _selectedLanguage);
        setState(() {
          _schemes = demoSchemes;
          _filteredSchemes = demoSchemes;
          _isLoading = false;
        });
      } else {
        // Load from database (real data)
        final database = ref.read(databaseProvider);
        final schemes = await database.getAllSchemes(language: _selectedLanguage);
        
        setState(() {
          _schemes = schemes;
          _filteredSchemes = schemes;
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

  Future<void> _syncSchemes() async {
    setState(() => _isLoading = true);

    try {
      final schemesRepo = ref.read(schemesRepositoryProvider);
      await schemesRepo.refreshSchemes(language: _selectedLanguage);
      await _loadSchemes();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Schemes synced successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _searchSchemes(String query) {
    if (query.isEmpty) {
      setState(() => _filteredSchemes = _schemes);
      return;
    }

    setState(() {
      _filteredSchemes = _schemes.where((scheme) {
        return scheme.title.toLowerCase().contains(query.toLowerCase()) ||
               scheme.description.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  void _showSchemeDetails(Scheme scheme) {
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
                    child: Text(scheme.title, style: AppTextStyles.h3),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Text('Description', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
              SizedBox(height: 8.h),
              Text(scheme.description, style: AppTextStyles.bodyMedium),
              SizedBox(height: 16.h),
              Text('Eligibility Criteria', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
              SizedBox(height: 8.h),
              _buildEligibilityCriteria(scheme.eligibilityCriteria),
              SizedBox(height: 16.h),
              Text('Benefits', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
              SizedBox(height: 8.h),
              Text(scheme.benefits, style: AppTextStyles.bodyMedium),
              if (scheme.applyUrl != null) ...[
                SizedBox(height: 24.h),
                ElevatedButton.icon(
                  onPressed: () => _launchUrl(scheme.applyUrl!),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Apply Now'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEligibilityCriteria(String criteriaJson) {
    try {
      final criteria = jsonDecode(criteriaJson);
      if (criteria is Map) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: criteria.entries.map((entry) {
            return Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle, size: 16.sp, color: AppColors.success),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      '${entry.key}: ${entry.value}',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      } else if (criteria is List) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: criteria.map((item) {
            return Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle, size: 16.sp, color: AppColors.success),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      item.toString(),
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      }
    } catch (_) {}
    return Text(criteriaJson, style: AppTextStyles.bodyMedium);
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open URL')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Government Schemes'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.language),
            onSelected: (value) {
              setState(() => _selectedLanguage = value);
              _loadSchemes();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'en', child: Text('English')),
              const PopupMenuItem(value: 'hi', child: Text('हिंदी')),
              const PopupMenuItem(value: 'ta', child: Text('தமிழ்')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _syncSchemes,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search schemes...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchSchemes('');
                        },
                      )
                    : null,
              ),
              onChanged: _searchSchemes,
            ),
          ),
          Expanded(child: _buildBody()),
        ],
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
              onPressed: _loadSchemes,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredSchemes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance, size: 64.sp, color: AppColors.textSecondary),
            SizedBox(height: 16.h),
            const Text('No schemes available', style: AppTextStyles.h3),
            SizedBox(height: 8.h),
            const Text('Tap refresh to sync schemes', style: AppTextStyles.bodyMedium),
            SizedBox(height: 16.h),
            ElevatedButton.icon(
              onPressed: _syncSchemes,
              icon: const Icon(Icons.sync),
              label: const Text('Sync Now'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _syncSchemes,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: _filteredSchemes.length,
        itemBuilder: (context, index) {
          final scheme = _filteredSchemes[index];
          return _buildSchemeCard(scheme);
        },
      ),
    );
  }

  Widget _buildSchemeCard(Scheme scheme) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      child: InkWell(
        onTap: () => _showSchemeDetails(scheme),
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
                      scheme.title,
                      style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      'Eligible',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.success),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                scheme.description.length > 150
                    ? '${scheme.description.substring(0, 150)}...'
                    : scheme.description,
                style: AppTextStyles.bodySmall,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Icon(Icons.card_giftcard, size: 16.sp, color: AppColors.primary),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: Text(
                      scheme.benefits.length > 60
                          ? '${scheme.benefits.substring(0, 60)}...'
                          : scheme.benefits,
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 14.sp, color: AppColors.textSecondary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
