import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wafi_ecommerce_app/core/constants/sizes.dart';
import 'package:wafi_ecommerce_app/core/constants/strings.dart';
import 'package:wafi_ecommerce_app/core/utils/validators.dart';
import 'package:wafi_ecommerce_app/features/reviews/review_model.dart';
import 'package:wafi_ecommerce_app/features/reviews/review_provider.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_button.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_card.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_input.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_snackbar.dart';

Future<void> showReviewComposer(
  BuildContext context,
  WidgetRef ref, {
  required String productId,
  required String productName,
  required ReviewModel? existingReview,
}) async {
  ref.read(reviewMutationProvider.notifier).clearMessages();

  final result = await showModalBottomSheet<_ReviewComposerResult>(
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
          child: _ReviewComposerSheet(
            productId: productId,
            productName: productName,
            existingReview: existingReview,
          ),
        ),
      );
    },
  );

  if (!context.mounted || result == null) return;
  if (result.errorMessage != null && result.errorMessage!.isNotEmpty) {
    GlassSnackbar.error(context, result.errorMessage!);
    return;
  }
  if (result.successMessage != null && result.successMessage!.isNotEmpty) {
    GlassSnackbar.success(context, result.successMessage!);
  }
}

class _ReviewComposerResult {
  const _ReviewComposerResult({this.successMessage, this.errorMessage});

  final String? successMessage;
  final String? errorMessage;
}

class _ReviewComposerSheet extends ConsumerStatefulWidget {
  const _ReviewComposerSheet({
    required this.productId,
    required this.productName,
    required this.existingReview,
  });

  final String productId;
  final String productName;
  final ReviewModel? existingReview;

  @override
  ConsumerState<_ReviewComposerSheet> createState() =>
      _ReviewComposerSheetState();
}

class _ReviewComposerSheetState extends ConsumerState<_ReviewComposerSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _commentController;
  late int _rating;
  final Map<String, String?> _errors = <String, String?>{};

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.existingReview?.title ?? '',
    );
    _commentController = TextEditingController(
      text: widget.existingReview?.comment ?? '',
    );
    _rating = widget.existingReview?.rating ?? 0;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final nextErrors = <String, String?>{
      'rating': _rating <= 0 ? 'Select a rating.' : null,
      'title': AppValidators.required(_titleController.text),
      'comment': AppValidators.required(_commentController.text),
    };

    setState(() {
      _errors
        ..clear()
        ..addAll(nextErrors);
    });

    if (nextErrors.values.any((error) => error != null)) return;

    await ref
        .read(reviewMutationProvider.notifier)
        .submitReview(
          productId: widget.productId,
          productName: widget.productName,
          rating: _rating,
          title: _titleController.text,
          comment: _commentController.text,
        );

    final mutationState = ref.read(reviewMutationProvider);
    if (!mounted) return;

    if (mutationState.errorMessage != null &&
        mutationState.errorMessage!.isNotEmpty) {
      Navigator.of(
        context,
      ).pop(_ReviewComposerResult(errorMessage: mutationState.errorMessage));
      return;
    }

    Navigator.of(context).pop(
      _ReviewComposerResult(
        successMessage:
            mutationState.successMessage ?? 'Your review has been saved.',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mutationState = ref.watch(reviewMutationProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.existingReview == null
                ? AppStrings.writeReview
                : AppStrings.editReview,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            widget.productName,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSizes.lg),
          Text(
            AppStrings.rating,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSizes.sm),
          _InteractiveStarRating(
            rating: _rating,
            onChanged: (value) {
              setState(() {
                _rating = value;
                _errors['rating'] = null;
              });
            },
          ),
          if (_errors['rating'] != null) ...[
            const SizedBox(height: AppSizes.xs),
            Text(
              _errors['rating']!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: AppSizes.lg),
          GlassInput(
            controller: _titleController,
            label: AppStrings.reviewTitle,
            hint: 'Summarize your experience',
            maxLength: 80,
            errorText: _errors['title'],
            onChanged: (_) {
              if (_errors['title'] != null) {
                setState(() => _errors['title'] = null);
              }
            },
          ),
          const SizedBox(height: AppSizes.md),
          GlassInput(
            controller: _commentController,
            label: AppStrings.reviewComment,
            hint: 'What did you like or dislike?',
            maxLines: 5,
            maxLength: 400,
            errorText: _errors['comment'],
            onChanged: (_) {
              if (_errors['comment'] != null) {
                setState(() => _errors['comment'] = null);
              }
            },
          ),
          const SizedBox(height: AppSizes.lg),
          GlassButton(
            label: widget.existingReview == null
                ? AppStrings.writeReview
                : AppStrings.update,
            prefixIcon: Icons.rate_review_outlined,
            isLoading: mutationState.isSaving,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

class _InteractiveStarRating extends StatelessWidget {
  const _InteractiveStarRating({required this.rating, required this.onChanged});

  final int rating;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (index) {
        final value = index + 1;
        return IconButton(
          onPressed: () => onChanged(value),
          visualDensity: const VisualDensity(horizontal: -3, vertical: -3),
          padding: EdgeInsets.zero,
          icon: Icon(
            value <= rating ? Icons.star_rounded : Icons.star_border_rounded,
            color: const Color(0xFFFFB800),
            size: 30,
          ),
        );
      }),
    );
  }
}
