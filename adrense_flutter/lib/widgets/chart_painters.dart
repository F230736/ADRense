part of '../main.dart';

/// Arc progress indicator following the Figma Make donut-ring design.
class ScoreRingPainter extends CustomPainter {
  ScoreRingPainter(this.progress, this.color);
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 7;
    final base = Paint()
      ..color = P.surface3
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;
    final active = Paint()
      ..color = color
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, base);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, 2 * math.pi * progress.clamp(0, 1), false, active);
  }

  @override
  bool shouldRepaint(covariant ScoreRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

/// Smooth area-line chart styled after the prototype's miniature trend charts.
class TrendPainter extends CustomPainter {
  TrendPainter(this.values);
  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final range = maxValue - minValue == 0 ? 1.0 : maxValue - minValue;
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = i * size.width / (values.length - 1);
      final y = size.height - 10 - (values[i] - minValue) / range * (size.height - 22);
      if (i == 0) { path.moveTo(x, y); } else { path.lineTo(x, y); }
    }
    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fill, Paint()
      ..shader = LinearGradient(begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [P.teal.withValues(alpha: 0.28), P.teal.withValues(alpha: 0)])
        .createShader(Offset.zero & size));
    canvas.drawPath(path, Paint()
      ..color = P.teal
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant TrendPainter oldDelegate) => oldDelegate.values != values;
}


class ColoredTrendPainter extends CustomPainter {
  ColoredTrendPainter(this.values,this.color);
  final List<double> values;
  final Color color;
  @override
  void paint(Canvas canvas,Size size) {
    if(values.length<2)return;
    final minValue=values.reduce(math.min),maxValue=values.reduce(math.max);
    final range=maxValue-minValue==0?1.0:maxValue-minValue;
    final path=Path();
    for(var i=0;i<values.length;i++){
      final x=i*size.width/(values.length-1);
      final y=size.height-12-(values[i]-minValue)/range*(size.height-24);
      if(i==0){path.moveTo(x,y);}else{path.lineTo(x,y);}
    }
    final fill=Path.from(path)..lineTo(size.width,size.height)..lineTo(0,size.height)..close();
    canvas.drawPath(fill,Paint()..shader=LinearGradient(
      begin: Alignment.topCenter,end: Alignment.bottomCenter,
      colors:[color.withValues(alpha:.24),color.withValues(alpha:0)])
      .createShader(Offset.zero&size));
    canvas.drawPath(path,Paint()..color=color..strokeWidth=2.5..style=PaintingStyle.stroke);
  }
  @override bool shouldRepaint(covariant ColoredTrendPainter old)=>old.values!=values||old.color!=color;
}