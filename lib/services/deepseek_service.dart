import 'dart:convert';
import 'package:http/http.dart' as http;

class DeepSeekService {
  static const String _baseUrl = 'https://api.deepseek.com/v1/chat/completions';
  final String apiKey;

  DeepSeekService({required this.apiKey});

  Future<List<String>> generateTasks(DateTime date) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            {
              'role': 'user',
              'content': 'Generate 3-5 suggested tasks or activities for ${_formatDate(date)}. '
                  'Return them in a simple list format, one task per line, without numbers or bullet points.',
            }
          ],
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        
        // Split the content into lines and clean up any empty lines
        return content
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .map((line) => line.trim())
            .toList();
      } else {
        throw Exception('Failed to generate tasks: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error generating tasks: $e');
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
} 