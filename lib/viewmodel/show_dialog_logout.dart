import 'package:flutter/material.dart';

Future<bool> showConfirmLogoutDialog(BuildContext context) async {
  final res = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: const Text('Logout'),
      content: const Text('Apakah kamu yakin ingin keluar dari akun?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Logout'),
        ),
      ],
    ),
  );
  return res ?? false;
}