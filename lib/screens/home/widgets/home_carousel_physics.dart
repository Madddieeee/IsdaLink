import 'package:flutter/widgets.dart';

/// Snaps a horizontal Home marketplace carousel to the nearest full content
/// card while still allowing the final compact discovery card to rest flush
/// against the trailing screen padding.
class HomeItemSnapScrollPhysics extends ScrollPhysics {
  const HomeItemSnapScrollPhysics({
    super.parent,
    required this.itemExtent,
  });

  final double itemExtent;

  @override
  HomeItemSnapScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return HomeItemSnapScrollPhysics(
      parent: buildParent(ancestor),
      itemExtent: itemExtent,
    );
  }

  double targetPixels(
    ScrollMetrics position,
    Tolerance tolerance,
    double velocity,
  ) {
    var item = position.pixels / itemExtent;

    if (velocity < -tolerance.velocity) {
      item -= 0.5;
    } else if (velocity > tolerance.velocity) {
      item += 0.5;
    }

    final snapped = item.roundToDouble() * itemExtent;
    return snapped
        .clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        )
        .toDouble();
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }

    final tolerance = toleranceFor(position);
    final target = targetPixels(position, tolerance, velocity);

    if ((target - position.pixels).abs() < tolerance.distance) {
      return null;
    }

    return ScrollSpringSimulation(
      spring,
      position.pixels,
      target,
      velocity,
      tolerance: tolerance,
    );
  }
}
