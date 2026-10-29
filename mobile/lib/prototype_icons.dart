// Trazos de Lucide (ISC/MIT). Ver THIRD_PARTY_NOTICES/Lucide.txt.
import 'package:flutter/material.dart';

class LineIcon extends StatelessWidget {
  final String name;
  final double size, stroke;
  final Color color;
  const LineIcon(
    this.name, {
    super.key,
    this.size = 20,
    this.color = const Color(0xff171714),
    this.stroke = 2,
  });
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _IconPainter(name, color, stroke)),
    ),
  );
}

class _IconPainter extends CustomPainter {
  final String name;
  final Color color;
  final double stroke;
  _IconPainter(this.name, this.color, this.stroke);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    switch (name) {
      case 'arrow-left':
        {
          final p = Path();
          p.moveTo(12.0, 19.0);
          p.lineTo(5.0, 12.0);
          p.lineTo(12.0, 5.0);
          canvas.drawPath(p, paint);
        }
        {
          final p = Path();
          p.moveTo(19.0, 12.0);
          p.lineTo(5.0, 12.0);
          canvas.drawPath(p, paint);
        }
        break;
      case 'arrow-right':
        {
          final p = Path();
          p.moveTo(5.0, 12.0);
          p.lineTo(19.0, 12.0);
          canvas.drawPath(p, paint);
        }
        {
          final p = Path();
          p.moveTo(12.0, 5.0);
          p.lineTo(19.0, 12.0);
          p.lineTo(12.0, 19.0);
          canvas.drawPath(p, paint);
        }
        break;
      case 'badge-check':
        {
          final p = Path();
          p.moveTo(3.85, 8.62);
          p.arcToPoint(
            Offset(8.63, 3.8499999999999996),
            radius: Radius.elliptical(4.0, 4.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: true,
          );
          p.arcToPoint(
            Offset(15.370000000000001, 3.8499999999999996),
            radius: Radius.elliptical(4.0, 4.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: true,
          );
          p.arcToPoint(
            Offset(20.150000000000002, 8.629999999999999),
            radius: Radius.elliptical(4.0, 4.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: true,
          );
          p.arcToPoint(
            Offset(20.150000000000002, 15.37),
            radius: Radius.elliptical(4.0, 4.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: true,
          );
          p.arcToPoint(
            Offset(15.380000000000003, 20.15),
            radius: Radius.elliptical(4.0, 4.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: true,
          );
          p.arcToPoint(
            Offset(8.630000000000003, 20.15),
            radius: Radius.elliptical(4.0, 4.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: true,
          );
          p.arcToPoint(
            Offset(3.8500000000000023, 15.379999999999999),
            radius: Radius.elliptical(4.0, 4.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: true,
          );
          p.arcToPoint(
            Offset(3.8500000000000023, 8.62),
            radius: Radius.elliptical(4.0, 4.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: true,
          );
          p.close();
          canvas.drawPath(p, paint);
        }
        {
          final p = Path();
          p.moveTo(16.0, 9.0);
          p.lineTo(10.5, 14.5);
          p.lineTo(8.0, 12.0);
          canvas.drawPath(p, paint);
        }
        break;
      case 'building-2':
        {
          final p = Path();
          p.moveTo(6.0, 22.0);
          p.lineTo(6.0, 4.0);
          p.arcToPoint(
            Offset(8.0, 2.0),
            radius: Radius.elliptical(2.0, 2.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: true,
          );
          p.lineTo(16.0, 2.0);
          p.arcToPoint(
            Offset(18.0, 4.0),
            radius: Radius.elliptical(2.0, 2.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: true,
          );
          p.lineTo(18.0, 22.0);
          p.close();
          canvas.drawPath(p, paint);
        }
        {
          final p = Path();
          p.moveTo(6.0, 12.0);
          p.lineTo(4.0, 12.0);
          p.arcToPoint(
            Offset(2.0, 14.0),
            radius: Radius.elliptical(2.0, 2.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: false,
          );
          p.lineTo(2.0, 20.0);
          p.arcToPoint(
            Offset(4.0, 22.0),
            radius: Radius.elliptical(2.0, 2.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: false,
          );
          p.lineTo(6.0, 22.0);
          canvas.drawPath(p, paint);
        }
        {
          final p = Path();
          p.moveTo(18.0, 9.0);
          p.lineTo(20.0, 9.0);
          p.arcToPoint(
            Offset(22.0, 11.0),
            radius: Radius.elliptical(2.0, 2.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: true,
          );
          p.lineTo(22.0, 20.0);
          p.arcToPoint(
            Offset(20.0, 22.0),
            radius: Radius.elliptical(2.0, 2.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: true,
          );
          p.lineTo(18.0, 22.0);
          canvas.drawPath(p, paint);
        }
        {
          final p = Path();
          p.moveTo(10.0, 6.0);
          p.lineTo(14.0, 6.0);
          canvas.drawPath(p, paint);
        }
        {
          final p = Path();
          p.moveTo(10.0, 10.0);
          p.lineTo(14.0, 10.0);
          canvas.drawPath(p, paint);
        }
        {
          final p = Path();
          p.moveTo(10.0, 14.0);
          p.lineTo(14.0, 14.0);
          canvas.drawPath(p, paint);
        }
        {
          final p = Path();
          p.moveTo(10.0, 18.0);
          p.lineTo(14.0, 18.0);
          canvas.drawPath(p, paint);
        }
        break;
      case 'calendar-days':
        {
          final p = Path();
          p.moveTo(8.0, 2.0);
          p.lineTo(8.0, 5.0);
          canvas.drawPath(p, paint);
        }
        {
          final p = Path();
          p.moveTo(16.0, 2.0);
          p.lineTo(16.0, 5.0);
          canvas.drawPath(p, paint);
        }
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(3, 3, 18, 18),
            Radius.circular(2),
          ),
          paint,
        );
        {
          final p = Path();
          p.moveTo(3.0, 9.0);
          p.lineTo(21.0, 9.0);
          canvas.drawPath(p, paint);
        }
        {
          final p = Path();
          p.moveTo(8.0, 13.0);
          p.lineTo(8.01, 13.0);
          canvas.drawPath(p, paint);
        }
        {
          final p = Path();
          p.moveTo(12.0, 13.0);
          p.lineTo(12.01, 13.0);
          canvas.drawPath(p, paint);
        }
        {
          final p = Path();
          p.moveTo(16.0, 13.0);
          p.lineTo(16.01, 13.0);
          canvas.drawPath(p, paint);
        }
        {
          final p = Path();
          p.moveTo(8.0, 17.0);
          p.lineTo(8.01, 17.0);
          canvas.drawPath(p, paint);
        }
        {
          final p = Path();
          p.moveTo(12.0, 17.0);
          p.lineTo(12.01, 17.0);
          canvas.drawPath(p, paint);
        }
        {
          final p = Path();
          p.moveTo(16.0, 17.0);
          p.lineTo(16.01, 17.0);
          canvas.drawPath(p, paint);
        }
        break;
      case 'camera':
        {
          final p = Path();
          p.moveTo(13.997, 4.0);
          p.arcToPoint(
            Offset(15.757, 5.05),
            radius: Radius.elliptical(2.0, 2.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: true,
          );
          p.lineTo(16.243, 5.95);
          p.arcToPoint(
            Offset(18.003, 7.0),
            radius: Radius.elliptical(2.0, 2.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: false,
          );
          p.lineTo(20.0, 7.0);
          p.arcToPoint(
            Offset(22.0, 9.0),
            radius: Radius.elliptical(2.0, 2.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: true,
          );
          p.lineTo(22.0, 18.0);
          p.arcToPoint(
            Offset(20.0, 20.0),
            radius: Radius.elliptical(2.0, 2.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: true,
          );
          p.lineTo(4.0, 20.0);
          p.arcToPoint(
            Offset(2.0, 18.0),
            radius: Radius.elliptical(2.0, 2.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: true,
          );
          p.lineTo(2.0, 9.0);
          p.arcToPoint(
            Offset(4.0, 7.0),
            radius: Radius.elliptical(2.0, 2.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: true,
          );
          p.lineTo(5.997, 7.0);
          p.arcToPoint(
            Offset(7.756, 5.952),
            radius: Radius.elliptical(2.0, 2.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: false,
          );
          p.lineTo(8.245000000000001, 5.048);
          p.arcToPoint(
            Offset(10.004, 4.0),
            radius: Radius.elliptical(2.0, 2.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: true,
          );
          p.close();
          canvas.drawPath(p, paint);
        }
        canvas.drawCircle(Offset(12, 13), 3, paint);
        break;
      case 'check':
        {
          final p = Path();
          p.moveTo(20.0, 6.0);
          p.lineTo(9.0, 17.0);
          p.lineTo(4.0, 12.0);
          canvas.drawPath(p, paint);
        }
        break;
      case 'chevron-down':
        {
          final p = Path();
          p.moveTo(6.0, 9.0);
          p.lineTo(12.0, 15.0);
          p.lineTo(18.0, 9.0);
          canvas.drawPath(p, paint);
        }
        break;
      case 'chevron-right':
        {
          final p = Path();
          p.moveTo(9.0, 18.0);
          p.lineTo(15.0, 12.0);
          p.lineTo(9.0, 6.0);
          canvas.drawPath(p, paint);
        }
        break;
      case 'clock-3':
        canvas.drawCircle(Offset(12, 12), 10, paint);
        {
          final p = Path();
          p.moveTo(12.0, 6.0);
          p.lineTo(12.0, 12.0);
          p.lineTo(16.0, 12.0);
          canvas.drawPath(p, paint);
        }
        break;
      case 'file-text':
        {
          final p = Path();
          p.moveTo(6.0, 22.0);
          p.arcToPoint(
            Offset(4.0, 20.0),
            radius: Radius.elliptical(2.0, 2.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: true,
          );
          p.lineTo(4.0, 4.0);
          p.arcToPoint(
            Offset(6.0, 2.0),
            radius: Radius.elliptical(2.0, 2.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: true,
          );
          p.lineTo(14.0, 2.0);
          p.arcToPoint(
            Offset(15.704, 2.706),
            radius: Radius.elliptical(2.4, 2.4),
            rotation: 0.0,
            largeArc: false,
            clockwise: true,
          );
          p.lineTo(19.292, 6.2940000000000005);
          p.arcToPoint(
            Offset(20.0, 8.0),
            radius: Radius.elliptical(2.4, 2.4),
            rotation: 0.0,
            largeArc: false,
            clockwise: true,
          );
          p.lineTo(20.0, 20.0);
          p.arcToPoint(
            Offset(18.0, 22.0),
            radius: Radius.elliptical(2.0, 2.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: true,
          );
          p.close();
          canvas.drawPath(p, paint);
        }
        {
          final p = Path();
          p.moveTo(14.0, 2.0);
          p.lineTo(14.0, 7.0);
          p.arcToPoint(
            Offset(15.0, 8.0),
            radius: Radius.elliptical(1.0, 1.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: false,
          );
          p.lineTo(20.0, 8.0);
          canvas.drawPath(p, paint);
        }
        {
          final p = Path();
          p.moveTo(10.0, 9.0);
          p.lineTo(8.0, 9.0);
          canvas.drawPath(p, paint);
        }
        {
          final p = Path();
          p.moveTo(16.0, 13.0);
          p.lineTo(8.0, 13.0);
          canvas.drawPath(p, paint);
        }
        {
          final p = Path();
          p.moveTo(16.0, 17.0);
          p.lineTo(8.0, 17.0);
          canvas.drawPath(p, paint);
        }
        break;
      case 'house':
        {
          final p = Path();
          p.moveTo(15.0, 21.0);
          p.lineTo(15.0, 13.0);
          p.arcToPoint(
            Offset(14.0, 12.0),
            radius: Radius.elliptical(1.0, 1.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: false,
          );
          p.lineTo(10.0, 12.0);
          p.arcToPoint(
            Offset(9.0, 13.0),
            radius: Radius.elliptical(1.0, 1.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: false,
          );
          p.lineTo(9.0, 21.0);
          canvas.drawPath(p, paint);
        }
        {
          final p = Path();
          p.moveTo(3.0, 10.0);
          p.arcToPoint(
            Offset(3.709, 8.472),
            radius: Radius.elliptical(2.0, 2.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: true,
          );
          p.lineTo(10.709, 2.4719999999999995);
          p.arcToPoint(
            Offset(13.291, 2.4719999999999995),
            radius: Radius.elliptical(2.0, 2.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: true,
          );
          p.lineTo(20.291, 8.472);
          p.arcToPoint(
            Offset(21.0, 10.0),
            radius: Radius.elliptical(2.0, 2.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: true,
          );
          p.lineTo(21.0, 19.0);
          p.arcToPoint(
            Offset(19.0, 21.0),
            radius: Radius.elliptical(2.0, 2.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: true,
          );
          p.lineTo(5.0, 21.0);
          p.arcToPoint(
            Offset(3.0, 19.0),
            radius: Radius.elliptical(2.0, 2.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: true,
          );
          p.close();
          canvas.drawPath(p, paint);
        }
        break;
      case 'info':
        canvas.drawCircle(Offset(12, 12), 10, paint);
        {
          final p = Path();
          p.moveTo(12.0, 16.0);
          p.lineTo(12.0, 12.0);
          canvas.drawPath(p, paint);
        }
        {
          final p = Path();
          p.moveTo(12.0, 8.0);
          p.lineTo(12.01, 8.0);
          canvas.drawPath(p, paint);
        }
        break;
      case 'key-round':
        {
          final p = Path();
          p.moveTo(2.586, 17.414);
          p.arcToPoint(
            Offset(2.0, 18.828),
            radius: Radius.elliptical(2.0, 2.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: false,
          );
          p.lineTo(2.0, 21.0);
          p.arcToPoint(
            Offset(3.0, 22.0),
            radius: Radius.elliptical(1.0, 1.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: false,
          );
          p.lineTo(6.0, 22.0);
          p.arcToPoint(
            Offset(7.0, 21.0),
            radius: Radius.elliptical(1.0, 1.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: false,
          );
          p.lineTo(7.0, 20.0);
          p.arcToPoint(
            Offset(8.0, 19.0),
            radius: Radius.elliptical(1.0, 1.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: true,
          );
          p.lineTo(9.0, 19.0);
          p.arcToPoint(
            Offset(10.0, 18.0),
            radius: Radius.elliptical(1.0, 1.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: false,
          );
          p.lineTo(10.0, 17.0);
          p.arcToPoint(
            Offset(11.0, 16.0),
            radius: Radius.elliptical(1.0, 1.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: true,
          );
          p.lineTo(11.172, 16.0);
          p.arcToPoint(
            Offset(12.586, 15.414),
            radius: Radius.elliptical(2.0, 2.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: false,
          );
          p.lineTo(13.4, 14.6);
          p.arcToPoint(
            Offset(9.4, 10.6),
            radius: Radius.elliptical(6.5, 6.5),
            rotation: 0.0,
            largeArc: true,
            clockwise: false,
          );
          p.close();
          canvas.drawPath(p, paint);
        }
        canvas.drawCircle(Offset(16.5, 7.5), .5, paint);
        break;
      case 'layout-grid':
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(3, 3, 7, 7),
            Radius.circular(1),
          ),
          paint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(14, 3, 7, 7),
            Radius.circular(1),
          ),
          paint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(14, 14, 7, 7),
            Radius.circular(1),
          ),
          paint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(3, 14, 7, 7),
            Radius.circular(1),
          ),
          paint,
        );
        break;
      case 'list-filter':
        {
          final p = Path();
          p.moveTo(2.0, 5.0);
          p.lineTo(22.0, 5.0);
          canvas.drawPath(p, paint);
        }
        {
          final p = Path();
          p.moveTo(6.0, 12.0);
          p.lineTo(18.0, 12.0);
          canvas.drawPath(p, paint);
        }
        {
          final p = Path();
          p.moveTo(9.0, 19.0);
          p.lineTo(15.0, 19.0);
          canvas.drawPath(p, paint);
        }
        break;
      case 'lock-keyhole':
        canvas.drawCircle(Offset(12, 16), 1, paint);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(3, 10, 18, 12),
            Radius.circular(2),
          ),
          paint,
        );
        {
          final p = Path();
          p.moveTo(7.0, 10.0);
          p.lineTo(7.0, 7.0);
          p.arcToPoint(
            Offset(17.0, 7.0),
            radius: Radius.elliptical(5.0, 5.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: true,
          );
          p.lineTo(17.0, 10.0);
          canvas.drawPath(p, paint);
        }
        break;
      case 'log-out':
        {
          final p = Path();
          p.moveTo(16.0, 17.0);
          p.lineTo(21.0, 12.0);
          p.lineTo(16.0, 7.0);
          canvas.drawPath(p, paint);
        }
        {
          final p = Path();
          p.moveTo(21.0, 12.0);
          p.lineTo(9.0, 12.0);
          canvas.drawPath(p, paint);
        }
        {
          final p = Path();
          p.moveTo(9.0, 21.0);
          p.lineTo(5.0, 21.0);
          p.arcToPoint(
            Offset(3.0, 19.0),
            radius: Radius.elliptical(2.0, 2.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: true,
          );
          p.lineTo(3.0, 5.0);
          p.arcToPoint(
            Offset(5.0, 3.0),
            radius: Radius.elliptical(2.0, 2.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: true,
          );
          p.lineTo(9.0, 3.0);
          canvas.drawPath(p, paint);
        }
        break;
      case 'map-pin':
        {
          final p = Path();
          p.moveTo(20.0, 10.0);
          p.cubicTo(
            20.0,
            14.993,
            14.461,
            20.192999999999998,
            12.600999999999999,
            21.799,
          );
          p.arcToPoint(
            Offset(11.399, 21.799),
            radius: Radius.elliptical(1.0, 1.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: true,
          );
          p.cubicTo(9.539, 20.193, 4.0, 14.993, 4.0, 10.0);
          p.arcToPoint(
            Offset(20.0, 10.0),
            radius: Radius.elliptical(8.0, 8.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: true,
          );
          canvas.drawPath(p, paint);
        }
        canvas.drawCircle(Offset(12, 10), 3, paint);
        break;
      case 'message-circle-more':
        {
          final p = Path();
          p.moveTo(2.992, 16.342);
          p.arcToPoint(
            Offset(3.086, 17.509),
            radius: Radius.elliptical(2.0, 2.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: true,
          );
          p.lineTo(2.021, 20.799);
          p.arcToPoint(
            Offset(3.2569999999999997, 21.967),
            radius: Radius.elliptical(1.0, 1.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: false,
          );
          p.lineTo(6.67, 20.968999999999998);
          p.arcToPoint(
            Offset(7.769, 21.060999999999996),
            radius: Radius.elliptical(2.0, 2.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: true,
          );
          p.arcToPoint(
            Offset(2.992, 16.341999999999995),
            radius: Radius.elliptical(10.0, 10.0),
            rotation: 0.0,
            largeArc: true,
            clockwise: false,
          );
          canvas.drawPath(p, paint);
        }
        {
          final p = Path();
          p.moveTo(8.0, 12.0);
          p.lineTo(8.01, 12.0);
          canvas.drawPath(p, paint);
        }
        {
          final p = Path();
          p.moveTo(12.0, 12.0);
          p.lineTo(12.01, 12.0);
          canvas.drawPath(p, paint);
        }
        {
          final p = Path();
          p.moveTo(16.0, 12.0);
          p.lineTo(16.01, 12.0);
          canvas.drawPath(p, paint);
        }
        break;
      case 'phone':
        {
          final p = Path();
          p.moveTo(13.832, 16.568);
          p.arcToPoint(
            Offset(15.045000000000002, 16.265),
            radius: Radius.elliptical(1.0, 1.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: false,
          );
          p.lineTo(15.400000000000002, 15.8);
          p.arcToPoint(
            Offset(17.0, 15.0),
            radius: Radius.elliptical(2.0, 2.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: true,
          );
          p.lineTo(20.0, 15.0);
          p.arcToPoint(
            Offset(22.0, 17.0),
            radius: Radius.elliptical(2.0, 2.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: true,
          );
          p.lineTo(22.0, 20.0);
          p.arcToPoint(
            Offset(20.0, 22.0),
            radius: Radius.elliptical(2.0, 2.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: true,
          );
          p.arcToPoint(
            Offset(2.0, 4.0),
            radius: Radius.elliptical(18.0, 18.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: true,
          );
          p.arcToPoint(
            Offset(4.0, 2.0),
            radius: Radius.elliptical(2.0, 2.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: true,
          );
          p.lineTo(7.0, 2.0);
          p.arcToPoint(
            Offset(9.0, 4.0),
            radius: Radius.elliptical(2.0, 2.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: true,
          );
          p.lineTo(9.0, 7.0);
          p.arcToPoint(
            Offset(8.2, 8.6),
            radius: Radius.elliptical(2.0, 2.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: true,
          );
          p.lineTo(7.731999999999999, 8.951);
          p.arcToPoint(
            Offset(7.4399999999999995, 10.184000000000001),
            radius: Radius.elliptical(1.0, 1.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: false,
          );
          p.arcToPoint(
            Offset(13.832, 16.568),
            radius: Radius.elliptical(14.0, 14.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: false,
          );
          canvas.drawPath(p, paint);
        }
        break;
      case 'plus':
        {
          final p = Path();
          p.moveTo(5.0, 12.0);
          p.lineTo(19.0, 12.0);
          canvas.drawPath(p, paint);
        }
        {
          final p = Path();
          p.moveTo(12.0, 5.0);
          p.lineTo(12.0, 19.0);
          canvas.drawPath(p, paint);
        }
        break;
      case 'search':
        {
          final p = Path();
          p.moveTo(21.0, 21.0);
          p.lineTo(16.66, 16.66);
          canvas.drawPath(p, paint);
        }
        canvas.drawCircle(Offset(11, 11), 8, paint);
        break;
      case 'share-2':
        canvas.drawCircle(Offset(18, 5), 3, paint);
        canvas.drawCircle(Offset(6, 12), 3, paint);
        canvas.drawCircle(Offset(18, 19), 3, paint);
        canvas.drawLine(Offset(8.59, 13.51), Offset(15.42, 17.49), paint);
        canvas.drawLine(Offset(15.41, 6.51), Offset(8.59, 10.49), paint);
        break;
      case 'shield-check':
        {
          final p = Path();
          p.moveTo(20.0, 13.0);
          p.cubicTo(20.0, 18.0, 16.5, 20.5, 12.34, 21.95);
          p.arcToPoint(
            Offset(11.67, 21.939999999999998),
            radius: Radius.elliptical(1.0, 1.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: true,
          );
          p.cubicTo(7.5, 20.5, 4.0, 18.0, 4.0, 13.0);
          p.lineTo(4.0, 6.0);
          p.arcToPoint(
            Offset(5.0, 5.0),
            radius: Radius.elliptical(1.0, 1.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: true,
          );
          p.cubicTo(7.0, 5.0, 9.5, 3.8, 11.24, 2.28);
          p.arcToPoint(
            Offset(12.76, 2.28),
            radius: Radius.elliptical(1.17, 1.17),
            rotation: 0.0,
            largeArc: false,
            clockwise: true,
          );
          p.cubicTo(14.51, 3.81, 17.0, 5.0, 19.0, 5.0);
          p.arcToPoint(
            Offset(20.0, 6.0),
            radius: Radius.elliptical(1.0, 1.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: true,
          );
          p.close();
          canvas.drawPath(p, paint);
        }
        {
          final p = Path();
          p.moveTo(9.0, 12.0);
          p.lineTo(11.0, 14.0);
          p.lineTo(15.0, 10.0);
          canvas.drawPath(p, paint);
        }
        break;
      case 'sparkles':
        {
          final p = Path();
          p.moveTo(11.017, 2.814);
          p.arcToPoint(
            Offset(12.982999999999999, 2.814),
            radius: Radius.elliptical(1.0, 1.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: true,
          );
          p.lineTo(14.033999999999999, 8.372);
          p.arcToPoint(
            Offset(15.627999999999998, 9.966),
            radius: Radius.elliptical(2.0, 2.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: false,
          );
          p.lineTo(21.186, 11.017);
          p.arcToPoint(
            Offset(21.186, 12.982999999999999),
            radius: Radius.elliptical(1.0, 1.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: true,
          );
          p.lineTo(15.628, 14.033999999999999);
          p.arcToPoint(
            Offset(14.034, 15.627999999999998),
            radius: Radius.elliptical(2.0, 2.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: false,
          );
          p.lineTo(12.983, 21.186);
          p.arcToPoint(
            Offset(11.017000000000001, 21.186),
            radius: Radius.elliptical(1.0, 1.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: true,
          );
          p.lineTo(9.966000000000001, 15.628);
          p.arcToPoint(
            Offset(8.372000000000002, 14.034),
            radius: Radius.elliptical(2.0, 2.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: false,
          );
          p.lineTo(2.814000000000002, 12.983);
          p.arcToPoint(
            Offset(2.814000000000002, 11.017000000000001),
            radius: Radius.elliptical(1.0, 1.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: true,
          );
          p.lineTo(8.372000000000002, 9.966000000000001);
          p.arcToPoint(
            Offset(9.966000000000001, 8.372000000000002),
            radius: Radius.elliptical(2.0, 2.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: false,
          );
          p.close();
          canvas.drawPath(p, paint);
        }
        {
          final p = Path();
          p.moveTo(20.0, 2.0);
          p.lineTo(20.0, 6.0);
          canvas.drawPath(p, paint);
        }
        {
          final p = Path();
          p.moveTo(22.0, 4.0);
          p.lineTo(18.0, 4.0);
          canvas.drawPath(p, paint);
        }
        canvas.drawCircle(Offset(4, 20), 2, paint);
        break;
      case 'user-round':
        canvas.drawCircle(Offset(12, 8), 5, paint);
        {
          final p = Path();
          p.moveTo(20.0, 21.0);
          p.arcToPoint(
            Offset(4.0, 21.0),
            radius: Radius.elliptical(8.0, 8.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: false,
          );
          canvas.drawPath(p, paint);
        }
        break;
      case 'users-round':
        {
          final p = Path();
          p.moveTo(18.0, 21.0);
          p.arcToPoint(
            Offset(2.0, 21.0),
            radius: Radius.elliptical(8.0, 8.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: false,
          );
          canvas.drawPath(p, paint);
        }
        canvas.drawCircle(Offset(10, 8), 5, paint);
        {
          final p = Path();
          p.moveTo(22.0, 20.0);
          p.cubicTo(22.0, 16.63, 20.0, 13.5, 18.0, 12.0);
          p.arcToPoint(
            Offset(17.55, 3.6999999999999993),
            radius: Radius.elliptical(5.0, 5.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: false,
          );
          canvas.drawPath(p, paint);
        }
        break;
      case 'wallet-cards':
        {
          final p = Path();
          p.moveTo(3.0, 11.0);
          p.lineTo(6.75, 11.0);
          p.arcToPoint(
            Offset(8.35, 11.8),
            radius: Radius.elliptical(2.0, 2.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: true,
          );
          p.lineTo(8.799999999999999, 12.4);
          p.arcToPoint(
            Offset(15.2, 12.4),
            radius: Radius.elliptical(4.0, 4.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: false,
          );
          p.lineTo(15.649999999999999, 11.8);
          p.arcToPoint(
            Offset(17.25, 11.0),
            radius: Radius.elliptical(2.0, 2.0),
            rotation: 0.0,
            largeArc: false,
            clockwise: true,
          );
          p.lineTo(21.0, 11.0);
          canvas.drawPath(p, paint);
        }
        {
          final p = Path();
          p.moveTo(3.0, 7.0);
          p.lineTo(21.0, 7.0);
          canvas.drawPath(p, paint);
        }
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(3, 3, 18, 18),
            Radius.circular(2),
          ),
          paint,
        );
        break;
      case 'x':
        {
          final p = Path();
          p.moveTo(18.0, 6.0);
          p.lineTo(6.0, 18.0);
          canvas.drawPath(p, paint);
        }
        {
          final p = Path();
          p.moveTo(6.0, 6.0);
          p.lineTo(18.0, 18.0);
          canvas.drawPath(p, paint);
        }
        break;
      default:
        canvas.drawCircle(const Offset(12, 12), 8, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _IconPainter old) =>
      old.name != name || old.color != color || old.stroke != stroke;
}
