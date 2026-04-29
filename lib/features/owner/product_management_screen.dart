import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wafi_ecommerce_app/core/constants/sizes.dart';
import 'package:wafi_ecommerce_app/core/constants/strings.dart';
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
                    Expanded(
                      child: Text(
                        'Product Catalog Management',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
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
        return Padding(
          padding: EdgeInsets.only(
            left: AppSizes.screenPaddingH,
            right: AppSizes.screenPaddingH,
            top: AppSizes.screenPaddingH,
            bottom:
                MediaQuery.of(context).viewInsets.bottom +
                AppSizes.screenPaddingH,
          ),
          child: _ProductEditorSheet(categories: categories, product: product),
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
          Row(
            children: [
              Expanded(
                child: Text(
                  '${AppStrings.currencySymbol}${product.price.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              GlassButton(
                label: AppStrings.editProduct,
                prefixIcon: Icons.edit_outlined,
                isFullWidth: false,
                variant: GlassButtonVariant.ghost,
                onPressed: onEdit,
              ),
              const SizedBox(width: AppSizes.sm),
              GlassButton(
                label: AppStrings.delete,
                prefixIcon: Icons.delete_outline_rounded,
                isFullWidth: false,
                variant: GlassButtonVariant.danger,
                onPressed: onDelete,
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
  final _imagesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _selectedCategoryId;
  String? _selectedSubCategoryId;
  bool _isActive = true;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    if (product != null) {
      _nameController.text = product.name;
      _skuController.text = product.sku;
      _priceController.text = product.price.toStringAsFixed(0);
      _originalPriceController.text = product.originalPrice.toStringAsFixed(0);
      _stockController.text = product.stock.toString();
      _thresholdController.text = product.lowStockThreshold.toString();
      _shortDescriptionController.text = product.shortDescription;
      _descriptionController.text = product.description;
      _imagesController.text = product.images.join(', ');
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
    _imagesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ownerProductManagementProvider);
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
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEditing ? AppStrings.editProduct : AppStrings.addProduct,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSizes.lg),
              GlassInput(
                controller: _nameController,
                label: AppStrings.productName,
                hint: 'Premium Honey',
              ),
              const SizedBox(height: AppSizes.md),
              GlassInput(
                controller: _skuController,
                label: AppStrings.sku,
                hint: 'WAFI-HONEY-01',
              ),
              const SizedBox(height: AppSizes.md),
              Row(
                children: [
                  Expanded(
                    child: GlassInput(
                      controller: _priceController,
                      label: AppStrings.price,
                      keyboardType: TextInputType.number,
                      hint: '800',
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
                      keyboardType: TextInputType.number,
                      hint: '20',
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: GlassInput(
                      controller: _thresholdController,
                      label: AppStrings.lowStockAlert,
                      keyboardType: TextInputType.number,
                      hint: '5',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.md),
              _DropdownField<String>(
                label: AppStrings.category,
                value: _selectedCategoryId,
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
                hint: 'Short inventory-facing summary',
                maxLines: 2,
              ),
              const SizedBox(height: AppSizes.md),
              GlassInput(
                controller: _descriptionController,
                label: AppStrings.fullDesc,
                hint: 'Detailed catalog description',
                maxLines: 4,
              ),
              const SizedBox(height: AppSizes.md),
              GlassInput(
                controller: _imagesController,
                label: AppStrings.uploadImages,
                hint: 'Comma separated image URLs',
                maxLines: 2,
              ),
              const SizedBox(height: AppSizes.md),
              SwitchListTile.adaptive(
                value: _isActive,
                contentPadding: EdgeInsets.zero,
                title: const Text('Product is active'),
                subtitle: const Text(
                  'Inactive products stay hidden from customers.',
                ),
                onChanged: (value) => setState(() => _isActive = value),
              ),
              const SizedBox(height: AppSizes.lg),
              Row(
                children: [
                  Expanded(
                    child: GlassButton(
                      label: AppStrings.cancel,
                      variant: GlassButtonVariant.ghost,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: GlassButton(
                      label: _isEditing ? AppStrings.update : AppStrings.save,
                      isLoading: state.isSaving,
                      onPressed: state.isSaving ? null : _submit,
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
    final originalPrice = double.tryParse(_originalPriceController.text.trim());
    final stock = int.tryParse(_stockController.text.trim());
    final threshold = int.tryParse(_thresholdController.text.trim());

    if (name.isEmpty ||
        sku.isEmpty ||
        shortDescription.isEmpty ||
        description.isEmpty ||
        _selectedCategoryId == null ||
        price == null ||
        stock == null ||
        threshold == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields.')),
      );
      return;
    }

    final imageList = _imagesController.text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    final draft = OwnerProductDraft(
      name: name,
      description: description,
      shortDescription: shortDescription,
      sku: sku,
      price: price,
      originalPrice: originalPrice ?? price,
      categoryId: _selectedCategoryId!,
      subCategoryId: _selectedSubCategoryId,
      stock: stock,
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
    Navigator.of(context).pop();
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: items.any((item) => item.value == value) ? value : null,
          isExpanded: true,
          hint: const Text('Select'),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
