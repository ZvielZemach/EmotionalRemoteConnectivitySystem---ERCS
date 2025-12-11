import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class SendMessage extends StatefulWidget {
  const SendMessage({super.key});

  @override
  State<SendMessage> createState() => _SendMessageState();
}

class _SendMessageState extends State<SendMessage> {
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;

  /// שליחת הודעה עם טקסט ו־timestamp ל־Firebase Realtime Database
  Future<void> sendMessageToFirebase(String message) async {
    setState(() => _isSending = true);

    try {
      final DatabaseReference ref = FirebaseDatabase.instance.ref("messages");

      final newMessageRef = ref.push();
      await newMessageRef.set({
        'text': message,
        'timestamp': ServerValue.timestamp,
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("ההודעה נשלחה ל-Firebase")));
    } catch (e) {
      print("שגיאה בשליחה ל-Firebase: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("שגיאה בשליחה ל-Firebase")));
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("שלח הודעה ל-ESP32 דרך Firebase")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: "הקלד הודעה",
                border: OutlineInputBorder(),
              ),
              maxLines: null,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed:
                  _isSending
                      ? null
                      : () {
                        final message = _messageController.text.trim();
                        if (message.isNotEmpty) {
                          sendMessageToFirebase(message);
                          _messageController.clear();
                        }
                      },
              child:
                  _isSending
                      ? const CircularProgressIndicator()
                      : const Text("שלח ל-Firebase"),
            ),
          ],
        ),
      ),
    );
  }
}
