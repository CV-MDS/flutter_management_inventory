import 'package:flutter/material.dart';
import 'package:flutter_management_inventory/config/app_color.dart';

class ActivityTile extends StatelessWidget {
  const ActivityTile({super.key,
    required this.title,
    required this.subtitle,
    required this.trailingTime,
  });

  final String title;
  final String subtitle;
  final String trailingTime;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF7EB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.check_circle, color: Colors.green),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Login",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColor.textDark,
                    )),
                SizedBox(height: 2),
                Text("Login by admin",
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColor.hint,
                      fontWeight: FontWeight.w600,
                    )),
              ],
            ),
          ),
          Text(trailingTime,
              style: const TextStyle(
                color: AppColor.hint,
                fontWeight: FontWeight.w700,
              )),
        ],
      ),
    );
  }
}