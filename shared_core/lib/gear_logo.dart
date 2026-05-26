import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme.dart';

/// Realistic mechanical gear (cog) with crisp trapezoidal teeth, a hub with
/// 6 bolt holes, and a center axle. Two interlocked gears that rotate in
/// opposite directions like a real gear pair.
class GearLogo extends StatefulWidget {
  final double size;
  final bool showText;
  final Color? primary;
  final Color? secondary;
  const GearLogo({super.key, this.size = 96, this.showText = true, this.primary, this.secondary});
  @override
  State<GearLogo> createState() => _GearLogoState();
}

class _GearLogoState extends State<GearLogo> with TickerProviderStateMixin {
  late final _a = AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();
  late final _b = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();

  @override
  void dispose() { _a.dispose(); _b.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final primary = widget.primary ?? AppColors.orange;
    final secondary = widget.secondary ?? AppColors.orangeDark;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(width: widget.size, height: widget.size, child: Stack(alignment: Alignment.center, children: [
        // Big gear (background)
        AnimatedBuilder(animation: _a, builder: (_, __) =>
          Transform.rotate(angle: _a.value * 2 * pi,
            child: CustomPaint(size: Size.square(widget.size * 0.92), painter: _RealGear(primary, teeth: 12)))),
        // Small gear (foreground, opposite rotation)
        Positioned(right: 0, bottom: 0,
          child: AnimatedBuilder(animation: _b, builder: (_, __) =>
            Transform.rotate(angle: -_b.value * 2 * pi,
              child: CustomPaint(size: Size.square(widget.size * 0.50), painter: _RealGear(secondary, teeth: 10))))),
      ])),
      if (widget.showText) ...[
        const SizedBox(height: 14),
        Text('Yichalal',
          style: GoogleFonts.poppins(
            fontSize: widget.size * 0.32, fontWeight: FontWeight.w800, letterSpacing: 0.3,
            color: isDark ? AppColors.darkText : AppColors.text,
          )),
        Text('ENGINEERING',
          style: GoogleFonts.poppins(
            fontSize: widget.size * 0.115, letterSpacing: widget.size * 0.045,
            fontWeight: FontWeight.w600, color: primary,
          )),
      ],
    ]);
  }
}

/// Authentic-looking gear: trapezoidal teeth (wider base, narrower tip),
/// inner hub ring, 6 bolt holes, and a center axle hole. Reads as a real cog.
class _RealGear extends CustomPainter {
  final Color color;
  final int teeth;
  _RealGear(this.color, {this.teeth = 12});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final R = size.width * 0.50;          // tooth tip radius
    final r = R * 0.84;                    // tooth root radius
    final hubOuter = R * 0.55;             // outer hub ring radius
    final hubInner = R * 0.42;             // inner hub ring radius
    final bolt = R * 0.06;                 // bolt-hole radius
    final boltRing = (hubInner + hubOuter) / 2;
    final axle = R * 0.12;                 // center axle hole

    // Tooth geometry: each tooth occupies (2π/teeth). Tooth has a top
    // (between tipL and tipR) and a root gap between teeth.
    final step = 2 * pi / teeth;
    final tipHalf = step * 0.18;          // half-angle at the tooth tip
    final rootHalf = step * 0.30;          // half-angle at the tooth root
    final flank = step * 0.5 - tipHalf;    // angle between root and tip

    final path = Path();
    for (int i = 0; i < teeth; i++) {
      final centerAng = i * step - pi / 2;
      final rootStart = centerAng - step * 0.5 + rootHalf;
      final tipStart  = centerAng - tipHalf;
      final tipEnd    = centerAng + tipHalf;
      final rootEnd   = centerAng + step * 0.5 - rootHalf;

      final p1 = Offset(c.dx + r * cos(rootStart), c.dy + r * sin(rootStart));
      final p2 = Offset(c.dx + R * cos(tipStart), c.dy + R * sin(tipStart));
      final p3 = Offset(c.dx + R * cos(tipEnd), c.dy + R * sin(tipEnd));
      final p4 = Offset(c.dx + r * cos(rootEnd), c.dy + r * sin(rootEnd));

      if (i == 0) path.moveTo(p1.dx, p1.dy);
      else path.lineTo(p1.dx, p1.dy);
      path.lineTo(p2.dx, p2.dy);           // flank up
      path.lineTo(p3.dx, p3.dy);           // tip
      path.lineTo(p4.dx, p4.dy);           // flank down
      // tiny arc along the root to the next tooth's start
      final nextRootStart = ((i + 1) % teeth) * step - pi / 2 - step * 0.5 + rootHalf;
      final pNext = Offset(c.dx + r * cos(nextRootStart), c.dy + r * sin(nextRootStart));
      path.lineTo(pNext.dx, pNext.dy);
    }
    path.close();

    // Fill main body
    canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.fill);

    // Subtle inner highlight ring (depth)
    canvas.drawCircle(c, r, Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = R * 0.04);

    // Inner hub ring (raised look)
    canvas.drawCircle(c, hubOuter, Paint()..color = Colors.white.withOpacity(0.14));
    canvas.drawCircle(c, hubInner, Paint()..color = color);
    canvas.drawCircle(c, hubInner, Paint()
      ..color = Colors.black.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = R * 0.02);

    // 6 bolt holes on the hub ring
    for (int i = 0; i < 6; i++) {
      final a = i * pi / 3;
      final p = Offset(c.dx + boltRing * cos(a), c.dy + boltRing * sin(a));
      canvas.drawCircle(p, bolt, Paint()..color = Colors.white.withOpacity(0.85));
      canvas.drawCircle(p, bolt * 0.55, Paint()..color = color.withOpacity(0.7));
    }

    // Center axle hole
    canvas.drawCircle(c, axle, Paint()..color = Colors.white);
    canvas.drawCircle(c, axle, Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = R * 0.015);
  }

  @override
  bool shouldRepaint(covariant _RealGear old) => old.color != color || old.teeth != teeth;
}
