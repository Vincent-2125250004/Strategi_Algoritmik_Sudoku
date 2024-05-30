import 'dart:convert';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>?> fetchPuzzleFromAPI() async {
  try {
    final response = await http.get(Uri.parse(
        'https://sudoku-api.vercel.app/api/dosuku?query={newboard(limit:1){grids{value,difficulty}}}'));

    if (response.statusCode == 200) {
      print('Response body: ${response.body}');
      final jsonResponse = json.decode(response.body);
      final newBoard = jsonResponse['newboard'] as Map<String, dynamic>;
      final grids = newBoard['grids'] as List<dynamic>;
      final value = grids[0]['value'] as List<dynamic>;
      final difficulty = grids[0]['difficulty'] as String;
      return {
        'puzzle': value.map((row) => List<int>.from(row.cast<int>())).toList(),
        'difficulty': difficulty,
      };
    } else {
      print('Failed to load puzzle from API, status code: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    print('Error fetching puzzle: $e');
    return null;
  }
}
