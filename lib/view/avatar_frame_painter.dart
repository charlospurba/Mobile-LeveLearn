// import 'package:flutter/material.dart';
// import 'dart:math' as math;

// class AvatarFramePainter extends CustomPainter {
//   final String designId;
//   AvatarFramePainter(this.designId);

//   @override
//   void paint(Canvas canvas, Size size) {
//     if (designId.isEmpty || designId == "null") return;

//     final center = Offset(size.width / 2, size.height / 2);
//     final radius = size.width / 2;
//     final rect = Rect.fromCircle(center: center, radius: radius);

//     final paint = Paint()
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 8
//       ..strokeCap = StrokeCap.round;

//     // --- 1. SETTING WARNA BERDASARKAN DESIGN ---
//     Map<String, List<Color>> designColors = {
//       "DESIGN_UNIQUE_WITCH": [Colors.deepPurple, Colors.blueAccent],
//       "DESIGN_UNIQUE_BUNNY_TECH": [Colors.pink.shade100, Colors.white],
//       "DESIGN_UNIQUE_BUTTERFLY": [Colors.blueAccent, Colors.purpleAccent.shade100],
//       "DESIGN_UNIQUE_NATURE": [Colors.green, Colors.limeAccent],
//       "DESIGN_UNIQUE_CROWN": [Colors.orange, Colors.pinkAccent],
//       "DESIGN_UNIQUE_FOX": [Colors.orangeAccent, Colors.redAccent],
//       "DESIGN_UNIQUE_RAINBOW": [Colors.lightBlueAccent, Colors.white],
//     };

//     List<Color> colors = designColors[designId] ?? [Colors.pinkAccent, Colors.orangeAccent];
//     paint.shader = LinearGradient(
//       begin: Alignment.topLeft,
//       end: Alignment.bottomRight,
//       colors: colors,
//     ).createShader(rect);

//     final fillPaint = Paint()
//       ..style = PaintingStyle.fill
//       ..shader = paint.shader;

//     // --- 2. GAMBAR ORNAMEN UNIK (Lapis Bawah/Atas) ---

//     // A. BUTTERFLY WINGS (Kiri & Kanan Besar)
//     if (designId.contains("BUTTERFLY")) {
//       _drawButterflyWings(canvas, size, fillPaint);
//     }

//     // B. WITCH HAT (Topi Miring)
//     if (designId.contains("WITCH")) {
//       _drawWitchHat(canvas, size, fillPaint);
//     }

//     // C. CYBER BUNNY (Headset + Telinga)
//     if (designId.contains("BUNNY_TECH")) {
//       _drawCyberBunny(canvas, size, fillPaint, paint);
//     }

//     // D. FOX TAIL & EARS
//     if (designId.contains("FOX")) {
//       _drawFoxFeatures(canvas, size, fillPaint);
//     }

//     // E. CROWN (Royal)
//     if (designId.contains("CROWN")) {
//       _drawCrown(canvas, size, fillPaint);
//     }

//     // --- 3. GAMBAR LINGKARAN UTAMA (BINGKAI) ---
//     // Efek bayangan luar
//     canvas.drawCircle(center, radius, Paint()
//       ..color = Colors.black26
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 10
//       ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    
//     canvas.drawCircle(center, radius, paint);
//   }

//   void _drawButterflyWings(Canvas canvas, Size size, Paint paint) {
//     Path leftWing = Path();
//     leftWing.moveTo(size.width * 0.2, size.height * 0.5);
//     leftWing.cubicTo(-size.width * 0.4, 0, -size.width * 0.2, size.height, size.width * 0.2, size.height * 0.8);
//     canvas.drawPath(leftWing, paint);

//     Path rightWing = Path();
//     rightWing.moveTo(size.width * 0.8, size.height * 0.5);
//     rightWing.cubicTo(size.width * 1.4, 0, size.width * 1.2, size.height, size.width * 0.8, size.height * 0.8);
//     canvas.drawPath(rightWing, paint);
//   }

//   void _drawWitchHat(Canvas canvas, Size size, Paint paint) {
//     Path hat = Path();
//     hat.moveTo(size.width * 0.1, size.height * 0.3); // Alas topi
//     hat.lineTo(size.width * 0.9, size.height * 0.1);
//     hat.lineTo(size.width * 0.5, -size.height * 0.4); // Puncak topi
//     hat.close();
//     canvas.drawPath(hat, paint);
//   }

//   void _drawCyberBunny(Canvas canvas, Size size, Paint fill, Paint stroke) {
//     // Telinga Kiri melengkung
//     canvas.drawOval(Rect.fromLTWH(size.width * 0.1, -size.height * 0.3, size.width * 0.15, size.height * 0.5), fill);
//     // Telinga Kanan nekuk
//     Path path = Path();
//     path.moveTo(size.width * 0.7, size.height * 0.1);
//     path.lineTo(size.width * 0.9, -size.height * 0.2);
//     path.lineTo(size.width * 1.1, 0);
//     canvas.drawPath(path, fill);
//     // Headset bawah
//     canvas.drawRRect(RRect.fromLTRBR(size.width * 0.05, size.height * 0.7, size.width * 0.2, size.height * 0.9, const Radius.circular(5)), fill);
//   }

//   void _drawFoxFeatures(Canvas canvas, Size size, Paint paint) {
//     // Ekor di bawah
//     Path tail = Path();
//     tail.moveTo(size.width * 0.5, size.height * 0.9);
//     tail.quadraticBezierTo(size.width * 1.2, size.height * 1.1, size.width * 0.8, size.height * 0.7);
//     canvas.drawPath(tail, paint);
//     // Telinga lancip
//     canvas.drawPath(Path()..moveTo(size.width * 0.2, size.height * 0.2)..lineTo(size.width * 0.1, 0)..lineTo(size.width * 0.4, size.height * 0.1), paint);
//     canvas.drawPath(Path()..moveTo(size.width * 0.8, size.height * 0.2)..lineTo(size.width * 0.9, 0)..lineTo(size.width * 0.6, size.height * 0.1), paint);
//   }

//   void _drawCrown(Canvas canvas, Size size, Paint paint) {
//     Path crown = Path();
//     crown.moveTo(size.width * 0.3, size.height * 0.1);
//     crown.lineTo(size.width * 0.3, -size.height * 0.1);
//     crown.lineTo(size.width * 0.5, 0); // Tengah
//     crown.lineTo(size.width * 0.7, -size.height * 0.1);
//     crown.lineTo(size.width * 0.7, size.height * 0.1);
//     canvas.drawPath(crown, paint);
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }