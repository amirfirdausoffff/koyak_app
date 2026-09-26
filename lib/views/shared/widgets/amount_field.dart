import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';

/// Ringgit input with an always-visible `RM` prefix and 2-decimal limit.
class AmountField extends StatelessWidget {
  const AmountField({
    super.key,
    required this.controller,
    this.hintText = '0.00',
    this.focusNode,
    this.autofocus = false,
    this.large = false,
    this.composer = false,
    this.textInputAction,
    this.onSubmitted,
    this.allowZero = false,
    this.optional = false,
  });

  final TextEditingController controller;
  final String hintText;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool large;

  /// A borderless, large amount field used in the Belanja smart composer.
  final bool composer;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  /// Accept RM 0 (e.g. an account that is now empty).
  final bool allowZero;

  /// Accept an empty field (nothing to change).
  final bool optional;

  static String? validate(
    String? value, {
    bool allowZero = false,
    bool optional = false,
  }) {
    final text = value?.trim() ?? '';
    if (text.isEmpty && optional) return null;
    final amount = CurrencyFormatter.parse(text);
    final isValid = amount != null && (allowZero ? amount >= 0 : amount > 0);
    return isValid ? null : 'Masukkan jumlah RM yang sah';
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = composer ? 34.0 : (large ? 26.0 : 16.0);
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: textInputAction,
      inputFormatters: [AmountInputFormatter()],
      validator: (value) =>
          validate(value, allowZero: allowZero, optional: optional),
      onFieldSubmitted: onSubmitted,
      style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        filled: !composer,
        fillColor: composer ? Colors.transparent : null,
        contentPadding: composer
            ? const EdgeInsets.only(bottom: 12)
            : null,
        hintText: hintText,
        hintStyle: TextStyle(
          fontSize: large ? fontSize : 15,
          fontWeight: large ? FontWeight.w700 : FontWeight.w400,
          color: AppColors.textMuted,
        ),
        border: composer
            ? const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.border),
              )
            : null,
        enabledBorder: composer
            ? const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.border),
              )
            : null,
        focusedBorder: composer
            ? const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.green, width: 2),
              )
            : null,
        errorBorder: composer
            ? const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.amber),
              )
            : null,
        focusedErrorBorder: composer
            ? const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.amber, width: 2),
              )
            : null,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 16, right: 8),
          child: Text(
            CurrencyFormatter.symbol,
            style: TextStyle(
              fontSize: fontSize * 0.7,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(),
      ),
    );
  }
}

/// Digits with at most 2 decimals; a comma typed as decimal becomes a dot.
class AmountInputFormatter extends TextInputFormatter {
  static final _pattern = RegExp(r'^\d{0,9}(\.\d{0,2})?$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(',', '.');
    return _pattern.hasMatch(text) ? newValue.copyWith(text: text) : oldValue;
  }
}
