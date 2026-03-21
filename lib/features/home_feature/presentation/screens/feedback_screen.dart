import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sweet_shop_app_ui/core/services/app_session.dart';
import 'package:flutter_sweet_shop_app_ui/core/theme/dimens.dart';
import 'package:flutter_sweet_shop_app_ui/core/theme/theme.dart';
import 'package:flutter_sweet_shop_app_ui/core/utils/app_feedback.dart';
import 'package:flutter_sweet_shop_app_ui/core/widgets/app_button.dart';
import 'package:flutter_sweet_shop_app_ui/core/widgets/app_scaffold.dart';
import 'package:flutter_sweet_shop_app_ui/features/home_feature/data/services/feedback_service.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final FeedbackService _feedbackService = FeedbackService();
  final _restaurantNameController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _restaurantNameController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (_isSubmitting) {
      return;
    }
    if (_restaurantNameController.text.trim().isEmpty ||
        _messageController.text.trim().isEmpty) {
      context.showErrorMessage(context.tr('feedback_form_validation'));
      return;
    }

    final userId = AppSession.userId;
    if (userId.isEmpty) {
      context.showErrorMessage(context.tr('feedback_login_required'));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _feedbackService.submitFeedback(
        userId: userId,
        restaurantName: _restaurantNameController.text.trim(),
        message: _messageController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      context.showSuccessMessage(context.tr('feedback_sent_message'));
      _restaurantNameController.clear();
      _messageController.clear();
    } catch (error) {
      if (!mounted) {
        return;
      }
      context.showErrorMessage(error);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final typography = context.theme.appTypography;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1A1A1A) : colors.white;
    final inputFill = isDark ? const Color(0xFF242424) : colors.gray;
    final hintColor = isDark ? colors.gray2 : colors.gray4;
    final titleColor = isDark ? colors.primaryTint1 : colors.primaryTint2;

    return AppScaffold(
      padding: EdgeInsets.zero,
      safeAreaTop: false,
      backgroundColor: colors.secondaryShade1,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colors.primary.withValues(alpha: 0.45),
              colors.secondary.withValues(alpha: 0.32),
              colors.secondaryShade1,
            ],
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: MediaQuery.paddingOf(context).top + 6),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimens.largePadding,
                vertical: Dimens.padding,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.arrow_back, color: colors.white),
                  ),
                  Expanded(
                    child: Text(
                      context.tr('feedback'),
                      textAlign: TextAlign.center,
                      style: typography.titleLarge.copyWith(
                        color: colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(
                  Dimens.largePadding,
                  Dimens.largePadding,
                  Dimens.largePadding,
                  Dimens.extraLargePadding,
                ),
                padding: const EdgeInsets.all(Dimens.extraLargePadding),
                decoration: BoxDecoration(
                  color: cardColor.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: colors.black.withValues(alpha: 0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('feedback_need_help_title'),
                      style: typography.titleMedium.copyWith(
                        color: titleColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: Dimens.padding),
                    Text(
                      context.tr('feedback_need_help_description'),
                      style: typography.bodyMedium.copyWith(
                        color: hintColor,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: Dimens.extraLargePadding),
                    TextField(
                      controller: _restaurantNameController,
                      style: typography.bodyMedium.copyWith(
                        color: isDark ? colors.white : colors.primaryTint2,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: context.tr('feedback_restaurant_name_hint'),
                        hintStyle: typography.bodyMedium.copyWith(
                          color: hintColor,
                        ),
                        filled: true,
                        fillColor: inputFill,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: Dimens.largePadding,
                          vertical: Dimens.mediumPadding,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: colors.gray2.withValues(alpha: 0.45),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: colors.gray2.withValues(alpha: 0.45),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: colors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: Dimens.largePadding),
                    TextField(
                      controller: _messageController,
                      maxLines: 6,
                      style: typography.bodyMedium.copyWith(
                        color: isDark ? colors.white : colors.primaryTint2,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: context.tr('feedback_message_hint'),
                        hintStyle: typography.bodyMedium.copyWith(
                          color: hintColor,
                        ),
                        filled: true,
                        fillColor: inputFill,
                        contentPadding: const EdgeInsets.all(
                          Dimens.largePadding,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: colors.gray2.withValues(alpha: 0.45),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: colors.gray2.withValues(alpha: 0.45),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: colors.primary),
                        ),
                      ),
                    ),
                    const Spacer(),
                    AppButton(
                      title: context.tr('send'),
                      onPressed: _isSubmitting ? null : _submitFeedback,
                      margin: EdgeInsets.zero,
                      borderRadius: 14,
                      textStyle: typography.titleMedium.copyWith(
                        color: colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
