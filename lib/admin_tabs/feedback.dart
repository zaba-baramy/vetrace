import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Make sure to add 'intl' to your pubspec.yaml

class AdminFeedbackTab extends StatelessWidget {
  const AdminFeedbackTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('feedback')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        if (snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No feedback received yet."));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var data = doc.data() as Map<String, dynamic>;

            // Nicer date formatting
            String formattedTime = "";
            if (data['timestamp'] != null) {
              DateTime date = (data['timestamp'] as Timestamp).toDate();
              formattedTime = DateFormat('MMM d, h:mm a').format(date);
            }

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              elevation: 2,
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.blueGrey,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text(
                  data['parentEmail'] ?? 'Anonymous Parent',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 5),
                    Text(data['message'] ?? ''),
                    const SizedBox(height: 5),
                    Text(formattedTime, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
                // --- THE RESOLVE (DELETE) BUTTON ---
                trailing: IconButton(
                  icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                  tooltip: 'Resolve & Remove',
                  onPressed: () => _confirmResolve(context, doc.id),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Confirmation dialog before deleting feedback
  void _confirmResolve(BuildContext context, String docId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Resolve Feedback?"),
        content: const Text("This will permanently remove this message from your list."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text("Resolve"),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await FirebaseFirestore.instance.collection('feedback').doc(docId).delete();
    }
  }
}