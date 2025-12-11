import 'package:flutter/material.dart';
import 'package:my_app/pages/SendingPages/SendMessage.dart';
import 'package:my_app/pages/SendingPages/SendSong1.dart';
import 'package:my_app/pages/SendingPages/SendPhoto.dart';
import 'package:my_app/pages/SendingPages/Sendsong2.dart';

class Selectionpage extends StatefulWidget {
  const Selectionpage({super.key, required this.userType, required this.name});

  final String userType;
  final String name;
  @override
  State<StatefulWidget> createState() {
    return _SelectionPageState();
  }
}

class _SelectionPageState extends State<Selectionpage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Hello ${widget.userType}",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              widget.name ==
                      "Tzviel tzemach" // check why doesnt work
                  ? "assets/Hadar_funney_Face.jpeg"
                  : "assets/Zviel.jpeg",
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: Checkbox.width,
              children: [
                Text(
                  "What would you like to send to your love?",
                  style: TextStyle(color: Colors.black87),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SendMessage()),
                    );
                  },
                  child: Text(
                    "Send Message",
                    style: TextStyle(color: Colors.black87),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Sendphoto()),
                    );
                  },
                  child: Text(
                    "Send photo",
                    style: TextStyle(color: Colors.black87),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SendSong()),
                    );
                  },
                  child: Text(
                    "Send song",
                    style: TextStyle(color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
