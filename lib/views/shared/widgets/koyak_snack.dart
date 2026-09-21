import 'package:flutter/material.dart';

void showKoyakSnack(
  BuildContext context,
  String message, {
  VoidCallback? onUndo,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        // Actions make snack bars sticky by default; undo should time out.
        persist: false,
        action: onUndo == null
            ? null
            : SnackBarAction(label: 'Undo', onPressed: onUndo),
      ),
    );
}
