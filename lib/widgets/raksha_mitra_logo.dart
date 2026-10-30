
import 'package:flutter/material.dart';

class RakshaMitraLogo extends StatelessWidget {
  final double size;
  final Color backgroundColor;
  final Color shieldColor;
  final bool showBackground;

  const RakshaMitraLogo({
    super.key,
    this.size = 52,
    this.backgroundColor = const Color(0xFFEDE9FE),
    this.shieldColor = const Color(0xFF173B70),
    this.showBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: showBackground ? backgroundColor : Colors.transparent,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Main shield
          Icon(
            Icons.shield_rounded,
            size: size * 0.76,
            color: shieldColor,
          ),

          // AI face inside the shield
          Positioned(
            top: size * 0.35,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _eye(size),
                SizedBox(width: size * 0.12),
                _eye(size),
              ],
            ),
          ),

          // Friendly AI smile
          Positioned(
            top: size * 0.54,
            child: Container(
              width: size * 0.22,
              height: size * 0.10,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: shieldColor,
                    width: size * 0.045,
                  ),
                ),
                borderRadius: BorderRadius.circular(size),
              ),
            ),
          ),

          // AI sparkle
          Positioned(
            top: size * 0.08,
            right: size * 0.06,
            child: Icon(
              Icons.auto_awesome_rounded,
              size: size * 0.28,
              color: const Color(0xFF8B5CF6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _eye(double size) {
    return Container(
      width: size * 0.09,
      height: size * 0.09,
      decoration: BoxDecoration(
        color: shieldColor,
        shape: BoxShape.circle,
      ),
    );
  }
}
