import 'package:flutter/material.dart';

class AdBadge extends StatelessWidget {
  const AdBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: 2,
        horizontal: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.amber.shade700.withAlpha(30),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        'AD',
        style: TextStyle(
          color: Colors.amber.shade700,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}
