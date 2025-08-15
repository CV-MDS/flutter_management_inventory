import 'package:flutter/material.dart';
import 'package:flutter_management_inventory/config/app_color.dart';

class CircleIcon extends StatelessWidget {
  const CircleIcon({
    required this.icon,
    this.onTap,
    this.dark = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final bg = dark ? AppColor.dark : Colors.white;
    final fg = dark ? Colors.white : AppColor.textDark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            if (!dark)
              BoxShadow(
                color: Colors.black.withOpacity(.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Icon(icon, color: fg),
      ),
    );
  }
}
