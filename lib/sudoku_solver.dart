Future<bool> solveSudokuStepByStep(List<List<int>> board,
    void Function(List<List<int>>, String) onStep) async {
  // Array to keep track of used numbers in rows, columns, and boxes
  List<List<bool>> rowsUsed = List.generate(9, (_) => List.filled(9, false));
  List<List<bool>> colsUsed = List.generate(9, (_) => List.filled(9, false));
  List<List<bool>> boxesUsed = List.generate(9, (_) => List.filled(9, false));

  // Initialize the tracking arrays
  for (int row = 0; row < 9; row++) {
    for (int col = 0; col < 9; col++) {
      int num = board[row][col];
      if (num != 0) {
        int boxIndex = (row ~/ 3) * 3 + (col ~/ 3);
        rowsUsed[row][num - 1] = true;
        colsUsed[col][num - 1] = true;
        boxesUsed[boxIndex][num - 1] = true;
      }
    }
  }

  Future<bool> solve() async {
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (board[row][col] == 0) {
          int boxIndex = (row ~/ 3) * 3 + (col ~/ 3);
          for (int num = 1; num <= 9; num++) {
            if (!rowsUsed[row][num - 1] &&
                !colsUsed[col][num - 1] &&
                !boxesUsed[boxIndex][num - 1]) {
              board[row][col] = num;
              rowsUsed[row][num - 1] = true;
              colsUsed[col][num - 1] = true;
              boxesUsed[boxIndex][num - 1] = true;

              onStep(List.generate(9, (i) => List.from(board[i])),
                  'Placed $num at ($row, $col)');
              await Future.delayed(
                  const Duration(milliseconds: 1)); // Yield execution

              if (await solve()) {
                return true;
              }
              board[row][col] = 0;
              rowsUsed[row][num - 1] = false;
              colsUsed[col][num - 1] = false;
              boxesUsed[boxIndex][num - 1] = false;

              onStep(List.generate(9, (i) => List.from(board[i])),
                  'Removed $num from ($row, $col)');
              await Future.delayed(
                  const Duration(milliseconds: 1)); // Yield execution
            } else {
              onStep(List.generate(9, (i) => List.from(board[i])),
                  'Skipped $num at ($row, $col) as it is invalid');
            }
          }
          return false;
        }
      }
    }
    return true;
  }

  return await solve();
}

bool isValid(List<List<int>> board, int row, int col, int num) {
  int boxIndex = (row ~/ 3) * 3 + (col ~/ 3);
  for (int i = 0; i < 9; i++) {
    if (board[row][i] == num ||
        board[i][col] == num ||
        board[row - row % 3 + i ~/ 3][col - col % 3 + i % 3] == num) {
      return false;
    }
  }
  return true;
}
