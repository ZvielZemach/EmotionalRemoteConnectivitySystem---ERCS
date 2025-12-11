import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ControlPage extends StatelessWidget {
  final String esp32Ip = "http://192.168.1.100";

  const ControlPage({super.key});  // כתובת ה-IP של ה-ESP32 ברשת

  void playSong() async {
    final response = await http.get(Uri.parse('$esp32Ip/play'));
    if (response.statusCode == 200) {
      print("השיר התחיל להתנגן");
    } else {
      print("שגיאה בניגון השיר");
    }
  }

  void pauseSong() async {
    final response = await http.get(Uri.parse('$esp32Ip/pause'));
    if (response.statusCode == 200) {
      print("השיר נעצר");
    } else {
      print("שגיאה בהפסקת השיר");
    }
  }

  void nextSong() async {
    final response = await http.get(Uri.parse('$esp32Ip/next'));
    if (response.statusCode == 200) {
      print("נגינת השיר הבא");
    } else {
      print("שגיאה בניגון השיר הבא");
    }
  }

  void prevSong() async {
    final response = await http.get(Uri.parse('$esp32Ip/prev'));
    if (response.statusCode == 200) {
      print("נגינת השיר הקודם");
    } else {
      print("שגיאה בניגון השיר הקודם");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Control MP3 Player"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: playSong,
              child: Text("הפעל שיר"),
            ),
            ElevatedButton(
              onPressed: pauseSong,
              child: Text("עצור שיר"),
            ),
            ElevatedButton(
              onPressed: nextSong,
              child: Text("שיר הבא"),
            ),
            ElevatedButton(
              onPressed: prevSong,
              child: Text("שיר קודם"),
            ),
          ],
        ),
      ),
    );
  }
}
