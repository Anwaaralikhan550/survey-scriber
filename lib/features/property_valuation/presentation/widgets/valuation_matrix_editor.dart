import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/valuation_matrix.dart';

/// Blank grid for the FBS Valuation Matrix: the surveyor types the comparables. Nothing is filled in
/// or calculated here. [value] is the stored answer (a JSON grid) and [onChanged] receives the new one.
class ValuationMatrixEditor extends StatefulWidget {
  const ValuationMatrixEditor({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<ValuationMatrixEditor> createState() => _ValuationMatrixEditorState();
}

class _ValuationMatrixEditorState extends State<ValuationMatrixEditor> {
  static const double _labelWidth = 118;
  static const double _cellWidth = 124;

  late List<List<TextEditingController>> _controllers;
  String _lastEncoded = '';

  @override
  void initState() {
    super.initState();
    final grid = ValuationMatrix.parse(widget.value);
    _lastEncoded = ValuationMatrix.encode(grid);
    _controllers = [
      for (final row in grid) [for (final cell in row) TextEditingController(text: cell)],
    ];
  }

  @override
  void didUpdateWidget(ValuationMatrixEditor old) {
    super.didUpdateWidget(old);
    // The answer changed from outside (loaded late, or synchronised): show it, unless it is what was typed.
    final incoming = ValuationMatrix.encode(ValuationMatrix.parse(widget.value));
    if (incoming != _lastEncoded) {
      final grid = ValuationMatrix.parse(widget.value);
      for (var r = 0; r < grid.length; r++) {
        for (var c = 0; c < grid[r].length; c++) {
          if (_controllers[r][c].text != grid[r][c]) _controllers[r][c].text = grid[r][c];
        }
      }
      _lastEncoded = incoming;
    }
  }

  @override
  void dispose() {
    for (final row in _controllers) {
      for (final c in row) {
        c.dispose();
      }
    }
    super.dispose();
  }

  void _changed() {
    final grid = [for (final row in _controllers) [for (final c in row) c.text]];
    final raw = ValuationMatrix.encode(grid);
    // Compared with the answer coming back in canonical (trimmed) form, so a space typed at the end of a word
    // is not taken for a change from outside and removed.
    _lastEncoded = ValuationMatrix.encode(ValuationMatrix.parse(raw));
    widget.onChanged(raw);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final border = BorderSide(color: colors.outlineVariant.withOpacity(0.7));

    Widget head(String text, {required double width}) => Container(
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: colors.primaryContainer.withOpacity(0.35),
            border: Border(top: border, left: border, bottom: border, right: border),
          ),
          child: Text(
            text,
            style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        );

    Widget rowName(String text) => Container(
          width: _labelWidth,
          constraints: const BoxConstraints(minHeight: 48),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest.withOpacity(0.5),
            border: Border(left: border, bottom: border, right: border),
          ),
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 0, 2, 4),
          child: Text(
            ValuationMatrix.title,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: colors.primary),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 0, 2, 10),
          child: Text(
            'Type the comparable details. Nothing is filled in for you.',
            style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  head(ValuationMatrix.headers.first, width: _labelWidth),
                  for (final h in ValuationMatrix.headers.skip(1)) head(h, width: _cellWidth),
                ],
              ),
              for (var r = 0; r < ValuationMatrix.rowLabels.length; r++)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      rowName(ValuationMatrix.rowLabels[r]),
                      for (var c = 0; c < ValuationMatrix.columns; c++)
                        Container(
                          width: _cellWidth,
                          constraints: const BoxConstraints(minHeight: 48),
                          decoration: BoxDecoration(
                            border: Border(bottom: border, right: border),
                          ),
                          // The label merges into the TextField's own accessibility node (no second text-field node).
                          child: Semantics(
                            label: '${ValuationMatrix.rowLabels[r]}, ${ValuationMatrix.headers[c + 1]}',
                            child: TextField(
                              key: ValueKey('matrix:$r:$c'),
                              controller: _controllers[r][c],
                              maxLength: ValuationMatrix.maxCellLength,
                              // Long text wraps and the row grows; a new line cannot be typed into a cell.
                              minLines: 1,
                              maxLines: null,
                              keyboardType: TextInputType.text,
                              textInputAction: TextInputAction.next,
                              inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'[\r\n]'))],
                              style: theme.textTheme.bodyMedium,
                              decoration: const InputDecoration(
                                counterText: '',
                                isDense: true,
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                              ),
                              onChanged: (_) => _changed(),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
