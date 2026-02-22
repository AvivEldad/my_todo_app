import 'package:flutter/material.dart';

class XpBar extends StatelessWidget {
  final int level;
  final int xp;
  final int xpPerLevel;

  const XpBar({
    super.key,
    required this.level,
    required this.xp,
    this.xpPerLevel = 100,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Level $level', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('$xp / $xpPerLevel XP'),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: xp / xpPerLevel,
            color: Colors.amber,
            backgroundColor: Colors.grey[800],
          ),
        ],
      ),
    );
  }
}
