import 'dart:math';
import 'package:flutter/material.dart';
import 'theme.dart';

/// Smooth realistic gear with rounded teeth, two stacked gears that rotate
/// in opposite directions.
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
  late final _a = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
  late final _b = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  @override
  void dispose() { _a.dispose(); _b.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final primary = widget.primary ?? AppColors.orange;
    final secondary = widget.secondary ?? AppColors.mint;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(width: widget.size, height: widget.size, child: Stack(alignment: Alignment.center, children: [
        AnimatedBuilder(animation: _a, builder: (_, __) =>
          Transform.rotate(angle: _a.value * 2 * pi, child: CustomPaint(size: Size.square(widget.size), painter: _SmoothGear(primary)))),
        Positioned(right: widget.size * 0.02, bottom: widget.size * 0.02,
          child: AnimatedBuilder(animation: _b, builder: (_, __) =>
            Transform.rotate(angle: -_b.value * 2 * pi, child: CustomPaint(size: Size.square(widget.size * 0.55), painter: _SmoothGear(secondary))))),
      ])),
      if (widget.showText) ...[
        const SizedBox(height: 14),
        Text('Yichalal', style: TextStyle(fontSize: widget.size * 0.32, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: AppColors.text)),
        Text('ENGINEERING', style: TextStyle(fontSize: widget.size * 0.12, letterSpacing: widget.size * 0.05, fontWeight: FontWeight.w600, color: primary)),
      ],
    ]);
  }
}

/// A real-looking gear: rounded teeth via cubic curves, polished hub.
class _SmoothGear extends CustomPainter {
  final Color color;
  _SmoothGear(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final R = size.width * 0.5;
    final r = R * 0.78;          // inner ring
    final hub = R * 0.36;
    final hole = R * 0.16;
    const teeth = 10;

    // Rounded teeth using sweeping arcs alternating between outer and inner radii.
    final path = Path();
    final stepFrac = 1.0 / teeth;
    final tipHalf = stepFrac * 0.22 * 2 * pi;      // narrow tip
    final valleyHalf = stepFrac * 0.28 * 2 * pi;   // wider valley → softer look
    for (int i = 0; i < teeth; i++) {
      final centerAng = (i / teeth) * 2 * pi - pi / 2;
      // valley start
      final vsAng = centerAng - (stepFrac * 0.5) * 2 * pi + valleyHalf;
      // tip
      final tsAng = centerAng - tipHalf;
      final teAng = centerAng + tipHalf;
      // valley end
      final veAng = centerAng + (stepFrac * 0.5) * 2 * pi - valleyHalf;

      final vs = Offset(c.dx + r * cos(vsAng), c.dy + r * sin(vsAng));
      final ts = Offset(c.dx + R * cos(tsAng), c.dy + R * sin(tsAng));
      final te = Offset(c.dx + R * cos(teAng), c.dy + R * sin(teAng));
      final ve = Offset(c.dx + r * cos(veAng), c.dy + r * sin(veAng));

      if (i == 0) path.moveTo(vs.dx, vs.dy);
      else path.lineTo(vs.dx, vs.dy);

      // ramp up to tooth tip (smooth)
      path.quadraticBezierTo(
        c.dx + ((R + r) / 2) * cos((vsAng + tsAng) / 2),
        c.dy + ((R + r) / 2) * sin((vsAng + tsAng) / 2),
        ts.dx, ts.dy);

      // outer arc across the tooth top
      path.arcToPoint(te, radius: Radius.circular(R), clockwise: true);

      // ramp down from tooth tip
      path.quadraticBezierTo(
        c.dx + ((R + r) / 2) * cos((teAng + veAng) / 2),
        c.dy + ((R + r) / 2) * sin((teAng + veAng) / 2),
        ve.dx, ve.dy);

      // arc along the valley to next tooth start
      final nextVsAng = ((i + 1) / teeth) * 2 * pi - pi / 2 - (stepFrac * 0.5) * 2 * pi + valleyHalf;
      final nextVs = Offset(c.dx + r * cos(nextVsAng), c.dy + r * sin(nextVsAng));
      path.arcToPoint(nextVs, radius: Radius.circular(r), clockwise: true);
    }
    path.close();

    // Base + subtle highlight for depth.
    canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.fill);

    // Polished hub
    canvas.drawCircle(c, hub, Paint()..color = Colors.white.withOpacity(0.18));
    canvas.drawCircle(c, hub * 0.85, Paint()..color = color.withOpacity(0.85));
    canvas.drawCircle(c, hole, Paint()..color = Colors.white);

    // Spokes (3 elegant arcs) so it reads as a gear, not a sun
    final spoke = Paint()..color = Colors.white.withOpacity(0.55)..style = PaintingStyle.stroke..strokeWidth = R * 0.06..strokeCap = StrokeCap.round;
    for (int i = 0; i < 3; i++) {
      final a = i * 2 * pi / 3;
      canvas.drawLine(
        Offset(c.dx + hole * 1.2 * cos(a), c.dy + hole * 1.2 * sin(a)),
        Offset(c.dx + hub * 0.78 * cos(a), c.dy + hub * 0.78 * sin(a)),
        spoke);
    }
  }
  @override
  bool shouldRepaint(covariant _SmoothGear old) => old.color != color;
}
