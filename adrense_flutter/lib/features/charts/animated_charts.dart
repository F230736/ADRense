import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/adrense_theme.dart';

class AdrenseBarChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final List<Color>? colors;
  const AdrenseBarChart({super.key, required this.values, required this.labels, this.colors});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    if (values.isEmpty) return const SizedBox(height: 125);
    final maxValue = values.reduce(math.max);
    return SizedBox(
      height: 145,
      child: BarChart(
        BarChartData(
          maxY: math.max(1, maxValue * 1.25),
          alignment: BarChartAlignment.spaceAround,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(getTooltipColor: (_) => t.surfaceRaised),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(index >= 0 && index < labels.length ? labels[index] : '',
                      style: TextStyle(fontSize: 9, color: t.muted)),
                  );
                },
              ),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: [
            for (var i = 0; i < values.length; i++)
              BarChartGroupData(x: i, barRods: [
                BarChartRodData(
                  toY: values[i],
                  width: 17,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      (colors != null && i < colors!.length ? colors![i] : t.cyan),
                      (colors != null && i < colors!.length ? colors![i] : t.teal).withValues(alpha: .72),
                    ],
                  ),
                ),
              ]),
          ],
        ),
        duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
      ),
    );
  }
}

class AdrenseLineChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final Color? color;
  const AdrenseLineChart({super.key, required this.values, required this.labels, this.color});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final c = color ?? t.teal;
    if (values.isEmpty) return const SizedBox(height: 130);
    return SizedBox(
      height: 150,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: math.max(1, values.length - 1).toDouble(),
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(getTooltipColor: (_) => t.surfaceRaised),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(index >= 0 && index < labels.length ? labels[index] : '',
                      style: TextStyle(fontSize: 9, color: t.muted)),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: t.border.withValues(alpha: .4),
              strokeWidth: .7,
              dashArray: [4, 5],
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: [for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i])],
              isCurved: true,
              barWidth: 3,
              isStrokeCapRound: true,
              gradient: LinearGradient(colors: [c, t.cyan]),
              dotData: FlDotData(show: true,
                getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                  radius: 3, color: c, strokeWidth: 1.5, strokeColor: t.surface,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [c.withValues(alpha: .24), c.withValues(alpha: 0)],
                ),
              ),
            ),
          ],
        ),
        duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 1000),
        curve: Curves.easeOutCubic,
      ),
    );
  }
}

class AnimatedSafetyGauge extends StatelessWidget {
  final int score;
  final double size;
  const AnimatedSafetyGauge({super.key, required this.score, this.size = 86});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final c = score >= 80 ? t.success : score >= 60 ? t.warning : t.danger;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: score.clamp(0, 100) / 100),
      duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => SizedBox(
        width: size,
        height: size,
        child: Stack(alignment: Alignment.center, children: [
          SizedBox(width:size,height:size,child:CircularProgressIndicator(value: 1, strokeWidth: 7, color: t.border)),
          SizedBox(width:size,height:size,child:CircularProgressIndicator(value: value, strokeWidth: 7,
            strokeCap: StrokeCap.round, color: c)),
          Column(mainAxisSize: MainAxisSize.min, children: [
            Text('${(value * 100).round()}', style: TextStyle(
              fontSize: size * .22, fontWeight: FontWeight.w800, color: t.ink)),
            Text('Score', style: TextStyle(fontSize: 9, color: t.muted)),
          ]),
        ]),
      ),
    );
  }
}
