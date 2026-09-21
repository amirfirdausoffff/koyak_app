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
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hintText;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool large;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  static String? validate(String? value) {
    final amount = CurrencyFormatter.parse(value ?? '');
    return amount == null || amount <= 0 ? 'Masukkan jumlah RM yang sah' : null;
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = large ? 26.0 : 16.0;
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: textInputAction,
      inputFormatters: [AmountInputFormatter()],
      validator: validate,
      onFieldSubmitted: onSubmitted,
      style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          fontSize: large ? fontSize : 15,
          fontWeight: large ? FontWeight.w700 : FontWeight.w400,
          color: AppColors.textMuted,
        ),
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
