import 'package:flutter/material.dart';
import 'dart:ui'; // Required for BackdropFilter blur
import 'package:firebase_auth/firebase_auth.dart'; // Added Firebase Auth import
import 'package:my_app/pages/SelectionPage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _formkey = GlobalKey<FormState>();
  var name = '';
  var password = '';
  var user = '';
  String message = '';

  Future<void> _checkUser() async {
    final valid = _formkey.currentState!.validate();
    if (!valid) return;

    _formkey.currentState!.save();

    // 1. Show a loading indicator while Firebase processes the login
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const Center(
            child: CircularProgressIndicator(
              color: Color.fromARGB(255, 229, 118, 248),
            ),
          ),
    );

    try {
      // 2. Format name to an email style for Firebase Auth backend compatibility
      // Example: "Hadar cohen" becomes "hadar.cohen@app.com"
      String formattedEmail =
          "${name.trim().toLowerCase().replaceAll(' ', '.')}@app.com";

      // 3. Attempt Firebase Sign-In
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: formattedEmail,
            password: password,
          );

      // Close the loading dialog upon success
      if (mounted) Navigator.of(context).pop();

      // 4. Update the local state for your custom romantic message logic
      setState(() {
        user = name.trim();
        if (user.toLowerCase().contains('hadar')) {
          message =
              "Hello my darling, did I tell you how much I love you today?\n"
              "If not, so I want you to know that you are the love of my life!, "
              "and since I met you I became the happiest person in all over the world";
        } else {
          message = "Hi Tzviel";
        }
      });

      // 5. Navigate to the SelectionPage with secure Firebase clearance
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => Selectionpage(userType: user, name: name),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      // Close the loading dialog upon failure
      if (mounted) Navigator.of(context).pop();

      // Handle Firebase Errors elegantly
      String errorText = "שגיאת התחברות";
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        errorText = "שם משתמש או סיסמה שגויים";
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text(
              errorText,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF141419), // Deep premium canvas color
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Stack(
        children: [
          // LAYER 1: The Pinned-Top Foreground Image
          Container(
            width: screenSize.width,
            height: screenSize.height * 0.75,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/Hadar&Tzviel.jpg"),
                fit: BoxFit.contain,
                alignment: Alignment.topCenter,
              ),
            ),
          ),

          // Subtle vignette gradient fading from the image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenSize.height * 0.60,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.15),
                    Colors.transparent,
                    const Color(0xFF141419).withOpacity(0.8),
                    const Color(0xFF141419),
                  ],
                  stops: const [0.0, 0.4, 0.85, 1.0],
                ),
              ),
            ),
          ),

          // LAYER 2: Greeting text
          Positioned(
            top: screenSize.height * 0.45,
            left: 0,
            right: 0,
            child: const Center(
              child: Text(
                "Hello & Good Morning",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.8,
                  shadows: [
                    Shadow(
                      blurRadius: 6,
                      color: Colors.black87,
                      offset: Offset(1, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // LAYER 3: Sign-in Card
          Container(
            width: screenSize.width,
            height: screenSize.height,
            alignment: const Alignment(0.0, 0.90),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isTablet = screenSize.width > 480;
                    final cardWidth = isTablet ? 420.0 : double.infinity;

                    return SizedBox(
                      width: cardWidth,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.15),
                                width: 1.2,
                              ),
                            ),
                            child: Form(
                              key: _formkey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    "Welcome Back",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Please enter your details to continue",
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // --- NAME FIELD ---
                                  TextFormField(
                                    maxLength: 50,
                                    style: const TextStyle(color: Colors.white),
                                    cursorColor: Colors.white,
                                    decoration: InputDecoration(
                                      counterText: "",
                                      labelText: 'Name',
                                      labelStyle: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.person_outline,
                                        color: Colors.white70,
                                      ),
                                      filled: true,
                                      fillColor: Colors.black.withOpacity(0.25),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(
                                          color: Colors.white70,
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty ||
                                          value.trim().length <= 1) {
                                        return 'Please enter a valid name';
                                      }
                                      return null;
                                    },
                                    onSaved: (value) {
                                      setState(() {
                                        name = value!;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  // --- PASSWORD FIELD ---
                                  TextFormField(
                                    maxLength: 10,
                                    obscureText: true,
                                    style: const TextStyle(color: Colors.white),
                                    cursorColor: Colors.white,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      counterText: "",
                                      labelText: 'Password',
                                      labelStyle: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                      hintText: 'Enter your phone number',
                                      hintStyle: const TextStyle(
                                        color: Colors.white30,
                                        fontSize: 13,
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.lock_outline,
                                        color: Colors.white70,
                                      ),
                                      filled: true,
                                      fillColor: Colors.black.withOpacity(0.25),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(
                                          color: Colors.white70,
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Enter your password';
                                      }
                                      return null;
                                    },
                                    onSaved: (newValue) {
                                      setState(() {
                                        password = newValue!;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 26),

                                  // --- GRADIENT ENTER BUTTON ---
                                  InkWell(
                                    onTap: _checkUser,
                                    borderRadius: BorderRadius.circular(16),
                                    child: Ink(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color.fromARGB(255, 135, 210, 248),
                                            Color.fromARGB(255, 229, 118, 248),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color.fromARGB(
                                              255,
                                              229,
                                              118,
                                              248,
                                            ).withOpacity(0.3),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Container(
                                        height: 52,
                                        width: double.infinity,
                                        alignment: Alignment.center,
                                        child: const Text(
                                          'Enter',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
