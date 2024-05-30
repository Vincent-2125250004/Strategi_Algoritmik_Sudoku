import 'package:flutter/material.dart';
import 'package:sudoku_solver/sudoku_solver.dart';
import 'sudoku_dataset.dart';
import 'dart:isolate';

void main() {
  runApp(const SudokuSolverApp());
}

class SudokuSolverApp extends StatelessWidget {
  const SudokuSolverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sudoku Solver',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SudokuSolverPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SudokuSolverPage extends StatefulWidget {
  const SudokuSolverPage({super.key});

  @override
  _SudokuSolverPageState createState() => _SudokuSolverPageState();
}

class _SudokuSolverPageState extends State<SudokuSolverPage> {
  List<List<int>> sudokuGrid = List.generate(9, (i) => List.filled(9, 0));
  bool solving = false;
  DateTime? startTime;
  DateTime? endTime;
  List<String> pseudocodeSteps = [];
  int totalIterations = 0;
  String difficulty = 'Unknown';

  @override
  void initState() {
    super.initState();
    generateNewPuzzle();
  }

  Future<void> generateNewPuzzle() async {
    try {
      final puzzleData = await fetchPuzzleFromAPI();
      if (puzzleData != null) {
        setState(() {
          sudokuGrid = (puzzleData['puzzle'] as List)
              .map((row) => (row as List).map((val) => val as int).toList())
              .toList();
          difficulty = puzzleData['difficulty'] as String;
          solving = false;
          pseudocodeSteps.clear();
          totalIterations = 0;
        });
        print('Generated new puzzle: $sudokuGrid');
      } else {
        throw Exception('Failed to fetch puzzle');
      }
    } catch (error) {
      print('Error fetching puzzle: $error');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to generate puzzle: $error'),
      ));
    }
  }

  Future<void> _solveSudoku() async {
    setState(() {
      solving = true;
      startTime = DateTime.now();
      pseudocodeSteps.clear();
      totalIterations = 0; // Reset the iteration counter
    });

    ReceivePort receivePort = ReceivePort();
    await Isolate.spawn<SudokuSolverArgs>(
      _solveSudokuIsolate,
      SudokuSolverArgs(sudokuGrid, receivePort.sendPort),
    );

    bool solved = false;
    List<List<int>> boardState = sudokuGrid; // Initialize with current state

    await for (var message in receivePort) {
      if (message is List<List<int>>) {
        boardState = message;
      } else if (message is bool) {
        solved = message;
        break;
      } else if (message is String) {
        pseudocodeSteps.insert(0, message); // Add new steps to the beginning
        totalIterations++; // Increment the iteration counter

        // Only update the UI every 10 iterations to reduce lag
        if (totalIterations % 10 == 0) {
          setState(() {
            sudokuGrid = boardState;
          });
        }
      }
    }

    setState(() {
      solving = false;
      endTime = DateTime.now();
      sudokuGrid = boardState;
    });

    if (startTime != null && endTime != null) {
      Duration duration = endTime!.difference(startTime!);
      if (solved) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Solved in ${duration.inMilliseconds} milliseconds with $totalIterations iterations'),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('This puzzle cannot be solved.'),
        ));
      }
    }
  }

  static void _solveSudokuIsolate(SudokuSolverArgs args) async {
    List<List<int>> board = args.sudokuGrid;
    SendPort sendPort = args.sendPort;

    bool solved = await solveSudokuStepByStep(board, (updatedBoard, pseudocode) async {
      sendPort.send(updatedBoard);
      sendPort.send(pseudocode);
      await Future.delayed(const Duration(milliseconds: 1)); // Yield execution
    });

    sendPort.send(solved); // Send the final status
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sudoku Solver'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 9,
                  childAspectRatio: 1.0,
                ),
                itemCount: 81,
                itemBuilder: (context, index) {
                  int row = index ~/ 9;
                  int col = index % 9;
                  return GestureDetector(
                    onTap: () => _editCell(row, col),
                    child: Container(
                      margin: const EdgeInsets.all(2.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black),
                        color: sudokuGrid[row][col] != 0
                            ? Colors.grey[300]
                            : Colors.white,
                      ),
                      child: Center(
                        child: Text(
                          sudokuGrid[row][col] != 0
                              ? '${sudokuGrid[row][col]}'
                              : '',
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Text('Difficulty: $difficulty'), // Add difficulty display
            const SizedBox(height: 10),
            Text('Total Iterations: $totalIterations'),
            const SizedBox(height: 10),
            Expanded(
              flex: 1,
              child: ListView.builder(
                itemCount: pseudocodeSteps.length,
                itemBuilder: (context, index) {
                  return Text(pseudocodeSteps[index]);
                },
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: generateNewPuzzle,
                  child: const Text('New Puzzle'),
                ),
                ElevatedButton(
                  onPressed: solving ? null : _solveSudoku,
                  child: const Text('Solve Sudoku'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _editCell(int row, int col) async {
    setState(() {
      solving = false; // Stop solving if manually editing
    });

    int newValue = await showDialog<int>(
      context: context,
      builder: (context) {
        return const NumberPickerDialog();
      },
    ) ?? sudokuGrid[row][col];
    setState(() {
      sudokuGrid[row][col] = newValue;
    });
  }
}

class NumberPickerDialog extends StatefulWidget {
  const NumberPickerDialog({super.key});

  @override
  _NumberPickerDialogState createState() => _NumberPickerDialogState();
}

class _NumberPickerDialogState extends State<NumberPickerDialog> {
  int selectedNumber = 1;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pick a number'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(9, (index) {
          return RadioListTile<int>(
            title: Text('${index + 1}'),
            value: index + 1,
            groupValue: selectedNumber,
            onChanged: (value) {
              setState(() {
                selectedNumber = value!;
              });
            },
          );
        }),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(selectedNumber);
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}

class SudokuSolverArgs {
  final List<List<int>> sudokuGrid;
  final SendPort sendPort;

  SudokuSolverArgs(this.sudokuGrid, this.sendPort);
}

