import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme.dart';

/// Realistic mechanical gear (cog).
///
/// Trapezoidal teeth with **softly rounded tips** (quadratic curves at the
/// crown of each tooth + fillet curves at the root) for a true machined-cog
/// look — not razor-sharp, not balloon-smooth. Hub ring with 6 bolt holes
/// and a center axle hole. Two interlocked gears rotating in opposite
/// directions like a real gear pair.
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
        AnimatedBuilder(animation: _a, builder: (_, __) =>
          Transform.rotate(angle: _a.value * 2 * pi,
            child: CustomPaint(size: Size.square(widget.size * 0.92), painter: _RealGear(primary, teeth: 12)))),
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

class _RealGear extends CustomPainter {
  final Color color;
  final int teeth;
  _RealGear(this.color, {this.teeth = 12});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final R = size.width * 0.50;          // tooth tip radius
    final r = R * 0.84;                    // tooth root radius
    final hubOuter = R * 0.55;
    final hubInner = R * 0.42;
    final bolt = R * 0.06;
    final boltRing = (hubInner + hubOuter) / 2;
    final axle = R * 0.12;

    final step = 2 * pi / teeth;
    // Tooth angular geometry:
    //   tip occupies (2 * tipHalf) at radius R
    //   root gap occupies (2 * rootHalf) at radius r
    final tipHalf = step * 0.16;
    final rootHalf = step * 0.30;

    Offset pt(double radius, double angle) =>
        Offset(c.dx + radius * cos(angle), c.dy + radius * sin(angle));

    final path = Path();
    for (int i = 0; i < teeth; i++) {
      final centerAng = i * step - pi / 2;
      final rootStart = centerAng - step * 0.5 + rootHalf;
      final tipStart  = centerAng - tipHalf;
      final tipEnd    = centerAng + tipHalf;
      final rootEnd   = centerAng + step * 0.5 - rootHalf;
      final nextRootStart = ((i + 1) % teeth) * step - pi / 2 - step * 0.5 + rootHalf;

      // Tooth profile (per tooth):
      //   p1: root start (left side of tooth base)
      //   p2: tip start  (left tip corner) — slightly raised
      //   crown: midpoint of tip arc (for the rounded top)
      //   p3: tip end (right tip corner)
      //   p4: root end (right side of tooth base)
      final p1 = pt(r, rootStart);
      final p2 = pt(R, tipStart);
      final p3 = pt(R, tipEnd);
      final p4 = pt(r, rootEnd);
      // Crown control: a tiny bit ABOVE R so the quadratic curve produces
      // a soft dome instead of a sharp peak.
      final crownAng = centerAng;
      final crownCtrl = pt(R * 1.04, crownAng);
      // Fillet (concave round) between teeth: control point INSIDE the
      // gear (smaller radius) so the curve dips into the root smoothly.
      final filletCtrlMid = (rootEnd + nextRootStart) / 2;
      final filletCtrl = pt(r * 0.94, filletCtrlMid);
      final pNext = pt(r, nextRootStart);

      if (i == 0) {
        path.moveTo(p1.dx, p1.dy);
      }
      // Up the left flank (straight)
      path.lineTo(p2.dx, p2.dy);
      // Rounded crown over the tip
      path.quadraticBezierTo(crownCtrl.dx, crownCtrl.dy, p3.dx, p3.dy);
      // Down the right flank (straight)
      path.lineTo(p4.dx, p4.dy);
      // Soft fillet across the root to the next tooth
      path.quadraticBezierTo(filletCtrl.dx, filletCtrl.dy, pNext.dx, pNext.dy);
    }
    path.close();

    // Drop shadow for depth (subtle)
    canvas.save();
    canvas.translate(0, R * 0.025);
    canvas.drawPath(path, Paint()
      ..color = Colors.black.withOpacity(0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5));
    canvas.restore();

    // Main gear body
    canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.fill);

    // Subtle highlight along the inside of the root circle for depth
    canvas.drawCircle(c, r, Paint()
      ..color = Colors.white.withOpacity(0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = R * 0.04);

    // Raised hub ring (lighter tint)
    canvas.drawCircle(c, hubOuter, Paint()..color = Colors.white.withOpacity(0.16));
    canvas.drawCircle(c, hubInner, Paint()..color = color);
    canvas.drawCircle(c, hubInner, Paint()
      ..color = Colors.black.withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = R * 0.022);

    // 6 bolt holes on the hub ring (with darker interior, light rim)
    for (int i = 0; i < 6; i++) {
      final a = i * pi / 3;
      final p = Offset(c.dx + boltRing * cos(a), c.dy + boltRing * sin(a));
      canvas.drawCircle(p, bolt, Paint()..color = Colors.white.withOpacity(0.92));
      canvas.drawCircle(p, bolt * 0.55, Paint()..color = color.withOpacity(0.55));
    }

    // Center axle hole
    canvas.drawCircle(c, axle, Paint()..color = Colors.white);
    canvas.drawCircle(c, axle, Paint()
      ..color = Colors.black.withOpacity(0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = R * 0.018);
  }

  @override
  bool shouldRepaint(covariant _RealGear old) => old.color != color || old.teeth != teeth;
}
