import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ParentFeedbackScreen extends StatefulWidget {
  const ParentFeedbackScreen({super.key});

  @override
  State<ParentFeedbackScreen> createState() => _ParentFeedbackScreenState();
}

// 1. Added AutomaticKeepAliveClientMixin
class _ParentFeedbackScreenState extends State<ParentFeedbackScreen> with AutomaticKeepAliveClientMixin {
  final TextEditingController _controller = TextEditingController();
  bool _isSending = false;

  // 2. Tell Flutter to keep the text and state alive in the background
  @override
  bool get wantKeepAlive => true;

  void _sendFeedback() async {
    if (_controller.text.isEmpty) return;
    setState(() => _isSending = true);

    final user = FirebaseAuth.instance.currentUser;

    try {
      await FirebaseFirestore.instance.collection('feedback').add({
        'parentEmail': user?.email,
        'message': _controller.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      if (!mounted) return;

      _controller.clear();
      FocusScope.of(context).unfocus();

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Feedback sent to Admin"))
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"))
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 3. REQUIRED: Call super.build(context)
    super.build(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Contact Admin",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            "Have a concern or an update about your child? Send a message directly to the school administration.",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: "Type your message here (e.g. My child is sick today)",
              border: OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.blue, width: 2.0),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _isSending
              ? const Center(child: CircularProgressIndicator())
              : SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[900],
                foregroundColor: Colors.white,
              ),
              onPressed: _sendFeedback,
              child: const Text("SUBMIT FEEDBACK"),
            ),
          )
        ],
      ),
    );
  }
}