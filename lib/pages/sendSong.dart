import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Sendsong extends StatelessWidget {
  final String esp32Ip = "http://192.168.1.100";

  const Sendsong({super.key});  // כתובת ה-IP של ה-ESP32 ברשת

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

  void increaseVolume() async {
    final response = await http.get(Uri.parse('$esp32Ip/volume/up'));
    if (response.statusCode == 200) {
      print("הווליום הוגבר");
    } else {
      print("שגיאה בהגברת הווליום");
    }
  }

  void decreaseVolume() async {
    final response = await http.get(Uri.parse('$esp32Ip/volume/down'));
    if (response.statusCode == 200) {
      print("הווליום הומתק");
    } else {
      print("שגיאה בהורדת הווליום");
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
            ElevatedButton(
              onPressed: increaseVolume,
              child: Text("הגבר ווליום"),
            ),
            ElevatedButton(
              onPressed: decreaseVolume,
              child: Text("הורד ווליום"),
            ),
          ],
        ),
      ),
    );
  }
}
