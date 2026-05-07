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

class ProductManagementScreen extends ConsumerWidget {
  const ProductManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ownerProductManagementProvider);
    final notifier = ref.read(ownerProductManagementProvider.notifier);

    ref.listen(ownerProductManagementProvider, (previous, next) {
      final messenger = ScaffoldMessenger.of(context);
      if (next.errorMessage != previous?.errorMessage && next.hasError) {
        messenger.showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      }
      if (next.successMessage != previous?.successMessage &&
          (next.successMessage?.isNotEmpty ?? false)) {
        messenger.showSnackBar(SnackBar(content: Text(next.successMessage!)));
      }
    });

    final categoryLookup = <String, ProductCategory>{
      for (final category in state.categories) category.id: category,
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
                      label: AppStrings.addProduct,
                      prefixIcon: Icons.add_rounded,
                      isFullWidth: false,
                      onPressed: state.categories.isEmpty
                          ? null
                          : () => _openProductEditor(
                              context,
                              ref,
                              categories: state.categories,
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.sm),
                Text(
                  'Create, update, and monitor stock across the full catalog.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSizes.lg),
                GlassInput(
                  hint: 'Search by product name or SKU',
                  prefixIcon: Icons.search_rounded,
                  onChanged: notifier.setSearchQuery,
                ),
                const SizedBox(height: AppSizes.lg),
                Wrap(
                  spacing: AppSizes.sm,
                  runSpacing: AppSizes.sm,
                  children: [
                    GlassChip(
                      label: '${state.products.length} total',
                      variant: GlassChipVariant.primary,
                    ),
                    GlassChip(
                      label:
                          '${state.products.where((item) => item.isLowStock).length} low stock',
                      variant: GlassChipVariant.warning,
                    ),
                    GlassChip(
                      label:
                          '${state.products.where((item) => !item.isActive).length} inactive',
                      variant: GlassChipVariant.neutral,
                    ),
                    GlassChip(
                      label:
                          '${state.products.where((item) => item.hasDiscount).length} on offer',
                      variant: GlassChipVariant.success,
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
          else if (state.filteredProducts.isEmpty)
            GlassCard(
              variant: GlassCardVariant.elevated,
              child: Column(
                children: [
                  const Icon(Icons.inventory_2_outlined, size: AppSizes.iconXl),
                  const SizedBox(height: AppSizes.md),
                  Text(
                    'No products available',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            )
          else
            ...state.filteredProducts.map(
              (product) => Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.md),
                child: _ProductManagementCard(
                  product: product,
                  categoryLookup: categoryLookup,
                  onEdit: () => _openProductEditor(
                    context,
                    ref,
                    categories: state.categories,
                    product: product,
                  ),
                  onDelete: () => _confirmDelete(context, ref, product),
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
    ProductModel product,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppStrings.deleteProduct),
          content: Text(AppStrings.deleteProductConfirm),
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
          .read(ownerProductManagementProvider.notifier)
          .deleteProduct(product.id);
    }
  }

  Future<void> _openProductEditor(
    BuildContext context,
    WidgetRef ref, {
    required List<ProductCategory> categories,
    ProductModel? product,
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
              child: _ProductEditorSheet(
                categories: categories,
                product: product,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProductManagementCard extends StatelessWidget {
  const _ProductManagementCard({
    required this.product,
    required this.categoryLookup,
    required this.onEdit,
    required this.onDelete,
  });

  final ProductModel product;
  final Map<String, ProductCategory> categoryLookup;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final category = categoryLookup[product.categoryId];
    final subCategory = categoryLookup[product.subCategoryId];

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
                      product.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Text(
                      product.sku,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              GlassChip(
                label: product.isActive ? 'Active' : 'Inactive',
                variant: product.isActive
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
                label: category?.name ?? 'Unassigned',
                variant: GlassChipVariant.primary,
              ),
              if (subCategory != null)
                GlassChip(
                  label: subCategory.name,
                  variant: GlassChipVariant.neutral,
                ),
              GlassChip(
                label: 'Stock ${product.stock}',
                variant: product.isLowStock
                    ? GlassChipVariant.warning
                    : GlassChipVariant.success,
              ),
              if (product.hasDiscount)
                GlassChip(
                  label: 'On Offer ${product.discountPercent}% OFF',
                  variant: GlassChipVariant.error,
                ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            product.shortDescription.isNotEmpty
                ? product.shortDescription
                : product.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            '${AppStrings.currencySymbol}${product.price.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (product.hasDiscount) ...[
            const SizedBox(height: AppSizes.xs),
            Text(
              'Was ${AppStrings.currencySymbol}${product.originalPrice.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                decoration: TextDecoration.lineThrough,
              ),
            ),
          ],
          const SizedBox(height: AppSizes.md),
          Row(
            children: [
              Expanded(
                child: GlassButton(
                  label: product.hasDiscount ? 'Edit Offer' : 'Add Offer',
                  prefixIcon: Icons.local_offer_outlined,
                  variant: GlassButtonVariant.success,
                  onPressed: onEdit,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: GlassButton(
                  label: AppStrings.editProduct,
                  prefixIcon: Icons.edit_outlined,
                  variant: GlassButtonVariant.ghost,
                  onPressed: onEdit,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: GlassButton(
                  label: AppStrings.delete,
                  prefixIcon: Icons.delete_outline_rounded,
                  variant: GlassButtonVariant.danger,
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

class _ProductEditorSheet extends ConsumerStatefulWidget {
  const _ProductEditorSheet({required this.categories, this.product});

  final List<ProductCategory> categories;
  final ProductModel? product;

  @override
  ConsumerState<_ProductEditorSheet> createState() =>
      _ProductEditorSheetState();
}

class _ProductEditorSheetState extends ConsumerState<_ProductEditorSheet> {
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _priceController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _thresholdController = TextEditingController();
  final _shortDescriptionController = TextEditingController();
  final _descriptionController = TextEditingController();
  final Map<String, String?> _errors = {};

  String? _selectedCategoryId;
  String? _selectedSubCategoryId;
  bool _isActive = true;
  bool _isUploadingImages = false;
  late final String _uploadFolderId;
  final List<String> _existingImages = [];
  final List<String> _selectedImagePaths = [];

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _uploadFolderId =
        product?.id ?? 'draft_${DateTime.now().millisecondsSinceEpoch}';
    if (product != null) {
      _nameController.text = product.name;
      _skuController.text = product.sku;
      _priceController.text = product.price.toStringAsFixed(0);
      _originalPriceController.text = product.originalPrice.toStringAsFixed(0);
      _stockController.text = product.stock.toString();
      _thresholdController.text = product.lowStockThreshold.toString();
      _shortDescriptionController.text = product.shortDescription;
      _descriptionController.text = product.description;
      _existingImages.addAll(product.images);
      _selectedCategoryId = product.categoryId;
      _selectedSubCategoryId = product.subCategoryId;
      _isActive = product.isActive;
    } else {
      _thresholdController.text = '5';
      _originalPriceController.text = '0';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    _stockController.dispose();
    _thresholdController.dispose();
    _shortDescriptionController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: FileUpload.imageExtensions,
      allowMultiple: true,
    );

    if (result == null || result.files.isEmpty || !mounted) return;

    final newPaths = <String>[];
    for (final file in result.files) {
      final path = file.path;
      if (path == null || path.trim().isEmpty || !File(path).existsSync()) {
        _showSnack('Selected file could not be opened from device storage.');
        return;
      }
      if (!_selectedImagePaths.contains(path) && !newPaths.contains(path)) {
        newPaths.add(path);
      }
    }

    if (newPaths.isEmpty) return;

    setState(() {
      _selectedImagePaths.addAll(newPaths);
    });
  }

  void _removeExistingImage(String imageUrl) {
    setState(() {
      _existingImages.remove(imageUrl);
    });
  }

  void _removeSelectedImage(String imagePath) {
    setState(() {
      _selectedImagePaths.remove(imagePath);
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ownerProductManagementProvider);
    final theme = Theme.of(context);
    final isBusy = state.isSaving || _isUploadingImages;
    final categories =
        widget.categories.where((item) => item.isTopLevel).toList()
          ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    final subCategories =
        widget.categories
            .where((item) => item.parentId == _selectedCategoryId)
            .toList()
          ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    return SafeArea(
      child: SingleChildScrollView(
        child: Form(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isEditing ? AppStrings.editProduct : AppStrings.addProduct,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    'Manage catalog details, upload imagery, and control storefront visibility.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.lg),
              GlassInput(
                controller: _nameController,
                label: AppStrings.productName,
                isRequired: true,
                hint: 'Premium Honey',
                errorText: _errors['name'],
                onChanged: (value) => _clearFieldError('name', value),
              ),
              const SizedBox(height: AppSizes.md),
              GlassInput(
                controller: _skuController,
                label: AppStrings.sku,
                isRequired: true,
                hint: 'WAFI-HONEY-01',
                errorText: _errors['sku'],
                onChanged: (value) => _clearFieldError('sku', value),
              ),
              const SizedBox(height: AppSizes.md),
              Row(
                children: [
                  Expanded(
                    child: GlassInput(
                      controller: _priceController,
                      label: AppStrings.price,
                      isRequired: true,
                      keyboardType: TextInputType.number,
                      hint: '800',
                      errorText: _errors['price'],
                      onChanged: (value) => _clearFieldError('price', value),
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: GlassInput(
                      controller: _originalPriceController,
                      label: AppStrings.originalPrice,
                      keyboardType: TextInputType.number,
                      hint: '900',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.md),
              Row(
                children: [
                  Expanded(
                    child: GlassInput(
                      controller: _stockController,
                      label: AppStrings.stockQty,
                      isRequired: true,
                      keyboardType: TextInputType.number,
                      hint: '20',
                      errorText: _errors['stock'],
                      onChanged: (value) => _clearFieldError('stock', value),
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: GlassInput(
                      controller: _thresholdController,
                      label: AppStrings.lowStockAlert,
                      isRequired: true,
                      keyboardType: TextInputType.number,
                      hint: '5',
                      errorText: _errors['threshold'],
                      onChanged: (value) =>
                          _clearFieldError('threshold', value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.md),
              _DropdownField<String>(
                label: AppStrings.category,
                isRequired: true,
                value: _selectedCategoryId,
                errorText: _errors['categoryId'],
                items: categories
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item.id,
                        child: Text(item.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value;
                    _selectedSubCategoryId = null;
                    if (value != null && _errors['categoryId'] != null) {
                      _errors['categoryId'] = null;
                    }
                  });
                },
              ),
              const SizedBox(height: AppSizes.md),
              _DropdownField<String>(
                label: AppStrings.subcategory,
                value: _selectedSubCategoryId,
                items: subCategories
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item.id,
                        child: Text(item.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSubCategoryId = value;
                  });
                },
              ),
              const SizedBox(height: AppSizes.md),
              GlassInput(
                controller: _shortDescriptionController,
                label: AppStrings.shortDesc,
                isRequired: true,
                hint: 'Short inventory-facing summary',
                maxLines: 2,
                errorText: _errors['shortDescription'],
                onChanged: (value) =>
                    _clearFieldError('shortDescription', value),
              ),
              const SizedBox(height: AppSizes.md),
              GlassInput(
                controller: _descriptionController,
                label: AppStrings.fullDesc,
                isRequired: true,
                hint: 'Detailed catalog description',
                maxLines: 4,
                errorText: _errors['description'],
                onChanged: (value) => _clearFieldError('description', value),
              ),
              const SizedBox(height: AppSizes.md),
              _ProductImagesField(
                existingImages: _existingImages,
                selectedImagePaths: _selectedImagePaths,
                isUploading: _isUploadingImages,
                onAddImages: isBusy ? null : _pickImages,
                onRemoveExisting: isBusy ? null : _removeExistingImage,
                onRemoveSelected: isBusy ? null : _removeSelectedImage,
              ),
              const SizedBox(height: AppSizes.md),
              _EditorSection(
                child: SwitchListTile.adaptive(
                  value: _isActive,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.md,
                  ),
                  title: Text(
                    'Product is active',
                    style: theme.textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    'Inactive products stay hidden from customers.',
                    style: theme.textTheme.bodySmall,
                  ),
                  onChanged: (value) => setState(() => _isActive = value),
                ),
              ),
              const SizedBox(height: AppSizes.lg),
              Row(
                children: [
                  Expanded(
                    child: GlassButton(
                      label: AppStrings.cancel,
                      variant: GlassButtonVariant.ghost,
                      onPressed: isBusy
                          ? null
                          : () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: GlassButton(
                      label: _isEditing ? AppStrings.update : AppStrings.save,
                      isLoading: isBusy,
                      onPressed: isBusy ? null : _submit,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final sku = _skuController.text.trim();
    final shortDescription = _shortDescriptionController.text.trim();
    final description = _descriptionController.text.trim();
    final price = double.tryParse(_priceController.text.trim());
    final originalPriceInput = double.tryParse(
      _originalPriceController.text.trim(),
    );
    final stock = int.tryParse(_stockController.text.trim());
    final threshold = int.tryParse(_thresholdController.text.trim());

    final nextErrors = <String, String?>{
      'name': AppValidators.required(name),
      'sku': AppValidators.required(sku),
      'shortDescription': AppValidators.required(shortDescription),
      'description': AppValidators.required(description),
      'categoryId': _selectedCategoryId == null
          ? AppStrings.validRequired
          : null,
      'price': _priceController.text.trim().isEmpty
          ? AppStrings.validRequired
          : price == null || price <= 0
          ? 'Enter a valid price.'
          : null,
      'stock': _stockController.text.trim().isEmpty
          ? AppStrings.validRequired
          : stock == null || stock < 0
          ? 'Enter a valid stock quantity.'
          : null,
      'threshold': _thresholdController.text.trim().isEmpty
          ? AppStrings.validRequired
          : threshold == null
          ? 'Enter a valid low stock alert value.'
          : null,
    };

    setState(() {
      _errors
        ..clear()
        ..addAll(nextErrors);
    });

    if (nextErrors.values.any((error) => error != null)) return;

    if (threshold! < 0) {
      _showSnack('Low stock alert cannot be negative.');
      return;
    }
    final originalPrice = originalPriceInput == null || originalPriceInput <= 0
        ? price!
        : originalPriceInput;
    if (originalPrice < price!) {
      _showSnack('Original price must be greater than or equal to price.');
      return;
    }
    final imageList = [..._existingImages];

    if (_selectedImagePaths.isNotEmpty) {
      setState(() {
        _isUploadingImages = true;
      });

      try {
        final uploadedImages = await ref
            .read(ownerManagementServiceProvider)
            .uploadProductImages(
              _selectedImagePaths,
              folderId: _uploadFolderId,
            );
        imageList.addAll(uploadedImages);
        _existingImages.addAll(uploadedImages);
        _selectedImagePaths.clear();
      } catch (error) {
        if (!mounted) return;
        _showSnack(error.toString());
        setState(() {
          _isUploadingImages = false;
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        _isUploadingImages = false;
      });
    }

    final draft = OwnerProductDraft(
      name: name,
      description: description,
      shortDescription: shortDescription,
      sku: sku,
      price: price,
      originalPrice: originalPrice,
      categoryId: _selectedCategoryId!,
      subCategoryId: _selectedSubCategoryId,
      stock: stock!,
      lowStockThreshold: threshold,
      images: imageList,
      isActive: _isActive,
    );

    final notifier = ref.read(ownerProductManagementProvider.notifier);
    if (_isEditing) {
      await notifier.updateProduct(widget.product!.id, draft);
    } else {
      await notifier.createProduct(draft);
    }

    if (!mounted) return;
    final nextState = ref.read(ownerProductManagementProvider);
    if (nextState.hasError) {
      return;
    }
    Navigator.of(context).pop();
  }

  void _clearFieldError(String fieldKey, String value) {
    if (value.trim().isEmpty || _errors[fieldKey] == null) return;
    setState(() => _errors[fieldKey] = null);
  }
}

class _ProductImagesField extends StatelessWidget {
  const _ProductImagesField({
    required this.existingImages,
    required this.selectedImagePaths,
    required this.isUploading,
    required this.onAddImages,
    required this.onRemoveExisting,
    required this.onRemoveSelected,
  });

  final List<String> existingImages;
  final List<String> selectedImagePaths;
  final bool isUploading;
  final VoidCallback? onAddImages;
  final ValueChanged<String>? onRemoveExisting;
  final ValueChanged<String>? onRemoveSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImages =
        existingImages.isNotEmpty || selectedImagePaths.isNotEmpty;

    return _EditorSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.uploadImages, style: theme.textTheme.labelLarge),
          const SizedBox(height: AppSizes.xs),
          Text(
            'Pick one or more files from device storage. Uploaded images will be saved to Cloudinary.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSizes.md),
          GlassButton(
            label: isUploading ? 'Uploading images...' : 'Choose Images',
            prefixIcon: Icons.add_photo_alternate_outlined,
            variant: GlassButtonVariant.ghost,
            onPressed: onAddImages,
          ),
          const SizedBox(height: AppSizes.md),
          if (!hasImages)
            Text(
              'No product images selected yet.',
              style: theme.textTheme.bodySmall,
            )
          else
            Wrap(
              spacing: AppSizes.sm,
              runSpacing: AppSizes.sm,
              children: [
                for (final imageUrl in existingImages)
                  _ProductImagePreview(
                    imageSource: imageUrl,
                    isLocalFile: false,
                    onRemove: onRemoveExisting == null
                        ? null
                        : () => onRemoveExisting!(imageUrl),
                  ),
                for (final imagePath in selectedImagePaths)
                  _ProductImagePreview(
                    imageSource: imagePath,
                    isLocalFile: true,
                    onRemove: onRemoveSelected == null
                        ? null
                        : () => onRemoveSelected!(imagePath),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ProductImagePreview extends StatelessWidget {
  const _ProductImagePreview({
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
                              const _ProductImageFallback(),
                        )
                      : Image.network(
                          imageSource,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const _ProductImageFallback(),
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

class _ProductImageFallback extends StatelessWidget {
  const _ProductImageFallback();

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

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
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

class _EditorSection extends StatelessWidget {
  const _EditorSection({required this.child});

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
