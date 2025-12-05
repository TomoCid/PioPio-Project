import 'package:flutter/material.dart';

class GenericSearchItem extends StatelessWidget {
  final Widget leftContent;
  final Widget rightContent;
  final VoidCallback? onTap;

  const GenericSearchItem({
    super.key,
    required this.leftContent,
    required this.rightContent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const double itemHeight = 80.0;
    final borderRadius = BorderRadius.circular(12.0);

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Row(
          children: [
            Container(
              width: itemHeight,
              height: itemHeight,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: borderRadius,
              ),
              child: Center(child: leftContent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: itemHeight,
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: borderRadius,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: rightContent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
