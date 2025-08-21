import 'package:flutter/material.dart';

class LabelWhite extends StatelessWidget {
  final String text;
  const LabelWhite(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ));
  }
}