import 'package:flutter/material.dart';
import 'package:flutter_management_inventory/config/app_color.dart';

class DrawerSectionLabel extends StatelessWidget {
  const DrawerSectionLabel(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Text(
        text,
        style: TextStyle(
          color: AppColor.hint,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}