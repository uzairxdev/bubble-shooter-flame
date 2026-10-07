import 'dart:math';

import 'bubble.dart';
import 'grid.dart';

/// Builds the starting board for a level.
///
/// Deterministic per level number, so retrying a level rebuilds the
/// identical board. Higher levels get more rows and more colors.
class LevelGenerator {
  static List<BubbleRow> generate(int level) =>
      _generate(level, Random(level * 7919 + 101));

  /// Deterministic board from an explicit seed — used by the daily
  /// challenge so every player gets the same board on a given day.
  static List<BubbleRow> generateSeeded(int level, int seed) =>
      _generate(level, Random(seed));

  static List<BubbleRow> _generate(int level, Random rng) {
    final colorCount =
        (3 + level ~/ 2).clamp(3, BubbleColor.values.length).toInt();
    final palette =
        List<BubbleColor>.of(BubbleColor.values.sublist(0, colorCount));
    final rowCount = (5 + level ~/ 2).clamp(5, 9).toInt();
    final pattern = rng.nextInt(3);

    final rows = <BubbleRow>[];
    for (var r = 0; r < rowCount; r++) {
      final offset = r.isOdd;
      final row =
          BubbleRow(offset: offset, capacity: GridLayout.capacityFor(offset));
      for (var c = 0; c < row.cells.length; c++) {
        final fill = switch (pattern) {
          1 => (r + c).isEven, // checkerboard
          2 => rng.nextDouble() < 0.85, // scattered
          _ => true, // solid
        };
        if (fill) {
          row.cells[c] = Bubble(
            bubbleColor: palette[rng.nextInt(palette.length)],
            radius: GridLayout.radius,
          );
        }
      }
      rows.add(row);
    }
    return rows;
  }
}
