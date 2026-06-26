// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:just_audio/just_audio.dart';
// import 'package:http/http.dart' as http;
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:firebase_auth/firebase_auth.dart'; // Added for Authentication check

// class SendSong extends StatefulWidget {
//   const SendSong({super.key});

//   @override
//   State<SendSong> createState() => _SendSongState();
// }

// class _SendSongState extends State<SendSong> {
//   String? selectedFilePath;
//   String? selectedFileName;
//   bool isSending = false;
//   TextEditingController youtubeController = TextEditingController();
//   List<File> downloadedSongs = [];
//   late AudioPlayer _audioPlayer;
//   File? currentlyPlayingFile;

//   @override
//   void initState() {
//     super.initState();
//     _audioPlayer = AudioPlayer();
//     _loadDownloadedSongs();
//   }

//   @override
//   void dispose() {
//     _audioPlayer.dispose();
//     youtubeController.dispose();
//     super.dispose();
//   }

//   Future<Directory> _getAudioDirectory() async {
//     final dir = Directory("/storage/emulated/0/Download/my_songs");
//     if (!await dir.exists()) await dir.create(recursive: true);
//     return dir;
//   }

//   Future<void> _loadDownloadedSongs() async {
//     if (Platform.isAndroid &&
//         !await Permission.manageExternalStorage.request().isGranted) {
//       return;
//     }
//     final dir = await _getAudioDirectory();
//     final files =
//         dir
//             .listSync()
//             .whereType<File>()
//             .where((f) => f.path.endsWith('.mp3'))
//             .toList();
//     setState(() => downloadedSongs = files);
//   }

//   Future<void> _pickMusicFromFolder() async {
//     if (downloadedSongs.isEmpty) {
//       _showMessage("אין שירים זמינים בתיקייה");
//       return;
//     }
//     showModalBottomSheet(
//       context: context,
//       builder:
//           (_) => ListView.builder(
//             itemCount: downloadedSongs.length,
//             itemBuilder: (_, index) {
//               final file = downloadedSongs[index];
//               return ListTile(
//                 title: Text(file.path.split('/').last),
//                 onTap: () {
//                   setState(() {
//                     selectedFilePath = file.path;
//                     selectedFileName = file.path.split('/').last;
//                   });
//                   Navigator.pop(context);
//                 },
//               );
//             },
//           ),
//     );
//   }

//   Future<void> _pickMusicFromDevice() async {
//     final result = await FilePicker.platform.pickFiles(type: FileType.audio);
//     if (result?.files.single.path != null) {
//       setState(() {
//         selectedFilePath = result!.files.single.path!;
//         selectedFileName = result.files.single.name;
//       });
//     }
//   }

//   Future<void> _sendSongToFirebase() async {
//     if (selectedFilePath == null) return;

//     // Guard against unauthenticated execution
//     if (FirebaseAuth.instance.currentUser == null) {
//       _showMessage("שגיאת אבטחה: עליך להיות מחובר כדי להעלות שירים");
//       return;
//     }

//     final song = File(selectedFilePath!);
//     final size = await song.length();
//     if (size > 10 * 1024 * 1024) {
//       _showMessage("קובץ גדול מ-10MB, לא ניתן להעלות");
//       return;
//     }

//     final fileName = selectedFileName ?? song.path.split('/').last;
//     final ref = FirebaseStorage.instance.ref("songs/$fileName");

//     try {
//       // העלה ל-Storage
//       await ref.putFile(song);

//       // קבל את ה-URL וכתוב ל-Realtime Database
//       final downloadUrl = await ref.getDownloadURL();
//       await FirebaseDatabase.instance.ref("esp32/audio_url").set(downloadUrl);

//       _showMessage("השיר עלה בהצלחה ונשלח ל-ESP32!");
//     } catch (e) {
//       print("Upload error: $e");
//       _showMessage("נכשלה העלאת השיר: חוסר בהרשאות אבטחה בשרת");
//     }
//   }

//   bool _isValidYouTubeUrl(String url) {
//     final uri = Uri.tryParse(url);
//     return uri != null &&
//         uri.hasAbsolutePath &&
//         (uri.host.contains('youtube.com') || uri.host.contains('youtu.be'));
//   }

//   Future<void> _saveYouTubeSong() async {
//     final url = youtubeController.text.trim();
//     if (!_isValidYouTubeUrl(url)) {
//       _showMessage("קישור יוטיוב לא תקין");
//       return;
//     }

//     // Security practice: verify authorization status even if dealing with your local download proxy
//     if (FirebaseAuth.instance.currentUser == null) {
//       _showMessage("פעולה נדחתה: משתמשים לא רשומים אינם רשאים להוריד שירים");
//       return;
//     }

//     try {
//       final response = await http.post(
//         Uri.parse("http://5.102.238.242:3000/download-youtube"),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({"youtubeUrl": url}),
//       );
//       if (response.statusCode == 200) {
//         await _loadDownloadedSongs();
//         youtubeController.clear();
//         _showMessage("השיר הורד ונשמר בהצלחה");
//       } else {
//         _showMessage("שגיאה בשרת");
//       }
//     } catch (e) {
//       print("Download error: $e");
//       _showMessage("הורדה נכשלה, נסה שוב מאוחר יותר");
//     }
//   }

//   void _openYouTube() async {
//     final url = Uri.parse("https://www.youtube.com/");
//     if (await canLaunchUrl(url)) {
//       await launchUrl(url, mode: LaunchMode.externalApplication);
//     } else {
//       _showMessage("לא ניתן לפתוח את YouTube");
//     }
//   }

//   Future<void> _playOrStopSong(File song) async {
//     if (currentlyPlayingFile == song) {
//       await _audioPlayer.stop();
//       setState(() => currentlyPlayingFile = null);
//     } else {
//       await _audioPlayer.setFilePath(song.path);
//       await _audioPlayer.play();
//       setState(() => currentlyPlayingFile = song);
//     }
//   }

//   Future<void> _deleteSong(File song) async {
//     try {
//       await song.delete();
//       await _loadDownloadedSongs();
//       _showMessage("השיר נמחק");
//     } catch (e) {
//       print("Delete error: $e");
//     }
//   }

//   void _showMessage(String message) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(SnackBar(content: Text(message)));
//   }

//   Widget _buildSongList() {
//     if (downloadedSongs.isEmpty) {
//       return const Text("אין שירים בתיקייה");
//     }
//     return ListView.builder(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       itemCount: downloadedSongs.length,
//       itemBuilder: (_, index) {
//         final song = downloadedSongs[index];
//         final isPlaying = currentlyPlayingFile == song;
//         return ListTile(
//           title: Text(song.path.split('/').last),
//           trailing: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               IconButton(
//                 icon: AnimatedSwitcher(
//                   duration: const Duration(milliseconds: 300),
//                   child: Icon(
//                     isPlaying ? Icons.stop : Icons.play_arrow,
//                     key: ValueKey(isPlaying),
//                   ),
//                 ),
//                 onPressed: () => _playOrStopSong(song),
//               ),
//               IconButton(
//                 icon: const Icon(Icons.delete),
//                 onPressed: () => _deleteSong(song),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("שליחת שיר ל-Firebase")),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             AnimatedSwitcher(
//               duration: const Duration(milliseconds: 300),
//               child:
//                   selectedFileName == null
//                       ? const Text("\u2022 לא נבחר שיר")
//                       : Text(
//                         "\u2022 שיר נבחר: $selectedFileName",
//                         key: ValueKey(selectedFileName),
//                         style: const TextStyle(fontWeight: FontWeight.bold),
//                       ),
//             ),
//             const SizedBox(height: 10),
//             ElevatedButton(
//               onPressed: _pickMusicFromFolder,
//               child: const Text("בחר שיר מתיקיית my_songs"),
//             ),
//             ElevatedButton(
//               onPressed: _pickMusicFromDevice,
//               child: const Text("בחר שיר מהגלריה הכללית"),
//             ),
//             ElevatedButton(
//               onPressed: selectedFilePath == null ? null : _sendSongToFirebase,
//               child: const Text("שלח שיר ל-Firebase"),
//             ),
//             const Divider(height: 30),
//             ElevatedButton(
//               onPressed: _openYouTube,
//               child: const Text("פתח YouTube"),
//             ),
//             const SizedBox(height: 8),
//             TextField(
//               controller: youtubeController,
//               decoration: const InputDecoration(
//                 labelText: "קישור לשיר ביוטיוב",
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 8),
//             ElevatedButton(
//               onPressed: _saveYouTubeSong,
//               child: const Text("הורד ושמור שיר מהיוטיוב"),
//             ),
//             const Divider(height: 30),
//             const Text(
//               "\u2022 שירים שהורדו",
//               style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//             ),
//             const SizedBox(height: 10),
//             _buildSongList(),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

// מחלקת צבעי ה-Theme המשותפת לפרויקט הגמר שלך
class _ThemeColors {
  static const primary = Color(0xFF6200EE); // סגול מודרני יוקרתי
  static const background = Color(0xFFF5F5F7); // רקע אפור בהיר ונקי
  static const cardBackground = Colors.white;
}

class SendSong extends StatefulWidget {
  const SendSong({super.key});

  @override
  State<SendSong> createState() => _SendSongState();
}

class _SendSongState extends State<SendSong> {
  String? selectedFilePath;
  String? selectedFileName;
  bool isSending = false;
  bool isDownloading = false; // אינדיקטור להורדה מיוטיוב
  TextEditingController youtubeController = TextEditingController();
  List<File> downloadedSongs = [];
  late AudioPlayer _audioPlayer;
  File? currentlyPlayingFile;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _loadDownloadedSongs();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    youtubeController.dispose();
    super.dispose();
  }

  Future<Directory> _getAudioDirectory() async {
    final dir = Directory("/storage/emulated/0/Download/my_songs");
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<void> _loadDownloadedSongs() async {
    if (Platform.isAndroid &&
        !await Permission.manageExternalStorage.request().isGranted) {
      return;
    }
    final dir = await _getAudioDirectory();
    final files =
        dir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.mp3'))
            .toList();
    setState(() => downloadedSongs = files);
  }

  Future<void> _pickMusicFromFolder() async {
    if (downloadedSongs.isEmpty) {
      _showCustomSnackBar("אין שירים זמינים בתיקייה", isError: true);
      return;
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: _ThemeColors.cardBackground,
      builder:
          (_) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  "בחר שיר מתיקיית האפליקציה",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: downloadedSongs.length,
                    itemBuilder: (_, index) {
                      final file = downloadedSongs[index];
                      return ListTile(
                        leading: const Icon(
                          Icons.audiotrack,
                          color: _ThemeColors.primary,
                        ),
                        title: Text(
                          file.path.split('/').last,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          setState(() {
                            selectedFilePath = file.path;
                            selectedFileName = file.path.split('/').last;
                          });
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _pickMusicFromDevice() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result?.files.single.path != null) {
      setState(() {
        selectedFilePath = result!.files.single.path!;
        selectedFileName = result.files.single.name;
      });
    }
  }

  Future<void> _sendSongToFirebase() async {
    if (selectedFilePath == null) return;

    if (FirebaseAuth.instance.currentUser == null) {
      _showCustomSnackBar(
        "שגיאת אבטחה: עליך להיות מחובר כדי להעלות שירים",
        isError: true,
      );
      return;
    }

    setState(() => isSending = true);

    final song = File(selectedFilePath!);
    final size = await song.length();
    if (size > 10 * 1024 * 1024) {
      setState(() => isSending = false);
      _showCustomSnackBar("קובץ גדול מ-10MB, לא ניתן להעלות", isError: true);
      return;
    }

    final fileName = selectedFileName ?? song.path.split('/').last;
    final ref = FirebaseStorage.instance.ref("songs/$fileName");

    try {
      await ref.putFile(song);
      final downloadUrl = await ref.getDownloadURL();
      await FirebaseDatabase.instance.ref("esp32/audio_url").set(downloadUrl);

      _showCustomSnackBar("השיר עלה בהצלחה ונשלח ל-ESP32! 🎉", isError: false);
      setState(() {
        selectedFilePath = null;
        selectedFileName = null;
      });
    } catch (e) {
      print("Upload error: $e");
      _showCustomSnackBar(
        "נכשלה העלאת השיר: חוסר בהרשאות אבטחה בשרת",
        isError: true,
      );
    } finally {
      setState(() => isSending = false);
    }
  }

  bool _isValidYouTubeUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null &&
        uri.hasAbsolutePath &&
        (uri.host.contains('youtube.com') || uri.host.contains('youtu.be'));
  }

  Future<void> _saveYouTubeSong() async {
    final url = youtubeController.text.trim();
    if (!_isValidYouTubeUrl(url)) {
      _showCustomSnackBar("קישור יוטיוב לא תקין", isError: true);
      return;
    }

    if (FirebaseAuth.instance.currentUser == null) {
      _showCustomSnackBar(
        "פעולה נדחתה: משתמשים לא רשומים אינם רשאים להוריד שירים",
        isError: true,
      );
      return;
    }

    setState(() => isDownloading = true);

    try {
      final response = await http.post(
        Uri.parse("http://5.102.238.242:3000/download-youtube"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"youtubeUrl": url}),
      );
      if (response.statusCode == 200) {
        await _loadDownloadedSongs();
        youtubeController.clear();
        _showCustomSnackBar("השיר הורד ונשמר בהצלחה 🎵", isError: false);
      } else {
        _showCustomSnackBar("שגיאה בהורדה משרת ה-Proxy", isError: true);
      }
    } catch (e) {
      print("Download error: $e");
      _showCustomSnackBar("הורדה נכשלה, נסה שוב מאוחר יותר", isError: true);
    } finally {
      setState(() => isDownloading = false);
    }
  }

  void _openYouTube() async {
    final url = Uri.parse("https://www.youtube.com/");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _showCustomSnackBar("לא ניתן לפתוח את YouTube", isError: true);
    }
  }

  Future<void> _playOrStopSong(File song) async {
    if (currentlyPlayingFile == song) {
      await _audioPlayer.stop();
      setState(() => currentlyPlayingFile = null);
    } else {
      await _audioPlayer.setFilePath(song.path);
      await _audioPlayer.play();
      setState(() => currentlyPlayingFile = song);

      // האזנה לסיום השיר באופן אוטומטי
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          if (mounted) {
            setState(() => currentlyPlayingFile = null);
          }
        }
      });
    }
  }

  Future<void> _deleteSong(File song) async {
    try {
      if (currentlyPlayingFile == song) {
        await _audioPlayer.stop();
        currentlyPlayingFile = null;
      }
      await song.delete();
      await _loadDownloadedSongs();
      _showCustomSnackBar("השיר נמחק מהמכשיר", isError: false);
    } catch (e) {
      print("Delete error: $e");
      _showCustomSnackBar("שגיאה במחיקת הקובץ", isError: true);
    }
  }

  void _showCustomSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongList() {
    if (downloadedSongs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            "אין שירים בתיקייה המקומית",
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
          ),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: downloadedSongs.length,
      itemBuilder: (_, index) {
        final song = downloadedSongs[index];
        final isPlaying = currentlyPlayingFile == song;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  isPlaying
                      ? _ThemeColors.primary.withOpacity(0.1)
                      : Colors.grey[100],
              child: Icon(
                isPlaying ? Icons.music_note : Icons.audiotrack_outlined,
                color: isPlaying ? _ThemeColors.primary : Colors.grey[600],
              ),
            ),
            title: Text(
              song.path.split('/').last,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      isPlaying ? Icons.stop_circle : Icons.play_circle_fill,
                      color:
                          isPlaying ? Colors.redAccent : _ThemeColors.primary,
                      size: 28,
                      key: ValueKey(isPlaying),
                    ),
                  ),
                  onPressed: () => _playOrStopSong(song),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.grey),
                  onPressed: () => _deleteSong(song),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ThemeColors.background,
      appBar: AppBar(
        title: const Text(
          "שליחת שיר ל-ESP32",
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
                ).unfocus(), // סגירת המקלדת בנגיעה ברקע החלק
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // כרטיס מקטע 1: העלאה וניהול קבצים מקומיים
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: _ThemeColors.cardBackground,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            color: _ThemeColors.primary,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "בחירה והעלאת קובץ שיר",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 25),

                      // תצוגת השיר הנבחר כרגע עם אנימציית החלפה
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child:
                            selectedFileName == null
                                ? Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: Colors.amber,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        "טרם נבחר קובץ מוזיקה להעלאה",
                                        style: TextStyle(color: Colors.black54),
                                      ),
                                    ],
                                  ),
                                )
                                : Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _ThemeColors.primary.withOpacity(
                                      0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _ThemeColors.primary.withOpacity(
                                        0.3,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          "שיר נבחר: $selectedFileName",
                                          key: ValueKey(selectedFileName),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: _ThemeColors.primary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                      ),
                      const SizedBox(height: 16),

                      ElevatedButton.icon(
                        icon: const Icon(Icons.folder_open_outlined),
                        label: const Text("בחר שיר מתיקיית my_songs"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: _ThemeColors.primary,
                          side: const BorderSide(color: _ThemeColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: isSending ? null : _pickMusicFromFolder,
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.phone_android_outlined),
                        label: const Text("בחר שיר מהגלריה הכללית"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: _ThemeColors.primary,
                          side: const BorderSide(color: _ThemeColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: isSending ? null : _pickMusicFromDevice,
                      ),
                      const SizedBox(height: 16),

                      ElevatedButton.icon(
                        icon:
                            isSending
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Icon(Icons.send_rounded),
                        label: Text(
                          isSending ? "מעלה לשרת..." : "שלח שיר ל-Firebase",
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _ThemeColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[300],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 2,
                        ),
                        onPressed:
                            (selectedFilePath == null || isSending)
                                ? null
                                : _sendSongToFirebase,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // כרטיס מקטע 2: הורדה ועבודה מול יוטיוב
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: _ThemeColors.cardBackground,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.video_library_outlined,
                                  color: Colors.redAccent,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Download songs from youTube",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize:
                                          14, // increased font size since we have space now
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            icon: const Icon(
                              Icons.open_in_new,
                              size: 16,
                              color: Colors.redAccent,
                            ),
                            label: const Text(
                              "פתח אפליקציה",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.redAccent,
                              ),
                            ),
                            onPressed: _openYouTube,
                          ),
                        ],
                      ),
                      const Divider(height: 15),
                      const SizedBox(height: 8),
                      TextField(
                        controller: youtubeController,
                        decoration: InputDecoration(
                          labelText: "הדבק כאן קישור לשיר ביוטיוב",
                          labelStyle: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.link,
                            color: Colors.redAccent,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.redAccent,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        icon:
                            isDownloading
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Icon(Icons.download_rounded),
                        label: Text(
                          isDownloading
                              ? "מוריד וממיר ל-MP3..."
                              : "הורד ושמור שיר מהיוטיוב",
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: isDownloading ? null : _saveYouTubeSong,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // כרטיס מקטע 3: כותרת ורשימת השירים שהורדו במכשיר
              const Row(
                children: [
                  Icon(
                    Icons.library_music_outlined,
                    color: Colors.black87,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "שירים שמורים במכשיר",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildSongList(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:just_audio/just_audio.dart';
// import 'package:http/http.dart' as http;
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class SendSong extends StatefulWidget {
//   const SendSong({super.key});

//   @override
//   State<SendSong> createState() => _SendSongState();
// }

// class _SendSongState extends State<SendSong> {
//   String? selectedFilePath;
//   String? selectedFileName;
//   bool isSending = false;
//   bool isDownloading = false; // חיווי ויזואלי להורדה מהיוטיוב
//   TextEditingController youtubeController = TextEditingController();
//   List<File> downloadedSongs = [];
//   late AudioPlayer _audioPlayer;
//   File? currentlyPlayingFile;

//   @override
//   void initState() {
//     super.initState();
//     _audioPlayer = AudioPlayer();
//     _loadDownloadedSongs();
//   }

//   @override
//   void dispose() {
//     _audioPlayer.dispose();
//     youtubeController.dispose();
//     super.dispose();
//   }

//   /// קבלת נתיב תיקייה חוקי ומאובטח באנדרואיד (בתוך מסמכי האפליקציה)
//   Future<Directory> _getAudioDirectory() async {
//     final baseDir = await getApplicationDocumentsDirectory();
//     final dir = Directory("${baseDir.path}/my_songs");
//     if (!await dir.exists()) {
//       await dir.create(recursive: true);
//     }
//     return dir;
//   }

//   /// טעינת השירים הקיימים מהתיקייה המקומית
//   Future<void> _loadDownloadedSongs() async {
//     try {
//       final dir = await _getAudioDirectory();
//       final files =
//           dir
//               .listSync()
//               .whereType<File>()
//               .where((f) => f.path.endsWith('.mp3'))
//               .toList();
//       setState(() => downloadedSongs = files);
//     } catch (e) {
//       print("Error loading songs: $e");
//     }
//   }

//   /// בחירת שיר מתוך רשימת השירים שהורדו מיוטיוב
//   Future<void> _pickMusicFromFolder() async {
//     if (downloadedSongs.isEmpty) {
//       _showMessage("אין שירים זמינים בתיקיית my_songs");
//       return;
//     }
//     showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder:
//           (_) => Container(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const Text(
//                   "בחר שיר מתיקיית ההורדות",
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//                 const Divider(),
//                 Expanded(
//                   child: ListView.builder(
//                     itemCount: downloadedSongs.length,
//                     itemBuilder: (_, index) {
//                       final file = downloadedSongs[index];
//                       final name = file.path.split('/').last;
//                       return ListTile(
//                         leading: const Icon(
//                           Icons.music_note,
//                           color: Colors.blue,
//                         ),
//                         title: Text(name),
//                         onTap: () {
//                           setState(() {
//                             selectedFilePath = file.path;
//                             selectedFileName = name;
//                           });
//                           Navigator.pop(context);
//                         },
//                       );
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           ),
//     );
//   }

//   /// בחירת קובץ מכל מקום אחר במכשיר
//   Future<void> _pickMusicFromDevice() async {
//     final result = await FilePicker.platform.pickFiles(type: FileType.audio);
//     if (result?.files.single.path != null) {
//       setState(() {
//         selectedFilePath = result!.files.single.path!;
//         selectedFileName = result.files.single.name;
//       });
//     }
//   }

//   /// העלאת השיר הנבחר ל-Firebase והודעה ל-ESP32
//   Future<void> _sendSongToFirebase() async {
//     if (selectedFilePath == null) return;

//     if (FirebaseAuth.instance.currentUser == null) {
//       _showMessage("שגיאת אבטחה: עליך להיות מחובר כדי להעלות שירים");
//       return;
//     }

//     setState(() => isSending = true);

//     final song = File(selectedFilePath!);
//     final size = await song.length();

//     if (size > 15 * 1024 * 1024) {
//       // הגדלה קלה ל-15MB ליתר ביטחון עבור שירים ארוכים
//       _showMessage("קובץ גדול מדי, לא ניתן להעלות");
//       setState(() => isSending = false);
//       return;
//     }

//     final fileName = selectedFileName ?? song.path.split('/').last;
//     final ref = FirebaseStorage.instance.ref("songs/$fileName");

//     try {
//       _showMessage("מעלה קובץ לשרת, אנא המתן...");
//       await ref.putFile(song);

//       final downloadUrl = await ref.getDownloadURL();
//       await FirebaseDatabase.instance.ref("esp32/audio_url").set(downloadUrl);

//       _showMessage("השיר עלה בהצלחה ונשלח ל-ESP32! 🎉");
//       setState(() {
//         selectedFilePath = null;
//         selectedFileName = null;
//       });
//     } catch (e) {
//       print("Upload error: $e");
//       _showMessage("נכשלה העלאת השיר: בדוק חיבור לרשת או הרשאות שרת");
//     } finally {
//       setState(() => isSending = false);
//     }
//   }

//   bool _isValidYouTubeUrl(String url) {
//     final uri = Uri.tryParse(url);
//     return uri != null &&
//         uri.hasAbsolutePath &&
//         (uri.host.contains('youtube.com') || uri.host.contains('youtu.be'));
//   }

//   /// הורדת השיר משרת ה-Proxy ושמירתו הפיזית במכשיר
//   Future<void> _saveYouTubeSong() async {
//     final url = youtubeController.text.trim();
//     if (!_isValidYouTubeUrl(url)) {
//       _showMessage("קישור יוטיוב לא תקין");
//       return;
//     }

//     if (FirebaseAuth.instance.currentUser == null) {
//       _showMessage("פעולה נדחתה: משתמשים לא רשומים אינם רשאים להוריד שירים");
//       return;
//     }

//     setState(() => isDownloading = true);
//     _showMessage("השרת מעבד ומוריד את השיר מיוטיוב, אנא המתן...");

//     try {
//       final response = await http
//           .post(
//             Uri.parse("http://5.102.238.242:3000/download-youtube"),
//             headers: {'Content-Type': 'application/json'},
//             body: jsonEncode({"youtubeUrl": url}),
//           )
//           .timeout(
//             const Duration(minutes: 2),
//           ); // הוספת Timeout כי המרה לוקחת זמן

//       if (response.statusCode == 200) {
//         final dir = await _getAudioDirectory();

//         // יצירת שם קובץ ייחודי מבוסס זמן הנוכחי כדי שלא יידרסו קבצים
//         final timestamp = DateTime.now().millisecondsSinceEpoch;
//         final fileSavePath = "${dir.path}/youtube_$timestamp.mp3";

//         final file = File(fileSavePath);

//         // שמירת ה-Bytes שחזרו מהשרת ישירות לתוך קובץ ה-MP3 במכשיר החכם!
//         await file.writeAsBytes(response.bodyBytes);

//         await _loadDownloadedSongs();
//         youtubeController.clear();
//         _showMessage("🎵 השיר הורד ונשמר בהצלחה בתיקיית האפליקציה!");
//       } else {
//         _showMessage("שגיאה בקוד השרת המרוחק (${response.statusCode})");
//       }
//     } catch (e) {
//       print("Download error: $e");
//       _showMessage("ההורדה נכשלה. ודא שהשרת המרוחק שלך דלוק ומגיב.");
//     } finally {
//       setState(() => isDownloading = false);
//     }
//   }

//   void _openYouTube() async {
//     final url = Uri.parse("https://www.youtube.com/");
//     if (await canLaunchUrl(url)) {
//       await launchUrl(url, mode: LaunchMode.externalApplication);
//     } else {
//       _showMessage("לא ניתן לפתוח את YouTube");
//     }
//   }

//   Future<void> _playOrStopSong(File song) async {
//     if (currentlyPlayingFile == song) {
//       await _audioPlayer.stop();
//       setState(() => currentlyPlayingFile = null);
//     } else {
//       try {
//         await _audioPlayer.setFilePath(song.path);
//         await _audioPlayer.play();
//         setState(() => currentlyPlayingFile = song);
//       } catch (e) {
//         _showMessage("שגיאה בניגון הקובץ");
//       }
//     }
//   }

//   Future<void> _deleteSong(File song) async {
//     try {
//       if (currentlyPlayingFile == song) {
//         await _audioPlayer.stop();
//         currentlyPlayingFile = null;
//       }
//       await song.delete();
//       await _loadDownloadedSongs();
//       _showMessage("השיר נמחק");
//     } catch (e) {
//       print("Delete error: $e");
//     }
//   }

//   void _showMessage(String message) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
//     );
//   }

//   Widget _buildSongList() {
//     if (downloadedSongs.isEmpty) {
//       return const Center(
//         child: Padding(
//           padding: EdgeInsets.all(8.0),
//           child: Text("אין שירים בתיקייה, הדבק קישור למעלה כדי להוריד"),
//         ),
//       );
//     }
//     return ListView.builder(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       itemCount: downloadedSongs.length,
//       itemBuilder: (_, index) {
//         final song = downloadedSongs[index];
//         final isPlaying = currentlyPlayingFile == song;
//         final name = song.path.split('/').last;
//         return Card(
//           elevation: 2,
//           margin: const EdgeInsets.symmetric(vertical: 4),
//           child: ListTile(
//             leading: Icon(
//               isPlaying ? Icons.music_video : Icons.music_note,
//               color: isPlaying ? Colors.green : Colors.grey,
//             ),
//             title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
//             trailing: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 IconButton(
//                   icon: Icon(isPlaying ? Icons.stop : Icons.play_arrow),
//                   color: isPlaying ? Colors.red : Colors.blue,
//                   onPressed: () => _playOrStopSong(song),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.delete, color: Colors.redAccent),
//                   onPressed: () => _deleteSong(song),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("שליחת שיר ל-Firebase"),
//         centerTitle: true,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             // תצוגת השיר שנבחר כרגע לעלייה
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.grey[200],
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: AnimatedSwitcher(
//                 duration: const Duration(milliseconds: 300),
//                 child:
//                     selectedFileName == null
//                         ? const Text("• לא נבחר שיר להעלאה")
//                         : Text(
//                           "• שיר מוכן למשלוח: $selectedFileName",
//                           key: ValueKey(selectedFileName),
//                           style: const TextStyle(
//                             fontWeight: FontWeight.bold,
//                             color: Colors.blue,
//                           ),
//                         ),
//               ),
//             ),
//             const SizedBox(height: 15),

//             ElevatedButton.icon(
//               icon: const Icon(Icons.folder_special),
//               onPressed: _pickMusicFromFolder,
//               label: const Text("בחר מתוך השירים שהורדו מיוטיוב"),
//             ),
//             ElevatedButton.icon(
//               icon: const Icon(Icons.audiotrack),
//               onPressed: _pickMusicFromDevice,
//               label: const Text("בחר שיר אחר מהגלריה הכללית"),
//             ),

//             const SizedBox(height: 10),
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.green[600],
//               ),
//               onPressed:
//                   (selectedFilePath == null || isSending)
//                       ? null
//                       : _sendSongToFirebase,
//               child:
//                   isSending
//                       ? const SizedBox(
//                         height: 20,
//                         width: 20,
//                         child: CircularProgressIndicator(
//                           color: Colors.white,
//                           strokeWidth: 2,
//                         ),
//                       )
//                       : const Text(
//                         "שלח שיר נבחר ל-Firebase",
//                         style: TextStyle(color: Colors.white),
//                       ),
//             ),

//             const Divider(height: 40, thickness: 1.5),

//             ElevatedButton.icon(
//               style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
//               icon: const Icon(Icons.open_in_new, color: Colors.white),
//               onPressed: _openYouTube,
//               label: const Text(
//                 "פתח אפליקציית YouTube להעתקת קישור",
//                 style: TextStyle(color: Colors.white),
//               ),
//             ),
//             const SizedBox(height: 15),

//             TextField(
//               controller: youtubeController,
//               decoration: const InputDecoration(
//                 labelText: "הדבק כאן קישור לשיר ביוטיוב",
//                 prefixIcon: Icon(Icons.link, color: Colors.red),
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 10),

//             ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.redAccent,
//               ),
//               onPressed: isDownloading ? null : _saveYouTubeSong,
//               child:
//                   isDownloading
//                       ? const Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           SizedBox(
//                             height: 18,
//                             width: 18,
//                             child: CircularProgressIndicator(
//                               color: Colors.white,
//                               strokeWidth: 2,
//                             ),
//                           ),
//                           SizedBox(width: 10),
//                           Text(
//                             "מבצע הורדה מהשרת המרוחק...",
//                             style: TextStyle(color: Colors.white),
//                           ),
//                         ],
//                       )
//                       : const Text(
//                         "הורד ושמור שיר מהיוטיוב",
//                         style: TextStyle(color: Colors.white),
//                       ),
//             ),

//             const Divider(height: 40, thickness: 1.5),
//             const Row(
//               children: [
//                 Icon(Icons.download_done, color: Colors.green),
//                 SizedBox(width: 8),
//                 Text(
//                   "שירים מקומיים באפליקציה (my_songs)",
//                   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 10),
//             _buildSongList(),
//           ],
//         ),
//       ),
//     );
//   }
// }
