import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:my_app/pages/SendingPages/SendMessage.dart';
import 'package:my_app/pages/SendingPages/SendPhoto.dart';
import 'package:my_app/pages/SendingPages/Sendsong2.dart';

class Selectionpage extends StatefulWidget {
  const Selectionpage({super.key, required this.userType, required this.name});

  final String userType;
  final String name;

  @override
  State<StatefulWidget> createState() => _SelectionPageState();
}

class _SelectionPageState extends State<Selectionpage> {
  @override
  Widget build(BuildContext context) {
    final String cleanName = widget.name.trim().toLowerCase();
    final String cleanUserType = widget.userType.trim().toLowerCase();
    final bool isHadarUser =
        cleanName == "hadar cohen" || cleanUserType == "hadar";

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          "Hello ${widget.userType}",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            shadows: [
              Shadow(
                color: Colors.black45,
                blurRadius: 4,
                offset: Offset(1, 2),
              ),
            ],
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              isHadarUser
                  ? "assets/Zviel.jpeg"
                  : "assets/Hadar_Funney_Face.jpeg",
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  // This anchors your container precisely slightly below the center
                  // (0.0 is center, 1.0 is bottom. 0.4 is perfect for being a bit lower)
                  Align(
                    alignment: const Alignment(0, 0.4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            width:
                                constraints.maxWidth > 600
                                    ? 450
                                    : double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.25),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.favorite,
                                  color: Colors.pinkAccent,
                                  size: 40,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  "What would you like to send to your love?",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 32),

                                // Menu Action Buttons
                                _buildMenuButton(
                                  context: context,
                                  label: "Send Message",
                                  icon: Icons.chat_bubble_rounded,
                                  colors: [
                                    Colors.purpleAccent.shade200,
                                    Colors.indigoAccent.shade200,
                                  ],
                                  onTap:
                                      () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => SendMessage(),
                                        ),
                                      ),
                                ),
                                const SizedBox(height: 16),
                                _buildMenuButton(
                                  context: context,
                                  label: "Send Photo",
                                  icon: Icons.camera_alt_rounded,
                                  colors: [
                                    Colors.pinkAccent.shade200,
                                    Colors.orangeAccent.shade200,
                                  ],
                                  onTap:
                                      () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => Sendphoto(),
                                        ),
                                      ),
                                ),
                                const SizedBox(height: 16),
                                _buildMenuButton(
                                  context: context,
                                  label: "Send Song",
                                  icon: Icons.music_note_rounded,
                                  colors: [
                                    Colors.cyanAccent.shade700,
                                    Colors.tealAccent.shade700,
                                  ],
                                  onTap:
                                      () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => SendSong(),
                                        ),
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: colors.first.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 26),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white70,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
