import 'package:flutter/material.dart';

class GoogleGIcon extends StatelessWidget {
  final double size;

  const GoogleGIcon({super.key, this.size = 20});

  static const _bluePath =
      'M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z';
  static const _greenPath =
      'M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z';
  static const _yellowPath =
      'M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l3.66-2.84z';
  static const _redPath =
      'M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z';

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: const _GoogleGPainter(),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  const _GoogleGPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24;
    canvas.scale(scale);
    canvas.drawPath(_parsePath(GoogleGIcon._bluePath), _fill(0xFF4285F4));
    canvas.drawPath(_parsePath(GoogleGIcon._greenPath), _fill(0xFF34A853));
    canvas.drawPath(_parsePath(GoogleGIcon._yellowPath), _fill(0xFFFBBC05));
    canvas.drawPath(_parsePath(GoogleGIcon._redPath), _fill(0xFFEA4335));
  }

  Paint _fill(int color) {
    return Paint()
      ..color = Color(color)
      ..style = PaintingStyle.fill;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Path _parsePath(String d) {
  final elements = <Object>[];
  final numberRegex = RegExp(r'[-+]?(\d*\.)?\d+(?:[eE][-+]?\d+)?');
  for (var i = 0; i < d.length; i++) {
    final ch = d[i];
    if (_isCommand(ch)) {
      elements.add(ch);
      continue;
    }
    final match = numberRegex.matchAsPrefix(d, i);
    if (match != null) {
      elements.add(double.parse(match.group(0)!));
      i += match.group(0)!.length - 1;
    }
  }

  final path = Path();
  var cx = 0.0;
  var cy = 0.0;
  var subX = 0.0;
  var subY = 0.0;
  var lastCubicX = 0.0;
  var lastCubicY = 0.0;
  var hasLastCubic = false;
  var lastQuadX = 0.0;
  var lastQuadY = 0.0;
  var hasLastQuad = false;
  var command = '';
  var index = 0;

  double next() => elements[index++] as double;
  (double, double) point(double x, double y, bool relative) =>
      (relative ? cx + x : x, relative ? cy + y : y);

  while (index < elements.length) {
    if (elements[index] is String) {
      command = elements[index] as String;
      index++;
    }
    if (command.isEmpty) break;
    final code = command.toUpperCase();
    final relative = command != code;

    switch (code) {
      case 'M':
        final (x, y) = point(next(), next(), relative);
        path.moveTo(x, y);
        cx = x;
        cy = y;
        subX = x;
        subY = y;
        command = relative ? 'l' : 'L';
      case 'Z':
        path.close();
        cx = subX;
        cy = subY;
      case 'L':
        final (x, y) = point(next(), next(), relative);
        path.lineTo(x, y);
        cx = x;
        cy = y;
      case 'H':
        final x = relative ? cx + next() : next();
        path.lineTo(x, cy);
        cx = x;
      case 'V':
        final y = relative ? cy + next() : next();
        path.lineTo(cx, y);
        cy = y;
      case 'C':
        final (x1, y1) = point(next(), next(), relative);
        final (x2, y2) = point(next(), next(), relative);
        final (x, y) = point(next(), next(), relative);
        path.cubicTo(x1, y1, x2, y2, x, y);
        lastCubicX = x2;
        lastCubicY = y2;
        hasLastCubic = true;
        cx = x;
        cy = y;
      case 'S':
        final (x1, y1) = hasLastCubic
            ? (2 * cx - lastCubicX, 2 * cy - lastCubicY)
            : (cx, cy);
        final (x2, y2) = point(next(), next(), relative);
        final (x, y) = point(next(), next(), relative);
        path.cubicTo(x1, y1, x2, y2, x, y);
        lastCubicX = x2;
        lastCubicY = y2;
        hasLastCubic = true;
        cx = x;
        cy = y;
      case 'Q':
        final (x1, y1) = point(next(), next(), relative);
        final (x, y) = point(next(), next(), relative);
        path.quadraticBezierTo(x1, y1, x, y);
        lastQuadX = x1;
        lastQuadY = y1;
        hasLastQuad = true;
        cx = x;
        cy = y;
      case 'T':
        final (x1, y1) = hasLastQuad
            ? (2 * cx - lastQuadX, 2 * cy - lastQuadY)
            : (cx, cy);
        final (x, y) = point(next(), next(), relative);
        path.quadraticBezierTo(x1, y1, x, y);
        lastQuadX = x1;
        lastQuadY = y1;
        hasLastQuad = true;
        cx = x;
        cy = y;
      case 'A':
        next();
        next();
        next();
        next();
        next();
        final (x, y) = point(next(), next(), relative);
        path.lineTo(x, y);
        cx = x;
        cy = y;
      default:
        command = '';
    }
  }

  return path;
}

bool _isCommand(String ch) => RegExp(r'[a-zA-Z]').hasMatch(ch);
