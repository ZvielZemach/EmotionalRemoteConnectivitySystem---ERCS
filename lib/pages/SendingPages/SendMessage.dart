import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SendMessage extends StatefulWidget {
  const SendMessage({super.key});

  @override
  State<SendMessage> createState() => _SendMessageState();
}

class _ThemeColors {
  static const primary = Color(0xFF6200EE); // צבע סגול מודרני
  static const background = Color(0xFFF5F5F7);
}

class _SendMessageState extends State<SendMessage> {
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;

  /// שליחת הודעה עם טקסט ו־timestamp ל־Firebase Realtime Database
  Future<void> sendMessageToFirebase(String message) async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 10),
              Expanded(child: Text("Security error: You must be logged in.")),
            ],
          ),
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final DatabaseReference ref = FirebaseDatabase.instance.ref("messages");
      final newMessageRef = ref.push();

      await newMessageRef.set({
        'text': message,
        'timestamp': ServerValue.timestamp,
        'senderId': currentUser.uid,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text("The message succesfuly sent to - my love 🎉"),
              ),
            ],
          ),
        ),
      );
      _messageController.clear();
    } catch (e) {
      print("Error in sending message procces $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          content: const Text("Error sending: Incorrect permissions"),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ThemeColors.background,
      appBar: AppBar(
        title: const Text(
          "Sendin message page",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
      ),
      body: GestureDetector(
        onTap:
            () =>
                FocusScope.of(
                  context,
                ).unfocus(), // סגירת המקלדת בלחיצה על המסך החלק
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: _ThemeColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.text_fields_rounded,
                  size: 60,
                  color: _ThemeColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "What message would you like to present on the screen?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600, // תוקן מ-w640 ל-w600 קומפילטיבי
                  color: Colors.black87, // תוקן מ-blackDE ל-black87
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "The message you will send will arrive to the ESP32 and be presented on the TFT screen",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 32),

              // כרטיס המכיל את שדה הקלט
              Card(
                elevation: 4,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    controller: _messageController,
                    maxLines: 4,
                    minLines: 2,
                    keyboardType: TextInputType.multiline,
                    style: const TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      hintText: "Write here your message in English...",
                      alignLabelWithHint: true,
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 40),
                        child: Icon(
                          Icons.chat_bubble_outline,
                          color: _ThemeColors.primary,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // כפתור שליחה מעוצב ומודרני
              ElevatedButton.icon(
                onPressed:
                    _isSending
                        ? null
                        : () {
                          final message = _messageController.text.trim();
                          if (message.isNotEmpty) {
                            sendMessageToFirebase(message);
                          }
                        },
                icon:
                    _isSending
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : const Icon(Icons.send_rounded, color: Colors.white),
                label: Text(
                  _isSending ? "Sending now..." : "Send message",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _ThemeColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  shadowColor: _ThemeColors.primary.withOpacity(0.3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
