import 'package:bubble_pop/game/bubble.dart';
import 'package:bubble_pop/game/grid.dart';
import 'package:bubble_pop/game/level_generator.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a small board from a literal color map (null = empty cell).
List<BubbleRow> makeRows(List<List<BubbleColor?>> colors) {
  final rows = <BubbleRow>[];
  for (var r = 0; r < colors.length; r++) {
    final offset = r.isOdd;
    final row =
        BubbleRow(offset: offset, capacity: GridLayout.capacityFor(offset));
    for (var c = 0; c < colors[r].length && c < row.cells.length; c++) {
      final color = colors[r][c];
      if (color != null) {
        row.cells[c] =
            Bubble(bubbleColor: color, radius: GridLayout.radius);
      }
    }
    rows.add(row);
  }
  return rows;
}

String _boardSig(List<BubbleRow> rows) => rows
    .map((r) => r.cells
        .map((b) => b == null ? '.' : b.bubbleColor.index.toString())
        .join(','))
    .join(';');

void main() {
  test('row capacities alternate 10 / 9', () {
    expect(GridLayout.capacityFor(false), 10);
    expect(GridLayout.capacityFor(true), 9);
  });

  test('odd rows are shifted right by half a cell', () {
    final rows = makeRows([
      [BubbleColor.red],
      [BubbleColor.blue],
    ]);
    final evenCenter = GridLayout.cellCenter(0, 0, rows);
    final oddCenter = GridLayout.cellCenter(1, 0, rows);
    expect(evenCenter.x, GridLayout.cell / 2);
    expect(oddCenter.x, GridLayout.cell / 2 + GridLayout.cell / 2);
    expect(
      oddCenter.y - evenCenter.y,
      moreOrLessEquals(GridLayout.rowH, epsilon: 1e-4),
    );
  });

  test('interior odd cell has all six neighbors', () {
    final rows = makeRows([
      [BubbleColor.red, BubbleColor.red, BubbleColor.red],
      [BubbleColor.red, BubbleColor.red, BubbleColor.red],
      [BubbleColor.red, BubbleColor.red, BubbleColor.red],
    ]);
    final n = GridLayout.neighbors(1, 1, rows).toSet();
    expect(
      n,
      {(1, 0), (1, 2), (0, 1), (0, 2), (2, 1), (2, 2)},
    );
  });

  test('edge cells only report valid neighbors', () {
    final rows = makeRows([
      [BubbleColor.red, BubbleColor.red],
      [BubbleColor.red],
    ]);
    final n = GridLayout.neighbors(0, 0, rows).toSet();
    // even row, top-left corner: (0,1), (1,0); (-1,*) and (*,-1) invalid
    expect(n, {(0, 1), (1, 0)});
  });

  test('flood fill finds same-color connected group', () {
    final rows = makeRows([
      [BubbleColor.red, BubbleColor.red, BubbleColor.blue],
      [BubbleColor.red, BubbleColor.blue],
      [BubbleColor.blue, BubbleColor.blue, BubbleColor.blue],
    ]);
    expect(
      GridLayout.floodSame(0, 0, rows),
      {(0, 0), (0, 1), (1, 0)},
    );
    expect(
      GridLayout.floodSame(2, 0, rows),
      {(2, 0), (2, 1), (2, 2), (1, 1), (0, 2)},
    );
  });

  test('floating detection finds clusters detached from the top', () {
    final rows = makeRows([
      [BubbleColor.red, null, null],
      [null, null],
      [BubbleColor.blue, BubbleColor.blue, BubbleColor.blue],
    ]);
    expect(
      GridLayout.floatingCells(rows),
      {(2, 0), (2, 1), (2, 2)},
    );
  });

  test('level generation is deterministic per level', () {
    List<List<int?>> snapshot(int level) {
      final rows = LevelGenerator.generate(level);
      return [
        for (final r in rows)
          [for (final b in r.cells) b?.bubbleColor.index],
      ];
    }

    expect(snapshot(3), snapshot(3));
    expect(snapshot(3), isNot(snapshot(4)));
  });

  test('generated levels alternate row offsets and stay in bounds', () {
    for (var level = 1; level <= 6; level++) {
      final rows = LevelGenerator.generate(level);
      expect(rows.length, inInclusiveRange(5, 9));
      for (var r = 0; r < rows.length; r++) {
        expect(rows[r].offset, r.isOdd);
        expect(rows[r].cells.length,
            GridLayout.capacityFor(rows[r].offset));
        // every bubble center must be inside the playfield
        for (var c = 0; c < rows[r].cells.length; c++) {
          if (rows[r].cells[c] != null) {
            final p = GridLayout.cellCenter(r, c, rows);
            expect(p.x - GridLayout.radius, greaterThanOrEqualTo(0));
            expect(p.x + GridLayout.radius,
                lessThanOrEqualTo(GameConfig.width));
          }
        }
      }
    }
  });
  test('daily challenge boards are deterministic per seed', () {
    const seed = 20261007;
    final a = LevelGenerator.generateSeeded(3, seed);
    final b = LevelGenerator.generateSeeded(3, seed);
    expect(_boardSig(a), _boardSig(b));
    expect(a.length, greaterThan(0));
  });

  test('different daily seeds give different boards', () {
    final a = LevelGenerator.generateSeeded(3, 20261007);
    final b = LevelGenerator.generateSeeded(3, 20261008);
    expect(_boardSig(a), isNot(_boardSig(b)));
  });
}
