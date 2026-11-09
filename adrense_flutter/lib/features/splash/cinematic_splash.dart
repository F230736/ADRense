import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/widgets/premium_widgets.dart';

class CinematicSplash extends StatefulWidget {
  final VoidCallback onGetStarted;
  final VoidCallback onSignIn;
  const CinematicSplash({super.key, required this.onGetStarted, required this.onSignIn});
  @override
  State<CinematicSplash> createState() => _CinematicSplashState();
}

class _CinematicSplashState extends State<CinematicSplash> with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: const Duration(seconds: 14));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !MediaQuery.disableAnimationsOf(context)) controller.repeat();
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Widget _orb(Color color, double size) => IgnorePointer(
    child: ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
      child: Container(width: size, height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: .19))),
    ),
  );

  Widget _stat(int number, String label, {String suffix = '', bool light = false}) => Container(
    padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
    decoration: BoxDecoration(
      color: light ? Colors.white.withValues(alpha: .82) : Colors.white.withValues(alpha: .08),
      border: Border.all(color: light ? const Color(0xFFB4D7DC) : Colors.white.withValues(alpha: .16)),
      borderRadius: BorderRadius.circular(17),
    ),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      AnimatedCounter(value: number, suffix: suffix,
        style: TextStyle(fontSize: 20, color: light ? const Color(0xFF006D68) : const Color(0xFF55F0DF), fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 10, color: light ? const Color(0xFF476178) : const Color(0xFFB6D0DF))),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    final light = Theme.of(context).brightness == Brightness.light;
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxHeight < 690;
      return Stack(children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, child) => DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-1 + controller.value * .4, -1),
                  end: Alignment(1 - controller.value * .3, 1),
                  colors: light ? const [Color(0xFFF4FCFF), Color(0xFFD6F3EE), Color(0xFFE6EEFF)] : const [Color(0xFF071421), Color(0xFF092F3D), Color(0xFF071220)],
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(child: RepaintBoundary(
          child: AnimatedBuilder(animation: controller,
            builder: (context, child) => CustomPaint(painter: MoleculePainter(controller.value, light: light))),
        )),
        Positioned(top: constraints.maxHeight * .10, left: -45,
          child: _orb(light ? const Color(0xFF46C7B9) : const Color(0xFF00C9B8), 170)),
        Positioned(bottom: constraints.maxHeight * .14, right: -55,
          child: _orb(light ? const Color(0xFF98B8EE) : const Color(0xFF3879E9), 180)),
        SafeArea(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(children: [
            Spacer(flex: compact ? 1 : 2),
            Hero(tag: 'adrense-logo', child: Container(
              width: compact ? 106 : 130,
              height: compact ? 106 : 130,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(34),
                gradient: const LinearGradient(colors: [Color(0xFF116B75), Color(0xFF173C52)]),
                border: Border.all(color: const Color(0xFF28E5D3).withValues(alpha: .7)),
                boxShadow: [BoxShadow(color: const Color(0xFF00E0CF).withValues(alpha: .25),
                  blurRadius: 46, spreadRadius: 6)],
              ),
              child: Stack(alignment: Alignment.center, children: [
                AnimatedBuilder(animation: controller,
                  builder: (context, child) => CustomPaint(
                    size: const Size(100, 100), painter: OrbitPainter(controller.value))),
                SvgPicture.asset('assets/logo.svg', width: 75, height: 75),
              ]),
            )).animate().scale(begin: const Offset(.65, .65),
              duration: 900.ms, curve: Curves.elasticOut).fadeIn(duration: 650.ms),
            const SizedBox(height: 24),
            Text('AI-POWERED · PHARMACOVIGILANCE', textAlign: TextAlign.center,
              style: TextStyle(color: light ? const Color(0xFF006F72) : const Color(0xFF5CE5D9), letterSpacing: 1.8,
                fontSize: 10, fontWeight: FontWeight.w700))
              .animate().fadeIn(delay: 350.ms, duration: 700.ms),
            const SizedBox(height: 12),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: light ? const [Color(0xFF133B55), Color(0xFF007F7A), Color(0xFF133B55)] : const [Colors.white, Color(0xFF8DF7ED), Colors.white]).createShader(bounds),
              child: const Text('ADRense', style: TextStyle(fontSize: 44,
                fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1.5)),
            ).animate().fadeIn(delay: 450.ms, duration: 850.ms).slideY(begin: .2, end: 0),
            const SizedBox(height: 12),
            Text('Smarter insights. Safer medicines.',
              style: TextStyle(color: light ? const Color(0xFF3D6075) : const Color(0xFFB7D1E0), fontSize: 14))
              .animate().fadeIn(delay: 650.ms),
            Spacer(flex: compact ? 1 : 2),
            GradientButton(label: 'Get Started', onPressed: widget.onGetStarted,
              icon: Icons.arrow_forward_rounded)
              .animate().fadeIn(delay: 750.ms).slideY(begin: .3, end: 0),
            const SizedBox(height: 12),
            SizedBox(height: 54, width: double.infinity,
              child: OutlinedButton(
                onPressed: widget.onSignIn,
                style: OutlinedButton.styleFrom(
                  foregroundColor: light ? const Color(0xFF075F65) : Colors.white,
                  side: BorderSide(color: light ? const Color(0xFF83C6C7) : const Color(0xFF557486)),
                  backgroundColor: light ? Colors.white.withValues(alpha:.75) : const Color(0x330C2A3B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ).animate().fadeIn(delay: 900.ms),
            const Spacer(),
            Row(children: [
              Expanded(child: _stat(1247, 'ADR Reports', light: light)),
              const SizedBox(width: 8),
              Expanded(child: _stat(847, 'Drugs', light: light)),
              const SizedBox(width: 8),
              Expanded(child: _stat(94, 'Accuracy', suffix: '%', light: light)),
            ]).animate().fadeIn(delay: 1100.ms),
            SizedBox(height: compact ? 12 : 30),
          ]),
        )),
      ]);
    });
  }
}

class MoleculePainter extends CustomPainter {
  final double progress;
  MoleculePainter(this.progress, {this.light = false});
  final bool light;
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(19);
    final points = <Offset>[];
    for (var i = 0; i < 28; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      points.add(Offset(x + math.sin(progress * 2 * math.pi + i) * 8,
        y + math.cos(progress * 2 * math.pi + i * .6) * 9));
    }
    final line = Paint()..strokeWidth = .65;
    for (var i = 0; i < points.length; i++) {
      for (var j = i + 1; j < points.length; j++) {
        final distance = (points[i] - points[j]).distance;
        if (distance < 105) {
          line.color = (light ? const Color(0xFF007E80) : const Color(0xFF65F1E5)).withValues(alpha: (1 - distance / 105) * (light ? .13 : .16));
          canvas.drawLine(points[i], points[j], line);
        }
      }
      canvas.drawCircle(points[i], 1.3,
        Paint()..color = const Color(0xFF75F8EE).withValues(alpha: .25));
    }
  }
  @override
  bool shouldRepaint(covariant MoleculePainter old) => old.progress != progress || old.light != light;
}

class OrbitPainter extends CustomPainter {
  final double progress;
  OrbitPainter(this.progress);
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(center: Offset(size.width / 2, size.height / 2),
      width: size.width * .82, height: size.height * .38);
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-.5);
    canvas.translate(-size.width / 2, -size.height / 2);
    final path = Path()..addOval(rect);
    final metric = path.computeMetrics().first;
    final fraction = (.25 + .75 * math.min(1, progress * 3)).clamp(0.0, 1.0);
    canvas.drawPath(metric.extractPath(0, metric.length * fraction),
      Paint()..color = const Color(0xFF4BF3E4).withValues(alpha: .7)
        ..style = PaintingStyle.stroke..strokeWidth = 1.4);
    canvas.restore();
  }
  @override
  bool shouldRepaint(covariant OrbitPainter old) => old.progress != progress;
}
