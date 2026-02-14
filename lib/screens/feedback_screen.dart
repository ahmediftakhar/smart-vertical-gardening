import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _feedbackController = TextEditingController();

  late final DatabaseReference _feedbackRef;

  bool isSubmitting = false;
  int _selectedRating = 0;

  @override
  void initState() {
    super.initState();
    _feedbackRef = FirebaseDatabase.instance.ref('feedbacks');
  }

  Future<void> _submitFeedback() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      await _feedbackRef.push().set({
        'rating': _selectedRating,
        'feedback': _feedbackController.text.trim(),
        'timestamp': DateTime.now().toIso8601String(),
      });

      final SharedPreferences prefs =
          await SharedPreferences.getInstance();
      await prefs.setBool('feedback_submitted', true);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Thank you for your feedback!')),
      );

      Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Failed to submit feedback')),
        );
      }
    }
  }

  Future<void> _skipFeedback() async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();
    await prefs.setBool('feedback_submitted', true);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Widget _buildRatingStars() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final int starValue = index + 1;

        return IconButton(
          iconSize: 32,
          icon: Icon(
            Icons.star,
            color: _selectedRating >= starValue
                ? Colors.amber
                : Colors.grey,
          ),
          onPressed: () {
            setState(() {
              _selectedRating = starValue;
            });
          },
        );
      }),
    );
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback'),
        backgroundColor: Colors.green[800],
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _skipFeedback,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'We value your feedback!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              const Text('Rate your experience'),
              _buildRatingStars(),

              const SizedBox(height: 16),
              TextFormField(
                controller: _feedbackController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Your Feedback',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Feedback cannot be empty';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : _submitFeedback,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[800],
                  ),
                  child: isSubmitting
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : const Text(
                          'Submit',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
