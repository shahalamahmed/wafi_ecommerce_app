import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wafi_ecommerce_app/core/config/app_config.dart';
import 'package:wafi_ecommerce_app/core/constants/sizes.dart';
import 'package:wafi_ecommerce_app/core/constants/strings.dart';
import 'package:wafi_ecommerce_app/core/utils/validators.dart';
import 'package:wafi_ecommerce_app/features/addresses/address_model.dart';
import 'package:wafi_ecommerce_app/features/addresses/address_provider.dart';
import 'package:wafi_ecommerce_app/features/auth/auth_provider.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_button.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_card.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_chip.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_input.dart';
import 'package:wafi_ecommerce_app/shared/widgets/wafi_app_bar.dart';

class AddressScreen extends ConsumerWidget {
  const AddressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addressProvider);
    final notifier = ref.read(addressProvider.notifier);

    return Scaffold(
      appBar: const WafiAppBar(
        title: AppStrings.addresses,
        subtitle: 'Save, edit, and manage your delivery locations',
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddressSheet(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text(AppStrings.addAddress),
      ),
      body: RefreshIndicator(
        onRefresh: notifier.load,
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : state.isEmpty
            ? ListView(
                children: const [SizedBox(height: 180), _EmptyAddresses()],
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.screenPaddingH,
                  AppSizes.screenPaddingH,
                  AppSizes.screenPaddingH,
                  100,
                ),
                itemCount: state.items.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppSizes.md),
                itemBuilder: (context, index) {
                  final address = state.items[index];
                  return GlassCard(
                    variant: GlassCardVariant.elevated,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            GlassChip(
                              label: address.typeLabel,
                              variant: GlassChipVariant.primary,
                            ),
                            const SizedBox(width: AppSizes.sm),
                            if (address.isDefault)
                              const GlassChip(
                                label: AppStrings.defaultAddress,
                                variant: GlassChipVariant.success,
                              ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => showAddressSheet(
                                context,
                                ref,
                                initial: address,
                              ),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              onPressed: () => notifier.remove(address.id),
                              icon: const Icon(Icons.delete_outline_rounded),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.sm),
                        Text(
                          address.formatted,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}

Future<void> showAddressSheet(
  BuildContext context,
  WidgetRef ref, {
  AddressModel? initial,
}) async {
  final notifier = ref.read(addressProvider.notifier);
  final state = ref.read(addressProvider);
  final userId = ref.read(authProvider).user?.uid;

  if (userId == null || userId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sign in first to manage addresses.')),
    );
    return;
  }

  if (initial == null && state.items.length >= AppConfig.addressMaxCount) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text(AppStrings.maxAddress)));
    return;
  }

  final name = ValueNotifier<AddressType>(initial?.type ?? AddressType.home);
  final addressLine1 = TextEditingController(text: initial?.addressLine1 ?? '');
  final addressLine2 = TextEditingController(text: initial?.addressLine2 ?? '');
  final city = TextEditingController(text: initial?.city ?? '');
  final postalCode = TextEditingController(text: initial?.postalCode ?? '');
  final country = TextEditingController(text: initial?.country ?? 'Bangladesh');
  final isDefault = ValueNotifier<bool>(
    initial?.isDefault ?? state.items.isEmpty,
  );
  final errors = <String, String?>{};

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          AppSizes.lg,
          AppSizes.lg,
          AppSizes.lg,
          MediaQuery.of(sheetContext).viewInsets.bottom + AppSizes.xl2,
        ),
        child: GlassCard(
          variant: GlassCardVariant.elevated,
          child: StatefulBuilder(
            builder: (context, setModalState) {
              void clearFieldError(String fieldKey, String value) {
                if (value.trim().isEmpty || errors[fieldKey] == null) return;
                setModalState(() => errors[fieldKey] = null);
              }

              Future<void> submit() async {
                final nextErrors = <String, String?>{
                  'addressLine1': AppValidators.required(addressLine1.text),
                  'city': AppValidators.required(city.text),
                  'postalCode': AppValidators.required(postalCode.text),
                  'country': AppValidators.required(country.text),
                };

                setModalState(() {
                  errors
                    ..clear()
                    ..addAll(nextErrors);
                });

                if (nextErrors.values.any((error) => error != null)) return;

                await notifier.save(
                  AddressModel(
                    id: initial?.id ?? '',
                    userId: userId,
                    type: name.value,
                    addressLine1: addressLine1.text.trim(),
                    addressLine2: addressLine2.text.trim(),
                    city: city.text.trim(),
                    postalCode: postalCode.text.trim(),
                    country: country.text.trim(),
                    isDefault: isDefault.value,
                    createdAt: initial?.createdAt,
                  ),
                );

                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              }

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      initial == null
                          ? AppStrings.addAddress
                          : AppStrings.editAddress,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSizes.lg),
                    Wrap(
                      spacing: AppSizes.sm,
                      children: [
                        for (final type in AddressType.values)
                          GlassChip(
                            label: switch (type) {
                              AddressType.home => AppStrings.addressHome,
                              AddressType.office => AppStrings.addressOffice,
                              AddressType.other => AppStrings.addressOther,
                            },
                            variant: GlassChipVariant.primary,
                            isSelected: name.value == type,
                            onTap: () {
                              name.value = type;
                              setModalState(() {});
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.lg),
                    _SheetInput(
                      controller: addressLine1,
                      label: AppStrings.addressLine1,
                      isRequired: true,
                      errorText: errors['addressLine1'],
                      onChanged: (value) =>
                          clearFieldError('addressLine1', value),
                    ),
                    const SizedBox(height: AppSizes.md),
                    _SheetInput(
                      controller: addressLine2,
                      label: AppStrings.addressLine2,
                    ),
                    const SizedBox(height: AppSizes.md),
                    _SheetInput(
                      controller: city,
                      label: AppStrings.city,
                      isRequired: true,
                      errorText: errors['city'],
                      onChanged: (value) => clearFieldError('city', value),
                    ),
                    const SizedBox(height: AppSizes.md),
                    _SheetInput(
                      controller: postalCode,
                      label: AppStrings.postalCode,
                      isRequired: true,
                      errorText: errors['postalCode'],
                      onChanged: (value) =>
                          clearFieldError('postalCode', value),
                    ),
                    const SizedBox(height: AppSizes.md),
                    _SheetInput(
                      controller: country,
                      label: AppStrings.country,
                      isRequired: true,
                      errorText: errors['country'],
                      onChanged: (value) => clearFieldError('country', value),
                    ),
                    const SizedBox(height: AppSizes.md),
                    SwitchListTile(
                      value: isDefault.value,
                      onChanged: (value) {
                        isDefault.value = value;
                        setModalState(() {});
                      },
                      title: const Text(AppStrings.setDefault),
                    ),
                    const SizedBox(height: AppSizes.md),
                    GlassButton(
                      label: initial == null
                          ? AppStrings.addAddress
                          : AppStrings.update,
                      isLoading: ref.read(addressProvider).isSaving,
                      onPressed: submit,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    },
  );
}

class _SheetInput extends StatelessWidget {
  const _SheetInput({
    required this.controller,
    required this.label,
    this.isRequired = false,
    this.errorText,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final bool isRequired;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return GlassInput(
      controller: controller,
      label: label,
      isRequired: isRequired,
      hint: label,
      errorText: errorText,
      onChanged: onChanged,
    );
  }
}

class _EmptyAddresses extends StatelessWidget {
  const _EmptyAddresses();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.screenPaddingH),
        child: GlassCard(
          variant: GlassCardVariant.elevated,
          child: Column(
            children: [
              const Icon(Icons.location_on_outlined, size: AppSizes.iconXl),
              const SizedBox(height: AppSizes.md),
              Text(
                AppStrings.emptyAddress,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
