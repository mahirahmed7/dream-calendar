import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/deepseek_service.dart';

class DreamAIScreen extends StatefulWidget {
  final DateTime selectedDate;
  final Function(List<String>) onTasksGenerated;

  const DreamAIScreen({
    super.key,
    required this.selectedDate,
    required this.onTasksGenerated,
  });

  @override
  State<DreamAIScreen> createState() => _DreamAIScreenState();
}

class _DreamAIScreenState extends State<DreamAIScreen> {
  final TextEditingController _promptController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  final _deepSeekService = DeepSeekService(apiKey: dotenv.env['DEEPSEEK_API_KEY'] ?? '');

  Future<void> _generateSchedule() async {
    if (_promptController.text.trim().isEmpty) {
      setState(() {
        _error = 'Please enter what you need help with';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tasks = await _deepSeekService.generateTasks(
        widget.selectedDate,
        customPrompt: _promptController.text,
      );
      widget.onTasksGenerated(tasks);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to generate schedule. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Dream AI',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 24,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'What would you like help scheduling?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tell me about your goals, timeframe, or specific tasks you need help organizing.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _promptController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'E.g., Help me create a weekly workout schedule...',
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.black87),
                    ),
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 14,
                      ),
                    ),
                  ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _generateSchedule,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Generate Schedule',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.white70,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
                ),
              ),
            ),
        ],
      ),
    );
  }
} 