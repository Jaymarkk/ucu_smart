import 'dart:ui';

Offset percentToMapPixel(Size mapSize, Offset percent) {
  return Offset(
    mapSize.width * percent.dx / 100,
    mapSize.height * percent.dy / 100,
  );
}

Offset mapPixelToPercent(Size mapSize, Offset pixel) {
  if (mapSize.width <= 0 || mapSize.height <= 0) {
    throw ArgumentError.value(mapSize, 'mapSize', 'Must be non-zero.');
  }
  return Offset(
    pixel.dx / mapSize.width * 100,
    pixel.dy / mapSize.height * 100,
  );
}
