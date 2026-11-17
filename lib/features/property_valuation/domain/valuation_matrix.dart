import 'dart:convert';

/// The "FBS Valuation Matrix" of the client's sample valuation report (comparables table).
///
/// It is always blank until the surveyor types into it, in the app or in the desktop browser editor:
/// nothing here is calculated or generated. The grid is kept as one answer (`et_matrix_grid` on the
/// `valuation_matrix` screen) holding a JSON list of rows, each a list of six cell texts
/// (Comp 1 .. Comp 5, Subject). The row names are fixed.
class ValuationMatrix {
  const ValuationMatrix._();

  static const screenId = 'valuation_matrix';
  static const fieldId = 'et_matrix_grid';
  static const title = 'FBS Valuation Matrix';

  /// Header row of the table: the first cell names the row column.
  static const headers = <String>['Best Match', 'Comp 1', 'Comp 2', 'Comp 3', 'Comp 4', 'Comp 5', 'Subject'];

  /// Row names, as in the client's sample.
  static const rowLabels = <String>[
    'Address',
    'Date of Trans',
    'Price',
    'Size / Sqm',
    'Bedrooms',
    'Condition',
    'Compare',
    'Type',
    'Tenure',
    'Price/Sqm',
    'Features',
    'Adjustment',
    'Amount',
    'Adjustment',
    'Amount',
    'Adjustment',
    'Amount',
  ];

  static const columns = 6;
  static const maxCellLength = 200;

  /// Cell texts only (no row names): [rowLabels.length] rows of [columns] empty strings.
  static List<List<String>> emptyGrid() =>
      [for (var r = 0; r < rowLabels.length; r++) List<String>.filled(columns, '')];

  /// The stored answer as a grid. Anything that is not a list of rows is treated as blank, so a bad
  /// or old value can never break the screen or the report.
  static List<List<String>> parse(String? stored) {
    final grid = emptyGrid();
    final text = (stored ?? '').trim();
    if (text.isEmpty) return grid;
    try {
      final decoded = jsonDecode(text);
      if (decoded is! List) return grid;
      for (var r = 0; r < rowLabels.length && r < decoded.length; r++) {
        final row = decoded[r];
        if (row is! List) continue;
        for (var c = 0; c < columns && c < row.length; c++) {
          final cell = row[c];
          if (cell == null) continue;
          final value = '$cell'.trim();
          grid[r][c] = value.length > maxCellLength ? value.substring(0, maxCellLength) : value;
        }
      }
    } on FormatException {
      return grid;
    }
    return grid;
  }

  /// The answer to store. A grid with nothing typed is stored as an empty answer.
  static String encode(List<List<String>> grid) {
    if (grid.every((row) => row.every((c) => c.trim().isEmpty))) return '';
    return jsonEncode(grid);
  }

  /// Table rows for the report and the browser editor: row name first, then the six cells.
  static List<List<String>> tableRows(List<List<String>> grid) => [
        for (var r = 0; r < rowLabels.length; r++) [rowLabels[r], ...grid[r]],
      ];

  /// The grid back from table rows (row name column dropped). Rows or cells that are missing stay blank.
  static List<List<String>> gridFromTableRows(List<List<String>> rows) {
    final grid = emptyGrid();
    for (var r = 0; r < rowLabels.length && r < rows.length; r++) {
      for (var c = 0; c < columns; c++) {
        final i = c + 1;
        if (i < rows[r].length) grid[r][c] = rows[r][i].trim();
      }
    }
    return grid;
  }
}
