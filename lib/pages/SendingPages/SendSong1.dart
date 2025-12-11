// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:http/http.dart' as http;
// import 'package:path_provider/path_provider.dart';

// class SendSong extends StatefulWidget {
//   @override
//   _SendSongState createState() => _SendSongState();
// }

// class _SendSongState extends State<SendSong> {
//   String? selectedFilePath;
//   TextEditingController youtubeUrlController = TextEditingController();
//   bool isDownloading = false;

//   Future<void> pickMusicFile() async {
//     var status = await Permission.storage.request();
//     if (status.isGranted) {
//       FilePickerResult? result = await FilePicker.platform.pickFiles(
//         type: FileType.audio,
//       );

//       if (result != null) {
//         setState(() {
//           selectedFilePath = result.files.single.path;
//         });
//       }
//     } else {
//       print("הרשאה נדחתה");
//     }
//   }

//   Future<void> downloadFromYoutube(String url) async {
//     setState(() => isDownloading = true);

//     try {
//       // מדמה הורדת קובץ מיוטיוב - פה אמור להיות ממשק לשרת שמוריד את השיר
//       final response = await http.get(
//         Uri.parse("https://your-server.com/download?url=$url"),
//       );

//       if (response.statusCode == 200) {
//         final directory = await getApplicationDocumentsDirectory();
//         final filePath = '${directory.path}/downloaded_song.mp3';
//         final file = File(filePath);
//         await file.writeAsBytes(response.bodyBytes);

//         setState(() {
//           selectedFilePath = filePath;
//         });

//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text("ההורדה הצליחה")));
//       } else {
//         throw Exception("שגיאה בהורדה");
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text("ההורדה נכשלה: $e")));
//     }

//     setState(() => isDownloading = false);
//   }

//   Future<void> sendToESP32() async {
//     if (selectedFilePath == null) return;

//     final file = File(selectedFilePath!);
//     final uri = Uri.parse("http://esp32-ip-address/upload"); // שנה לכתובת שלך

//     final request = http.MultipartRequest('POST', uri)
//       ..files.add(await http.MultipartFile.fromPath('file', file.path));

//     final response = await request.send();

//     if (response.statusCode == 200) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text("הקובץ נשלח בהצלחה ל-ESP32")));
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("שליחה נכשלה: ${response.statusCode}")),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("שליחת שיר ל-ESP32")),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             ElevatedButton(
//               onPressed: pickMusicFile,
//               child: Text("בחר שיר מהמכשיר"),
//             ),
//             TextField(
//               controller: youtubeUrlController,
//               decoration: InputDecoration(labelText: "קישור ליוטיוב"),
//             ),
//             ElevatedButton(
//               onPressed:
//                   isDownloading
//                       ? null
//                       : () => downloadFromYoutube(youtubeUrlController.text),
//               child:
//                   isDownloading
//                       ? CircularProgressIndicator()
//                       : Text("הורד שיר מיוטיוב"),
//             ),
//             if (selectedFilePath != null)
//               Text("קובץ נבחר: ${selectedFilePath!.split('/').last}"),
//             SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: selectedFilePath == null ? null : sendToESP32,
//               child: Text("שלח ל-ESP32"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
