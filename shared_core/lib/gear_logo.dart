import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme.dart';

/// Realistic mechanical gear (cog).
///
/// Cubic-bezier tooth profile (involute approximation) for a true machined
/// gear look. 14 teeth, trapezoidal flanks with rounded tips and concave
/// fillets at the root — same silhouette as a real industrial spur gear.
/// Includes raised hub ring with 6 bolt holes and a chamfered center axle.
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
  late final _a = AnimationController(vsync: this, duration: const Duration(seconds: 16))..repeat();
  late final _b = AnimationController(vsync: this, duration: const Duration(seconds: 11))..repeat();

  @override
  void dispose() { _a.dispose(); _b.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final primary = widget.primary ?? AppColors.orange;
    final secondary = widget.secondary ?? AppColors.orangeDark;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(width: widget.size, height: widget.size, child: Stack(alignment: Alignment.center, children: [
        // Big gear
        AnimatedBuilder(animation: _a, builder: (_, __) =>
          Transform.rotate(angle: _a.value * 2 * pi,
            child: CustomPaint(size: Size.square(widget.size * 0.92), painter: _RealGear(primary, teeth: 14)))),
        // Small gear — positioned so its teeth visually mesh with the big gear
        Positioned(right: 0, bottom: 0,
          child: AnimatedBuilder(animation: _b, builder: (_, __) =>
            Transform.rotate(angle: -_b.value * 2 * pi,
              child: CustomPaint(size: Size.square(widget.size * 0.48), painter: _RealGear(secondary, teeth: 10))))),
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
  _RealGear(this.color, {this.teeth = 14});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final R = size.width * 0.50;       // outside (addendum) radius — tip of tooth
    final r = R * 0.83;                 // root (dedendum) radius
    final hubOuter = R * 0.50;
    final hubInner = R * 0.36;
    final bolt = R * 0.055;
    final boltRing = (hubInner + hubOuter) / 2;
    final axle = R * 0.10;

    final step = 2 * pi / teeth;
    // Tooth widths (in angular units of a single tooth pitch):
    //   - tip face occupies tipFrac of the pitch
    //   - root gap occupies rootFrac of the pitch
    //   - the two flanks take the rest
    const tipFrac = 0.32;
    const rootFrac = 0.46;
    final tipHalf = step * tipFrac * 0.5;
    final rootHalf = step * rootFrac * 0.5;

    Offset pt(double radius, double angle) =>
        Offset(c.dx + radius * cos(angle), c.dy + radius * sin(angle));

    final path = Path();

    for (int i = 0; i < teeth; i++) {
      final centerAng = i * step - pi / 2;
      // 4 key angles of THIS tooth:
      final rootStart = centerAng - step * 0.5 + rootHalf;   // left fillet end (on root circle)
      final tipStart  = centerAng - tipHalf;                  // left tip corner (on outside circle)
      final tipEnd    = centerAng + tipHalf;                  // right tip corner
      final rootEnd   = centerAng + step * 0.5 - rootHalf;    // right fillet start
      final nextRootStart = ((i + 1) % teeth) * step - pi / 2 - step * 0.5 + rootHalf;

      final pLeftRoot  = pt(r, rootStart);
      final pLeftTip   = pt(R, tipStart);
      final pRightTip  = pt(R, tipEnd);
      final pRightRoot = pt(r, rootEnd);
      final pNextLeftRoot = pt(r, nextRootStart);

      // Flank control points — pull them slightly INWARD to give the flanks
      // a gentle inward (involute-like) curve instead of being dead straight.
      // This is what makes a gear look like a gear and not a star.
      final leftFlankCtrlAng = (rootStart + tipStart) / 2;
      final leftFlankCtrlRad = (r + R) * 0.50 - R * 0.015;
      final leftFlankCtrl = pt(leftFlankCtrlRad, leftFlankCtrlAng);

      final rightFlankCtrlAng = (tipEnd + rootEnd) / 2;
      final rightFlankCtrl = pt(leftFlankCtrlRad, rightFlankCtrlAng);

      // Tip crown control — slightly above R so the tip is a soft dome
      final crownCtrl = pt(R * 1.025, centerAng);

      // Root fillet control — INSIDE the root circle so it dips smoothly
      final filletAng = (rootEnd + nextRootStart) / 2;
      final filletCtrl = pt(r * 0.96, filletAng);

      if (i == 0) path.moveTo(pLeftRoot.dx, pLeftRoot.dy);

      // Left flank: gentle inward curve from root → tip-left-corner
      path.quadraticBezierTo(leftFlankCtrl.dx, leftFlankCtrl.dy, pLeftTip.dx, pLeftTip.dy);
      // Rounded tip crown
      path.quadraticBezierTo(crownCtrl.dx, crownCtrl.dy, pRightTip.dx, pRightTip.dy);
      // Right flank: mirror curve, tip-right-corner → root
      path.quadraticBezierTo(rightFlankCtrl.dx, rightFlankCtrl.dy, pRightRoot.dx, pRightRoot.dy);
      // Concave fillet at the bottom of the valley between teeth
      path.quadraticBezierTo(filletCtrl.dx, filletCtrl.dy, pNextLeftRoot.dx, pNextLeftRoot.dy);
    }
    path.close();

    // Drop shadow for depth
    canvas.save();
    canvas.translate(0, R * 0.03);
    canvas.drawPath(path, Paint()
      ..color = Colors.black.withOpacity(0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    canvas.restore();

    // Main gear body — slight radial highlight via two-stop gradient
    final rect = Rect.fromCircle(center: c, radius: R);
    canvas.drawPath(path, Paint()..shader = RadialGradient(
      colors: [_lighten(color, 0.12), color, _darken(color, 0.08)],
      stops: const [0.0, 0.65, 1.0],
    ).createShader(rect));

    // Inner ring highlight for depth (just inside the root circle)
    canvas.drawCircle(c, r * 0.97, Paint()
      ..color = Colors.white.withOpacity(0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = R * 0.025);

    // Hub — raised ring (lighter), inner disc (mid), darker rim line
    canvas.drawCircle(c, hubOuter, Paint()..color = _lighten(color, 0.10));
    canvas.drawCircle(c, hubInner, Paint()..color = color);
    canvas.drawCircle(c, hubInner, Paint()
      ..color = Colors.black.withOpacity(0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = R * 0.022);

    // 6 bolt holes around the hub ring (machined look — light face + darker bore)
    for (int i = 0; i < 6; i++) {
      final a = i * pi / 3;
      final p = Offset(c.dx + boltRing * cos(a), c.dy + boltRing * sin(a));
      // bolt face (light)
      canvas.drawCircle(p, bolt, Paint()..color = Colors.white.withOpacity(0.92));
      // bore (small dark dot in middle)
      canvas.drawCircle(p, bolt * 0.45, Paint()..color = _darken(color, 0.30));
      // outer ring shadow
      canvas.drawCircle(p, bolt, Paint()
        ..color = Colors.black.withOpacity(0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = R * 0.012);
    }

    // Center axle hole (chamfered)
    canvas.drawCircle(c, axle * 1.25, Paint()..color = Colors.white.withOpacity(0.85));
    canvas.drawCircle(c, axle, Paint()..color = Colors.white);
    canvas.drawCircle(c, axle, Paint()
      ..color = Colors.black.withOpacity(0.32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = R * 0.022);
  }

  Color _lighten(Color base, double amt) {
    final hsl = HSLColor.fromColor(base);
    return hsl.withLightness((hsl.lightness + amt).clamp(0.0, 1.0)).toColor();
  }
  Color _darken(Color base, double amt) {
    final hsl = HSLColor.fromColor(base);
    return hsl.withLightness((hsl.lightness - amt).clamp(0.0, 1.0)).toColor();
  }

  @override
  bool shouldRepaint(covariant _RealGear old) => old.color != color || old.teeth != teeth;
}
