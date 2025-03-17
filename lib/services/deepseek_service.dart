import 'dart:convert';
import 'package:http/http.dart' as http;

class DeepSeekService {
  final String apiKey;
  final String baseUrl = 'https://api.deepseek.com/v1';

  DeepSeekService({required this.apiKey});

  Future<List<String>> generateTasks(DateTime date, {String? customPrompt}) async {
    try {
      final prompt = customPrompt ?? 'Generate a list of productive tasks for ${date.toString().split(' ')[0]}';
      
      final response = await http.post(
        Uri.parse('$baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a helpful AI assistant that generates structured daily schedules and tasks. Keep responses concise and practical.',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'max_tokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        
        // Parse the response into a list of tasks
        return content
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .map((line) => line.replaceAll(RegExp(r'^\d+\.\s*'), ''))
            .toList();
      } else {
        throw Exception('Failed to generate tasks: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to generate tasks: $e');
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