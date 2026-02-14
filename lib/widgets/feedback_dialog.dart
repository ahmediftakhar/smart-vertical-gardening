import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class FeedbackDialog {
  static void show(BuildContext context) {
    final TextEditingController commentController = TextEditingController();
    double rating = 0;

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Rate Us'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                      ),
                      onPressed: () {
                        setState(() {
                          rating = index + 1.0;
                        });
                      },
                    );
                  }),
                ),
                TextField(
                  controller: commentController,
                  decoration: const InputDecoration(
                    hintText: "Optional comment...",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  if (rating == 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please select a rating.")),
                    );
                    return;
                  }

                  // Save feedback to Firebase
                  FirebaseDatabase.instance.ref('feedbacks').push().set({
                    'rating': rating,
                    'comment': commentController.text,
                    'timestamp': DateTime.now().toIso8601String(),
                  });

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Thanks for your feedback!")),
                  );
                },
                child: const Text("Submit"),
              ),
            ],
          ),
        );
      },
    );
  }
}
