import 'package:flutter/material.dart';

class NumberedMapMarker extends StatelessWidget {
  final int number;
  final String name;
  final VoidCallback? onTap;

  const NumberedMapMarker({
    super.key,
    required this.number,
    required this.name,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 18,
        height: 18,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF0E2958),
              width: 1.2,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            '$number',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF0E2958),
              fontSize: 8,
              fontWeight: FontWeight.w700,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}
