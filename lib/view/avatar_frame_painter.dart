import 'package:flutter/material.dart';
import 'dart:math' as math;

class AvatarFramePainter extends CustomPainter {
  final String designId;
  AvatarFramePainter(this.designId);

  @override
  void paint(Canvas canvas, Size size) {
    if (designId.isEmpty || designId == "null") return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 6;

    // Map ID Desain ke Warna/Gradient
    Map<String, List<Color>> designColors = {
      "DESIGN_GOLD_ELITE": [Color(0xFFFFD700), Color(0xFFB8860B)],
      "DESIGN_NEON_CYBER": [Color(0xFF00FBFF), Color(0xFF0045FF)],
      "DESIGN_NATURE_GREEN": [Color(0xFF4CAF50), Color(0xFF1B5E20)],
      "DESIGN_OCEAN_BLUE": [Color(0xFF2196F3), Color(0xFF0D47A1)],
      "DESIGN_ARCANE_PURPLE": [Color(0xFF9C27B0), Color(0xFF4A148C)],
      "DESIGN_STELLAR_STARS": [Color(0xFFE91E63), Color(0xFF311B92)],
      "DESIGN_STONE_GRAY": [Color(0xFF9E9E9E), Color(0xFF424242)],
      "DESIGN_QUANTUM_ORANGE": [Color(0xFFFF9800), Color(0xFFE65100)],
      "DESIGN_SPECTRUM_RAINBOW": [Colors.red, Colors.blue, Colors.green, Colors.yellow],
      "DESIGN_FROST_WHITE": [Color(0xFFE3F2FD), Color(0xFF90CAF9)],
      "DESIGN_SHADOW_BLACK": [Color(0xFF212121), Color(0xFF000000)],
      "DESIGN_CRIMSON_RED": [Color(0xFFF44336), Color(0xFFB71C1C)],
      "DESIGN_GLITCH_MAGENTA": [Color(0xFFFF00FF), Color(0xFF00FFFF)],
      "DESIGN_SILVER_ROYAL": [Color(0xFFE0E0E0), Color(0xFF757575)],
      "DESIGN_AUTUMN_BROWN": [Color(0xFF795548), Color(0xFF3E2723)],
      "DESIGN_ELECTRIC_YELLOW": [Color(0xFFFFEB3B), Color(0xFFFBC02D)],
      "DESIGN_TOXIC_LIME": [Color(0xFFCDDC39), Color(0xFF827717)],
      "DESIGN_ZEN_BAMBOO": [Color(0xFF8BC34A), Color(0xFF33691E)],
      "DESIGN_MIDNIGHT_NAVY": [Color(0xFF3F51B5), Color(0xFF1A237E)],
      "DESIGN_LAVA_HOT": [Color(0xFFFF5722), Color(0xFFBF360C)],
    };

    List<Color> colors = designColors[designId] ?? [Colors.grey, Colors.black];

    // Menambahkan Efek Glow untuk desain tertentu (Neon, Arcane, Glitch)
    if (designId.contains("NEON") || designId.contains("ARCANE") || designId.contains("GLITCH")) {
      paint.maskFilter = const MaskFilter.blur(BlurStyle.outer, 10);
    }

    paint.shader = LinearGradient(
      colors: colors,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    // Gambar Lingkaran Bingkai
    canvas.drawCircle(center, radius, paint);

    // Tambahan Ornamen untuk desain Elite
    if (designId.contains("ELITE") || designId.contains("ROYAL")) {
      canvas.drawCircle(center, radius + 4, paint..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}