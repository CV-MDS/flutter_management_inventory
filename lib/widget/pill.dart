import 'package:flutter/material.dart';

class Pill extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  final EdgeInsets padding;
  final double radius;
  const Pill({
    super.key,
    required this.text,
    required this.bg,
    required this.fg,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(radius)),
      child: Text(
        text,
        style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}