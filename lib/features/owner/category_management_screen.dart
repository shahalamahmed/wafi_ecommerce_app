import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wafi_ecommerce_app/core/constants/file_upload.dart';
import 'package:wafi_ecommerce_app/core/constants/sizes.dart';
import 'package:wafi_ecommerce_app/core/constants/strings.dart';
import 'package:wafi_ecommerce_app/core/theme/app_theme.dart';
import 'package:wafi_ecommerce_app/core/utils/validators.dart';
import 'package:wafi_ecommerce_app/features/owner/owner_management_provider.dart';
import 'package:wafi_ecommerce_app/features/owner/owner_management_service.dart';
import 'package:wafi_ecommerce_app/features/products/product_model.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_button.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_card.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_chip.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_input.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_snackbar.dart';

class CategoryManagementScreen extends ConsumerWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ownerCategoryManagementProvider);
    final notifier = ref.read(ownerCategoryManagementProvider.notifier);

    ref.listen(ownerCategoryManagementProvider, (previous, next) {
      if (next.errorMessage != previous?.errorMessage && next.hasError) {
        GlassSnackbar.error(context, next.errorMessage!);
      }
      if (next.successMessage != previous?.successMessage &&
          (next.successMessage?.isNotEmpty ?? false)) {
        GlassSnackbar.success(context, next.successMessage!);
      }
    });

    final categoryLookup = <String, ProductCategory>{
      for (final category in state.categories) category.id: category,
    };
    final categoryPathLookup = <String, String>{
      for (final category in state.categories)
        category.id: _categoryPath(category, categoryLookup),
    };

    return RefreshIndicator(
      onRefresh: notifier.load,
      child: ListView(
        padding: const EdgeInsets.all(AppSizes.screenPaddingH),
        children: [
          GlassCard(
            variant: GlassCardVariant.elevated,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GlassButton(
                      label: 'Add Category',
                      prefixIcon: Icons.add_rounded,
                      size: GlassButtonSize.sm,
                      isFullWidth: false,
                      onPressed: () => _openCategoryEditor(
                        context,
                        categories: state.categories,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.sm),
                Text(
                  'Create parent categories, add subcategories, and control storefront visibility.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSizes.lg),
                GlassInput(
                  hint: 'Search by category name or description',
                  prefixIcon: Icons.search_rounded,
                  onChanged: notifier.setSearchQuery,
                ),
                const SizedBox(height: AppSizes.lg),
                Wrap(
                  spacing: AppSizes.sm,
                  runSpacing: AppSizes.sm,
                  children: [
                    GlassChip(
                      label: '${state.categories.length} total',
                      variant: GlassChipVariant.primary,
                    ),
                    GlassChip(
                      label:
                          '${state.categories.where((item) => item.isActive).length} active',
                      variant: GlassChipVariant.success,
                    ),
                    GlassChip(
                      label:
                          '${state.categories.where((item) => !item.isTopLevel).length} subcategories',
                      variant: GlassChipVariant.neutral,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          if (state.isLoading)
            const Padding(
              padding: EdgeInsets.all(AppSizes.xl3),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (state.filteredCategories.isEmpty)
            GlassCard(
              variant: GlassCardVariant.elevated,
              child: Column(
                children: [
                  const Icon(Icons.category_outlined, size: AppSizes.iconXl),
                  const SizedBox(height: AppSizes.md),
                  Text(
                    'No categories available',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            )
          else
            ...state.filteredCategories.map(
              (category) => Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.md),
                child: _CategoryManagementCard(
                  category: category,
                  parentPath: category.parentId == null
                      ? null
                      : categoryPathLookup[category.parentId!],
                  onEdit: () => _openCategoryEditor(
                    context,
                    categories: state.categories,
                    category: category,
                  ),
                  onDelete: () => _confirmDelete(context, ref, category),
                ),
              ),
            ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ProductCategory category,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Category'),
          content: Text('Delete ${category.name} permanently?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(AppStrings.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(AppStrings.delete),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await ref
          .read(ownerCategoryManagementProvider.notifier)
          .deleteCategory(category.id);
    }
  }

  Future<void> _openCategoryEditor(
    BuildContext context, {
    required List<ProductCategory> categories,
    ProductCategory? category,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final theme = Theme.of(context);
        final glass = theme.extension<GlassTheme>()!;

        return AnimatedPadding(
          duration: const Duration(milliseconds: AppSizes.animFast),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.only(
            left: AppSizes.md,
            right: AppSizes.md,
            top: AppSizes.md,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSizes.md,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: glass.elevatedColor,
              borderRadius: BorderRadius.circular(AppSizes.radiusXxl),
              border: Border.all(color: glass.borderColor, width: 1),
              boxShadow: [
                BoxShadow(
                  color: glass.shadowColor.withValues(alpha: 0.18),
                  blurRadius: 28,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.screenPaddingH,
                AppSizes.xl,
                AppSizes.screenPaddingH,
                AppSizes.screenPaddingH,
              ),
              child: _CategoryEditorSheet(
                categories: categories,
                category: category,
              ),
            ),
          ),
        );
      },
    );
  }
}

String _categoryPath(
  ProductCategory category,
  Map<String, ProductCategory> categoryLookup,
) {
  final segments = <String>[category.name];
  var cursor = category.parentId;

  while ((cursor ?? '').isNotEmpty) {
    final parent = categoryLookup[cursor];
    if (parent == null) break;
    segments.insert(0, parent.name);
    cursor = parent.parentId;
  }

  return segments.join(' > ');
}

class _CategoryManagementCard extends StatelessWidget {
  const _CategoryManagementCard({
    required this.category,
    required this.parentPath,
    required this.onEdit,
    required this.onDelete,
  });

  final ProductCategory category;
  final String? parentPath;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      variant: GlassCardVariant.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Text(
                      category.description.isNotEmpty
                          ? category.description
                          : 'No description added',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              GlassChip(
                label: category.isActive ? 'Active' : 'Inactive',
                variant: category.isActive
                    ? GlassChipVariant.success
                    : GlassChipVariant.neutral,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          Wrap(
            spacing: AppSizes.sm,
            runSpacing: AppSizes.sm,
            children: [
              GlassChip(
                label: category.isTopLevel
                    ? 'Main Category'
                    : 'Nested Category',
                variant: GlassChipVariant.primary,
              ),
              GlassChip(
                label: 'Order ${category.displayOrder}',
                variant: GlassChipVariant.neutral,
              ),
              if ((parentPath ?? '').isNotEmpty)
                GlassChip(
                  label: 'Parent $parentPath',
                  variant: GlassChipVariant.warning,
                ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          Row(
            children: [
              Expanded(
                child: GlassButton(
                  label: 'Edit',
                  prefixIcon: Icons.edit_outlined,
                  variant: GlassButtonVariant.ghost,
                  size: GlassButtonSize.sm,
                  onPressed: onEdit,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: GlassButton(
                  label: AppStrings.delete,
                  prefixIcon: Icons.delete_outline_rounded,
                  variant: GlassButtonVariant.danger,
                  size: GlassButtonSize.sm,
                  onPressed: onDelete,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryEditorSheet extends ConsumerStatefulWidget {
  const _CategoryEditorSheet({required this.categories, this.category});

  final List<ProductCategory> categories;
  final ProductCategory? category;

  @override
  ConsumerState<_CategoryEditorSheet> createState() =>
      _CategoryEditorSheetState();
}

enum _CategoryCreationMode { main, nested }

class _CategoryEditorSheetState extends ConsumerState<_CategoryEditorSheet> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _displayOrderController = TextEditingController();
  final Map<String, String?> _errors = {};

  String? _selectedParentId;
  String? _initialParentId;
  bool _isActive = true;
  bool _isUploadingImage = false;
  bool _showAdvancedOrder = false;
  late _CategoryCreationMode _creationMode;
  late final String _uploadFolderId;
  String? _existingImageUrl;
  String? _selectedImagePath;

  bool get _isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    final category = widget.category;
    _uploadFolderId =
        category?.id ?? 'draft_${DateTime.now().millisecondsSinceEpoch}';
    if (category != null) {
      _nameController.text = category.name;
      _descriptionController.text = category.description;
      _existingImageUrl = category.image.trim().isEmpty ? null : category.image;
      _displayOrderController.text = category.displayOrder.toString();
      _selectedParentId = category.parentId;
      _initialParentId = category.parentId;
      _isActive = category.isActive;
      _creationMode = (category.parentId == null || category.parentId!.isEmpty)
          ? _CategoryCreationMode.main
          : _CategoryCreationMode.nested;
    } else {
      _creationMode = _CategoryCreationMode.main;
      _displayOrderController.text = _suggestedDisplayOrderFor(
        parentId: null,
      ).toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _displayOrderController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: FileUpload.imageExtensions,
    );

    if (result == null || result.files.isEmpty || !mounted) return;

    final path = result.files.single.path;
    if (path == null || path.trim().isEmpty || !File(path).existsSync()) {
      _showSnack('Selected file could not be opened from device storage.');
      return;
    }

    setState(() {
      _selectedImagePath = path;
    });
  }

  void _removeExistingImage() {
    setState(() {
      _existingImageUrl = null;
    });
  }

  void _removeSelectedImage() {
    setState(() {
      _selectedImagePath = null;
    });
  }

  void _showSnack(String message) {
    GlassSnackbar.info(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ownerCategoryManagementProvider);
    final theme = Theme.of(context);
    final isBusy = state.isSaving || _isUploadingImage;
    final availableParents = _availableParents(
      widget.categories,
      widget.category,
    );
    final hasParentSelection = _creationMode == _CategoryCreationMode.nested;
    final effectiveParentId = hasParentSelection ? _selectedParentId : null;
    final selectedParentPath = _categoryPathForId(effectiveParentId);
    final effectiveDisplayOrder = _effectiveDisplayOrder;

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEditing ? 'Edit Category' : 'Add Category',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSizes.xs),
            Text(
              'Choose where this category belongs, then add the details.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AppSizes.lg),
            _CategoryEditorSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Create As', style: theme.textTheme.labelLarge),
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    'Main categories appear at the top. Nested categories appear under an existing category.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSizes.md),
                  Wrap(
                    spacing: AppSizes.sm,
                    runSpacing: AppSizes.sm,
                    children: [
                      GlassChip(
                        label: 'Main Category',
                        variant: GlassChipVariant.primary,
                        isSelected: _creationMode == _CategoryCreationMode.main,
                        onTap: isBusy
                            ? null
                            : () {
                                setState(() {
                                  _creationMode = _CategoryCreationMode.main;
                                  _selectedParentId = null;
                                });
                              },
                      ),
                      GlassChip(
                        label: 'Under Existing Category',
                        variant: GlassChipVariant.primary,
                        isSelected:
                            _creationMode == _CategoryCreationMode.nested,
                        onTap: isBusy
                            ? null
                            : () {
                                setState(() {
                                  _creationMode = _CategoryCreationMode.nested;
                                });
                              },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.md),
            GlassInput(
              controller: _nameController,
              label: 'Category Name',
              isRequired: true,
              hint: 'Accessories, Phones, Android',
              errorText: _errors['name'],
              onChanged: (value) => _clearFieldError('name', value),
            ),
            const SizedBox(height: AppSizes.md),
            GlassInput(
              controller: _descriptionController,
              label: AppStrings.description,
              hint: 'Phone accessories and extras',
              maxLines: 3,
            ),
            const SizedBox(height: AppSizes.md),
            _CategoryImageField(
              existingImageUrl: _existingImageUrl,
              selectedImagePath: _selectedImagePath,
              isUploading: _isUploadingImage,
              onAddImage: isBusy ? null : _pickImage,
              onRemoveExisting: isBusy || _existingImageUrl == null
                  ? null
                  : _removeExistingImage,
              onRemoveSelected: isBusy || _selectedImagePath == null
                  ? null
                  : _removeSelectedImage,
            ),
            const SizedBox(height: AppSizes.md),
            if (hasParentSelection) ...[
              _CategoryEditorSection(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CategoryDropdownField<String?>(
                      label: 'Parent Category',
                      value: _selectedParentId,
                      items: availableParents
                          .map(
                            (item) => DropdownMenuItem<String?>(
                              value: item.id,
                              child: Text(_categoryPath(item)),
                            ),
                          )
                          .toList(),
                      errorText: _errors['parentId'],
                      onChanged: (value) {
                        setState(() {
                          _selectedParentId = value;
                          _errors['parentId'] = null;
                        });
                      },
                    ),
                    const SizedBox(height: AppSizes.sm),
                    Text(
                      selectedParentPath == null
                          ? 'Select a parent category to place this inside your existing structure.'
                          : 'Parent Path: $selectedParentPath',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.md),
            ],
            _CategoryEditorSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Position', style: theme.textTheme.labelLarge),
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    hasParentSelection
                        ? 'By default, this category will be added after the other items under the selected parent.'
                        : 'By default, this category will be added after the other main categories.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSizes.md),
                  Text(
                    'Automatic position: $effectiveDisplayOrder',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSizes.sm),
                  SwitchListTile.adaptive(
                    value: _showAdvancedOrder,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Set custom position',
                      style: theme.textTheme.titleMedium,
                    ),
                    subtitle: Text(
                      'Turn this on only if you want to override the automatic order.',
                      style: theme.textTheme.bodySmall,
                    ),
                    onChanged: isBusy
                        ? null
                        : (value) => setState(() => _showAdvancedOrder = value),
                  ),
                  if (_showAdvancedOrder) ...[
                    const SizedBox(height: AppSizes.sm),
                    GlassInput(
                      controller: _displayOrderController,
                      label: 'Custom Position',
                      isRequired: true,
                      keyboardType: TextInputType.number,
                      hint: '$effectiveDisplayOrder',
                      errorText: _errors['displayOrder'],
                      onChanged: (value) =>
                          _clearFieldError('displayOrder', value),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSizes.md),
            _CategoryEditorSection(
              child: SwitchListTile.adaptive(
                value: _isActive,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.md,
                ),
                title: Text(
                  'Category is active',
                  style: theme.textTheme.titleMedium,
                ),
                subtitle: Text(
                  'Inactive categories stay hidden from customers.',
                  style: theme.textTheme.bodySmall,
                ),
                onChanged: isBusy
                    ? null
                    : (value) => setState(() => _isActive = value),
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            Row(
              children: [
                Expanded(
                  child: GlassButton(
                    label: AppStrings.cancel,
                    variant: GlassButtonVariant.ghost,
                    size: GlassButtonSize.sm,
                    onPressed: isBusy
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: GlassButton(
                    label: _isEditing ? AppStrings.update : AppStrings.save,
                    size: GlassButtonSize.sm,
                    isLoading: isBusy,
                    onPressed: isBusy ? null : _submit,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<ProductCategory> _availableParents(
    List<ProductCategory> categories,
    ProductCategory? currentCategory,
  ) {
    if (currentCategory == null) {
      return [...categories]
        ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    }

    final blockedIds = _descendantIds(currentCategory.id, categories)
      ..add(currentCategory.id);

    final available =
        categories
            .where((category) => !blockedIds.contains(category.id))
            .toList()
          ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return available;
  }

  Set<String> _descendantIds(
    String parentId,
    List<ProductCategory> categories,
  ) {
    final descendants = <String>{};
    final pending = <String>[parentId];

    while (pending.isNotEmpty) {
      final currentId = pending.removeLast();
      for (final category in categories) {
        if (category.parentId != currentId) continue;
        if (descendants.add(category.id)) {
          pending.add(category.id);
        }
      }
    }

    return descendants;
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final effectiveParentId = _creationMode == _CategoryCreationMode.nested
        ? _selectedParentId
        : null;
    final customDisplayOrder = int.tryParse(
      _displayOrderController.text.trim(),
    );
    final displayOrder = _showAdvancedOrder
        ? customDisplayOrder
        : _effectiveDisplayOrder;

    final nextErrors = <String, String?>{
      'name': AppValidators.required(name),
      'parentId':
          _creationMode == _CategoryCreationMode.nested &&
              (effectiveParentId == null || effectiveParentId.isEmpty)
          ? 'Select a parent category.'
          : null,
      'displayOrder': !_showAdvancedOrder
          ? null
          : _displayOrderController.text.trim().isEmpty
          ? AppStrings.validRequired
          : displayOrder == null
          ? 'Enter a valid custom position.'
          : null,
    };

    setState(() {
      _errors
        ..clear()
        ..addAll(nextErrors);
    });

    if (nextErrors.values.any((error) => error != null)) return;

    var image = _existingImageUrl ?? '';

    if (_selectedImagePath != null) {
      setState(() {
        _isUploadingImage = true;
      });

      try {
        final uploadedImages = await ref
            .read(ownerManagementServiceProvider)
            .uploadProductImages([
              _selectedImagePath!,
            ], folderId: _uploadFolderId);
        image = uploadedImages.isEmpty ? '' : uploadedImages.first;
        _existingImageUrl = image.isEmpty ? null : image;
        _selectedImagePath = null;
      } catch (error) {
        if (!mounted) return;
        _showSnack(error.toString());
        setState(() {
          _isUploadingImage = false;
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        _isUploadingImage = false;
      });
    }

    final draft = OwnerCategoryDraft(
      name: name,
      description: description,
      image: image,
      parentId: effectiveParentId,
      displayOrder: displayOrder!,
      isActive: _isActive,
    );

    final notifier = ref.read(ownerCategoryManagementProvider.notifier);
    if (_isEditing) {
      await notifier.updateCategory(widget.category!.id, draft);
    } else {
      await notifier.createCategory(draft);
    }

    if (!mounted) return;
    final nextState = ref.read(ownerCategoryManagementProvider);
    if (nextState.hasError) return;
    Navigator.of(context).pop();
  }

  void _clearFieldError(String fieldKey, String value) {
    if (value.trim().isEmpty || _errors[fieldKey] == null) return;
    setState(() => _errors[fieldKey] = null);
  }

  int get _effectiveDisplayOrder {
    if (_showAdvancedOrder) {
      final parsed = int.tryParse(_displayOrderController.text.trim());
      if (parsed != null) return parsed;
    }

    final effectiveParentId = _creationMode == _CategoryCreationMode.nested
        ? _selectedParentId
        : null;
    if (_isEditing &&
        widget.category != null &&
        effectiveParentId == _initialParentId) {
      return widget.category!.displayOrder;
    }
    return _suggestedDisplayOrderFor(parentId: effectiveParentId);
  }

  int _suggestedDisplayOrderFor({required String? parentId}) {
    final siblingOrders = widget.categories
        .where((category) {
          if (widget.category != null && category.id == widget.category!.id) {
            return false;
          }
          final categoryParentId = (category.parentId ?? '').trim();
          final normalizedParentId = (parentId ?? '').trim();
          return categoryParentId == normalizedParentId;
        })
        .map((category) => category.displayOrder);

    if (siblingOrders.isEmpty) return 1;
    return siblingOrders.reduce((max, value) => value > max ? value : max) + 1;
  }

  String _categoryPath(ProductCategory category) {
    final segments = <String>[category.name];
    var cursor = category.parentId;

    while ((cursor ?? '').isNotEmpty) {
      ProductCategory? parent;
      for (final item in widget.categories) {
        if (item.id == cursor) {
          parent = item;
          break;
        }
      }
      if (parent == null) break;
      segments.insert(0, parent.name);
      cursor = parent.parentId;
    }

    return segments.join(' > ');
  }

  String? _categoryPathForId(String? categoryId) {
    if ((categoryId ?? '').isEmpty) return null;
    for (final category in widget.categories) {
      if (category.id == categoryId) {
        return _categoryPath(category);
      }
    }
    return null;
  }
}

class _CategoryImageField extends StatelessWidget {
  const _CategoryImageField({
    required this.existingImageUrl,
    required this.selectedImagePath,
    required this.isUploading,
    required this.onAddImage,
    required this.onRemoveExisting,
    required this.onRemoveSelected,
  });

  final String? existingImageUrl;
  final String? selectedImagePath;
  final bool isUploading;
  final VoidCallback? onAddImage;
  final VoidCallback? onRemoveExisting;
  final VoidCallback? onRemoveSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage =
        (existingImageUrl?.isNotEmpty ?? false) ||
        (selectedImagePath?.isNotEmpty ?? false);

    return _CategoryEditorSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.uploadImages, style: theme.textTheme.labelLarge),
          const SizedBox(height: AppSizes.xs),
          Text(
            'Pick an image file from device storage. The uploaded image will be saved to Cloudinary.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSizes.md),
          GlassButton(
            label: isUploading ? 'Uploading image...' : 'Choose Image',
            prefixIcon: Icons.add_photo_alternate_outlined,
            variant: GlassButtonVariant.ghost,
            size: GlassButtonSize.sm,
            onPressed: onAddImage,
          ),
          const SizedBox(height: AppSizes.md),
          if (!hasImage)
            Text(
              'No category image selected yet.',
              style: theme.textTheme.bodySmall,
            )
          else
            Wrap(
              spacing: AppSizes.sm,
              runSpacing: AppSizes.sm,
              children: [
                if (existingImageUrl?.isNotEmpty ?? false)
                  _CategoryImagePreview(
                    imageSource: existingImageUrl!,
                    isLocalFile: false,
                    onRemove: onRemoveExisting,
                  ),
                if (selectedImagePath?.isNotEmpty ?? false)
                  _CategoryImagePreview(
                    imageSource: selectedImagePath!,
                    isLocalFile: true,
                    onRemove: onRemoveSelected,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _CategoryImagePreview extends StatelessWidget {
  const _CategoryImagePreview({
    required this.imageSource,
    required this.isLocalFile,
    this.onRemove,
  });

  final String imageSource;
  final bool isLocalFile;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 92,
      padding: const EdgeInsets.all(AppSizes.xs),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: isLocalFile
                      ? Image.file(
                          File(imageSource),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const _CategoryImageFallback(),
                        )
                      : Image.network(
                          imageSource,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const _CategoryImageFallback(),
                        ),
                ),
              ),
              if (onRemove != null)
                Positioned(
                  top: 4,
                  right: 4,
                  child: InkWell(
                    onTap: onRemove,
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            isLocalFile ? 'New file' : 'Saved',
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _CategoryImageFallback extends StatelessWidget {
  const _CategoryImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        Icons.image_not_supported_outlined,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class _CategoryDropdownField<T> extends StatelessWidget {
  const _CategoryDropdownField({
    required this.label,
    required this.value,
    required this.items,
    this.isRequired = false,
    this.errorText,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final bool isRequired;
  final String? errorText;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = theme.extension<GlassTheme>()!;

    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.textTheme.bodySmall?.color,
              fontWeight: FontWeight.w500,
            ),
            children: [
              TextSpan(text: label),
              if (isRequired)
                TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.xs),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.inputPaddingH,
          ),
          decoration: BoxDecoration(
            color: glass.cardColor,
            borderRadius: BorderRadius.circular(AppSizes.inputRadius),
            border: Border.all(
              color: hasError ? theme.colorScheme.error : glass.borderColor,
              width: 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: items.any((item) => item.value == value) ? value : null,
              isExpanded: true,
              dropdownColor: glass.elevatedColor,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: theme.textTheme.bodySmall?.color,
              ),
              hint: Text(
                'Select',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
              items: items,
              style: theme.textTheme.bodyMedium,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              onChanged: onChanged,
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: AppSizes.xs),
          Text(
            errorText!,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }
}

class _CategoryEditorSection extends StatelessWidget {
  const _CategoryEditorSection({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = theme.extension<GlassTheme>()!;

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: glass.cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: glass.borderColor, width: 1),
      ),
      child: child,
    );
  }
}
