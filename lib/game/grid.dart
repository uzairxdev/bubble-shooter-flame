import 'package:flame/components.dart';

import 'bubble.dart';

/// Global tuning for the board.
///
/// The world is a fixed 420 logical units wide; the camera zooms so the
/// width always fills the screen exactly, and the visible height adapts to
/// the device's aspect ratio. Mutable fields are recomputed by the game in
/// [onGameResize]; defaults match the classic 420x800 stage (used by tests).
class GameConfig {
  static const double designWidth = 420;
  static double get width => designWidth;

  static const int columns = 10;

  /// Visible world height — set from the real screen in onGameResize.
  static double height = 800;

  /// Center of row 0. Kept clear of the Flutter HUD overlaying the top.
  static double gridTopY = 110;

  /// Bubbles crossing this line end the game.
  static double dangerY = 590;

  static double shooterY = 690;

  static const double flySpeed = 950;
  static const int shotsPerRow = 5; // shots before a new row pushes down
}

/// One horizontal row of the hex grid. [offset] rows are shifted right by
/// half a cell so bubbles nest into the gaps of the row above (classic
/// bubble-shooter packing). Each row carries its own offset flag so inserting
/// a new row at the top never moves existing bubbles sideways.
class BubbleRow {
  BubbleRow({required this.offset, required int capacity})
      : cells = List<Bubble?>.filled(capacity, null);

  final bool offset;
  final List<Bubble?> cells;
}

/// Hex-grid math + board queries. Cells are addressed as (row, col) records.
class GridLayout {
  static double get cell => GameConfig.width / GameConfig.columns;
  static double get radius => cell / 2 - 1;
  static double get rowH => cell * 0.8660254;

  static int capacityFor(bool offset) =>
      offset ? GameConfig.columns - 1 : GameConfig.columns;

  static bool validCell(int row, int col, List<BubbleRow> rows) {
    if (row < 0 || row >= rows.length) return false;
    return col >= 0 && col < rows[row].cells.length;
  }

  static Vector2 cellCenter(int row, int col, List<BubbleRow> rows) {
    final shift = rows[row].offset ? cell / 2 : 0.0;
    return Vector2(
      cell / 2 + col * cell + shift,
      GameConfig.gridTopY + row * rowH,
    );
  }

  /// The six hex neighbors of a cell, filtered to valid cells.
  static List<(int, int)> neighbors(int row, int col, List<BubbleRow> rows) {
    final List<(int, int)> deltas = rows[row].offset
        ? const [(0, -1), (0, 1), (-1, 0), (-1, 1), (1, 0), (1, 1)]
        : const [(0, -1), (0, 1), (-1, -1), (-1, 0), (1, -1), (1, 0)];
    final out = <(int, int)>[];
    for (final (dr, dc) in deltas) {
      final nr = row + dr;
      final nc = col + dc;
      if (validCell(nr, nc, rows)) out.add((nr, nc));
    }
    return out;
  }

  /// Flood fill over same-colored connected bubbles starting at (row, col).
  static Set<(int, int)> floodSame(int row, int col, List<BubbleRow> rows) {
    final target = rows[row].cells[col]?.bubbleColor;
    if (target == null) return <(int, int)>{};
    final seen = <(int, int)>{(row, col)};
    final stack = <(int, int)>[(row, col)];
    while (stack.isNotEmpty) {
      final (r, c) = stack.removeLast();
      for (final (nr, nc) in neighbors(r, c, rows)) {
        if (!seen.contains((nr, nc)) &&
            rows[nr].cells[nc]?.bubbleColor == target) {
          seen.add((nr, nc));
          stack.add((nr, nc));
        }
      }
    }
    return seen;
  }

  /// Every occupied cell NOT connected to the top row. Those bubbles fall.
  static Set<(int, int)> floatingCells(List<BubbleRow> rows) {
    final anchored = <(int, int)>{};
    final stack = <(int, int)>[];
    for (var c = 0; c < rows[0].cells.length; c++) {
      if (rows[0].cells[c] != null) {
        anchored.add((0, c));
        stack.add((0, c));
      }
    }
    while (stack.isNotEmpty) {
      final (r, c) = stack.removeLast();
      for (final (nr, nc) in neighbors(r, c, rows)) {
        if (!anchored.contains((nr, nc)) && rows[nr].cells[nc] != null) {
          anchored.add((nr, nc));
          stack.add((nr, nc));
        }
      }
    }
    final floating = <(int, int)>{};
    for (var r = 0; r < rows.length; r++) {
      for (var c = 0; c < rows[r].cells.length; c++) {
        if (rows[r].cells[c] != null && !anchored.contains((r, c))) {
          floating.add((r, c));
        }
      }
    }
    return floating;
  }
}
