// ignore_for_file: avoid_print
// Gera app_icon.png e app_icon_foreground.png em assets/icon/
// Execute: dart run scripts/generate_icon.dart
// Requer dev_dependency: image: ^4.1.7

import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  _generateFullIcon();
  _generateForegroundIcon();
  stdout.writeln('Ícones gerados em assets/icon/');
  stdout.writeln('Execute: flutter pub run flutter_launcher_icons');
}

/// Ícone completo 1024×1024 (fundo teal + escala da justiça branca)
void _generateFullIcon() {
  const size = 1024;
  final image = img.Image(width: size, height: size);

  // Fundo gradiente teal
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final t = (x + y) / (size * 2.0);
      final r = (0 + (0 - 0) * t).round();
      final g = (191 + (105 - 191) * t).round().clamp(0, 255);
      final b = (165 + (108 - 165) * t).round().clamp(0, 255);
      image.setPixelRgb(x, y, r, g, b);
    }
  }

  // Círculo central levemente mais claro
  img.fillCircle(
    image,
    x: size ~/ 2,
    y: size ~/ 2,
    radius: 420,
    color: img.ColorRgba8(255, 255, 255, 20),
  );

  // Desenha a escala da justiça em branco
  _drawScale(image, size);

  final file = File('assets/icon/app_icon.png');
  file.writeAsBytesSync(img.encodePng(image));
}

/// Foreground para ícone adaptativo: fundo transparente + escala branca
void _generateForegroundIcon() {
  const size = 1024;
  final image = img.Image(width: size, height: size);
  img.fill(image, color: img.ColorRgba8(0, 0, 0, 0));
  _drawScale(image, size);

  final file = File('assets/icon/app_icon_foreground.png');
  file.writeAsBytesSync(img.encodePng(image));
}

void _drawScale(img.Image image, int size) {
  final white = img.ColorRgba8(255, 255, 255, 255);
  final s = size.toDouble();

  // Poste central
  _drawThickLine(image, s * .50, s * .12, s * .50, s * .82, 18, white);

  // Base
  _drawThickLine(image, s * .22, s * .82, s * .78, s * .82, 18, white);

  // Viga horizontal
  _drawThickLine(image, s * .08, s * .30, s * .92, s * .30, 16, white);

  // Correntes esquerda
  _drawThickLine(image, s * .15, s * .30, s * .08, s * .52, 10, white);
  _drawThickLine(image, s * .08, s * .30, s * .15, s * .52, 10, white);

  // Correntes direita
  _drawThickLine(image, s * .85, s * .30, s * .92, s * .52, 10, white);
  _drawThickLine(image, s * .92, s * .30, s * .85, s * .52, 10, white);

  // Prato esquerdo
  _drawArcBottom(image, s * .115, s * .52, s * .06, 60, 12, white);
  _drawThickLine(image, s * .055, s * .52, s * .175, s * .52, 12, white);

  // Prato direito
  _drawArcBottom(image, s * .885, s * .52, s * .06, 60, 12, white);
  _drawThickLine(image, s * .825, s * .52, s * .945, s * .52, 12, white);

  // Círculos nos pivôs
  img.fillCircle(image, x: (s * .50).round(), y: (s * .12).round(), radius: 22, color: white);
  img.fillCircle(image, x: (s * .50).round(), y: (s * .30).round(), radius: 16, color: white);
  img.fillCircle(image, x: (s * .08).round(), y: (s * .30).round(), radius: 10, color: white);
  img.fillCircle(image, x: (s * .92).round(), y: (s * .30).round(), radius: 10, color: white);
}

void _drawThickLine(
  img.Image image,
  double x1, double y1,
  double x2, double y2,
  int thickness,
  img.Color color,
) {
  final dx = x2 - x1;
  final dy = y2 - y1;
  final len = (dx * dx + dy * dy).abs();
  if (len == 0) return;
  final steps = (len * 0.5).ceil().clamp(1, 2000);
  for (var i = 0; i <= steps; i++) {
    final t = i / steps;
    final cx = (x1 + dx * t).round();
    final cy = (y1 + dy * t).round();
    img.fillCircle(image, x: cx, y: cy, radius: thickness ~/ 2, color: color);
  }
}

void _drawArcBottom(
  img.Image image,
  double cx, double cy,
  double radiusFraction,
  int angleDegrees,
  int thickness,
  img.Color color,
) {
  const pi = 3.14159265358979;
  final r = image.width * radiusFraction;
  final halfAngle = angleDegrees / 2 * pi / 180;
  final steps = 40;
  for (var i = 0; i <= steps; i++) {
    final t = i / steps;
    final angle = -halfAngle + t * (2 * halfAngle);
    final x = cx + r * angle;
    final y = cy + r * (1 - (angle / halfAngle) * (angle / halfAngle)) * 0.5;
    img.fillCircle(image, x: x.round(), y: y.round(), radius: thickness ~/ 2, color: color);
  }
}
