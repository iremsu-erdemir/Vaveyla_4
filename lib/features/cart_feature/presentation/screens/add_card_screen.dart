import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sweet_shop_app_ui/core/theme/dimens.dart';
import 'package:flutter_sweet_shop_app_ui/core/theme/theme.dart';
import 'package:flutter_sweet_shop_app_ui/core/widgets/app_button.dart';
import 'package:flutter_sweet_shop_app_ui/core/widgets/app_scaffold.dart';
import 'package:flutter_sweet_shop_app_ui/core/widgets/bordered_container.dart';
import 'package:flutter_sweet_shop_app_ui/core/widgets/general_app_bar.dart';
import 'package:flutter_sweet_shop_app_ui/features/cart_feature/presentation/models/payment_saved_card.dart';
import 'package:flutter_sweet_shop_app_ui/features/cart_feature/presentation/services/payment_saved_card_store.dart';

class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key, this.initialCard, this.cardIndex});

  final PaymentSavedCard? initialCard;
  final int? cardIndex;

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expirationController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _cardNameController = TextEditingController(
    text: 'Nakit Kartim',
  );

  String? _nameError;
  String? _cardNumberError;
  String? _expirationError;
  String? _cvvError;
  String? _cardNameError;

  bool get _isEditMode =>
      widget.initialCard != null && widget.cardIndex != null;

  @override
  void initState() {
    super.initState();
    final initialCard = widget.initialCard;
    if (initialCard != null) {
      _nameController.text = initialCard.cardholderName;
      _cardNumberController.text = initialCard.cardNumber;
      _expirationController.text = initialCard.expiration;
      _cvvController.text = initialCard.cvv;
      _cardNameController.text = initialCard.cardAlias;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cardNumberController.dispose();
    _expirationController.dispose();
    _cvvController.dispose();
    _cardNameController.dispose();
    super.dispose();
  }

  void _onExpirationChanged(String value) {
    if (value.length == 2 && !value.contains('/')) {
      _expirationController.text = '$value/';
      _expirationController.selection = TextSelection.fromPosition(
        TextPosition(offset: _expirationController.text.length),
      );
    }
  }

  bool _validateForm() {
    final name = _nameController.text.trim();
    final cardNumber = _cardNumberController.text.replaceAll(' ', '');
    final expiration = _expirationController.text.trim();
    final cvv = _cvvController.text.trim();
    final cardName = _cardNameController.text.trim();

    setState(() {
      _nameError =
          name.isEmpty
              ? 'cardholder_required'.tr()
              : (name.length < 3 ? 'cardholder_invalid'.tr() : null);
      if (cardNumber.isEmpty) {
        _cardNumberError = 'card_number_required'.tr();
      } else if (cardNumber.length != 16 || int.tryParse(cardNumber) == null) {
        _cardNumberError = 'card_number_invalid'.tr();
      } else {
        _cardNumberError = null;
      }
      if (expiration.isEmpty) {
        _expirationError = 'expiration_required'.tr();
      } else if (!RegExp(r'^(0[1-9]|1[0-2])\/\d{2}$').hasMatch(expiration)) {
        _expirationError = 'expiration_invalid'.tr();
      } else {
        _expirationError = null;
      }
      if (cvv.isEmpty) {
        _cvvError = 'cvv_required'.tr();
      } else if (cvv.length != 3 || int.tryParse(cvv) == null) {
        _cvvError = 'cvv_invalid'.tr();
      } else {
        _cvvError = null;
      }
      _cardNameError =
          cardName.isEmpty
              ? 'card_name_required'.tr()
              : (cardName.length < 2 ? 'card_name_invalid'.tr() : null);
    });

    return _nameError == null &&
        _cardNumberError == null &&
        _expirationError == null &&
        _cvvError == null &&
        _cardNameError == null;
  }

  void _onSave() {
    if (!_validateForm()) {
      return;
    }

    final card = PaymentSavedCard(
      cardholderName: _nameController.text.trim(),
      cardNumber: _cardNumberController.text.replaceAll(' ', ''),
      expiration: _expirationController.text.trim(),
      cvv: _cvvController.text.trim(),
      bankName: 'BANK NAME',
      cardAlias: _cardNameController.text.trim(),
    );
    if (_isEditMode) {
      PaymentSavedCardStore.updateCardAt(widget.cardIndex!, card);
    } else {
      PaymentSavedCardStore.addCard(card);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEditMode ? 'card_updated_success'.tr() : 'card_added_success'.tr(),
        ),
        backgroundColor: context.theme.appColors.success,
      ),
    );
    Navigator.of(context).pop(true);
  }

  void _onDelete() {
    if (!_isEditMode) {
      return;
    }
    final isDeleted = PaymentSavedCardStore.removeCardAt(widget.cardIndex!);
    if (!isDeleted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('card_deleted_success'.tr()),
        backgroundColor: context.theme.appColors.success,
      ),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final appTypography = context.theme.appTypography;
    final appColors = context.theme.appColors;

    return AppScaffold(
      appBar: GeneralAppBar(
        title: _isEditMode ? context.tr('edit_card') : context.tr('add_card'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: Dimens.largePadding),
            _InputLabel(text: context.tr('cardholder_name_full').toUpperCase()),
            const SizedBox(height: Dimens.smallPadding),
            _CardInputField(
              controller: _nameController,
              hintText: 'CENGIZ DEMIR',
              errorText: _nameError,
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r"[a-zA-ZğüşöçıİĞÜŞÖÇ\s]"),
                ),
              ],
            ),
            const SizedBox(height: Dimens.largePadding),
            _InputLabel(text: context.tr('card_number').toUpperCase()),
            const SizedBox(height: Dimens.smallPadding),
            _CardInputField(
              controller: _cardNumberController,
              hintText: '5400  l...   ----   ----',
              errorText: _cardNumberError,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(16),
              ],
            ),
            const SizedBox(height: Dimens.largePadding),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InputLabel(text: context.tr('expiration').toUpperCase()),
                      const SizedBox(height: Dimens.smallPadding),
                      _CardInputField(
                        controller: _expirationController,
                        hintText: 'mm/yyyy',
                        errorText: _expirationError,
                        keyboardType: TextInputType.datetime,
                        textInputAction: TextInputAction.next,
                        onChanged: _onExpirationChanged,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[\d/]')),
                          LengthLimitingTextInputFormatter(5),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Dimens.padding),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InputLabel(text: context.tr('cvv').toUpperCase()),
                      const SizedBox(height: Dimens.smallPadding),
                      _CardInputField(
                        controller: _cvvController,
                        hintText: '•••',
                        errorText: _cvvError,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Dimens.largePadding),
            _InputLabel(text: context.tr('card_name').toUpperCase()),
            const SizedBox(height: Dimens.smallPadding),
            _CardInputField(
              controller: _cardNameController,
              hintText: context.tr('card_name_hint'),
              errorText: _cardNameError,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: Dimens.extraLargePadding),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(
          left: Dimens.largePadding,
          right: Dimens.largePadding,
          bottom: Dimens.padding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isEditMode)
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _onDelete,
                  child: Text(
                    context.tr('delete_card'),
                    style: appTypography.bodyMedium.copyWith(
                      color: appColors.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            AppButton(
              onPressed: _onSave,
              title: _isEditMode ? context.tr('update') : context.tr('save'),
              textStyle: appTypography.bodyLarge.copyWith(
                color: appColors.white,
              ),
              borderRadius: Dimens.corners,
              margin: const EdgeInsets.only(top: Dimens.largePadding),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputLabel extends StatelessWidget {
  const _InputLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: context.theme.appTypography.labelSmall.copyWith(
        color: context.theme.appColors.gray2,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _CardInputField extends StatelessWidget {
  const _CardInputField({
    required this.controller,
    required this.hintText,
    this.errorText,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final String? errorText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final appTypography = context.theme.appTypography;
    final appColors = context.theme.appColors;
    return BorderedContainer(
      borderRadius: 10,
      color: appColors.gray.withValues(alpha: 0.35),
      borderColor: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: Dimens.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            inputFormatters: inputFormatters,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: appTypography.bodySmall.copyWith(
                color: appColors.gray4,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              isDense: true,
            ),
          ),
          if (errorText != null)
            Padding(
              padding: const EdgeInsets.only(bottom: Dimens.smallPadding),
              child: Text(
                errorText!,
                style: appTypography.labelSmall.copyWith(
                  color: appColors.error,
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
