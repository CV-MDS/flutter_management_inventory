import 'package:flutter/material.dart';

import '../color.dart';

class CategoryDropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?>? onChanged;
  const CategoryDropdown({super.key,
    required this.value,
    required this.items,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: C.textDark),
          items: items
              .map((e) => DropdownMenuItem(
            value: e,
            child: Text(
              e,
              style: const TextStyle(
                color: C.textDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}