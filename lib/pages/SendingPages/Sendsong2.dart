import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';

class SendSong extends StatefulWidget {
  const SendSong({super.key});

  @override
  State<SendSong> createState() => _SendSongState();
}

class _SendSongState extends State<SendSong> {
  String? selectedFilePath;
  String? selectedFileName;
  bool isSending = false;
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
      _showMessage("אין שירים זמינים בתיקייה");
      return;
    }
    showModalBottomSheet(
      context: context,
      builder:
          (_) => ListView.builder(
            itemCount: downloadedSongs.length,
            itemBuilder: (_, index) {
              final file = downloadedSongs[index];
              return ListTile(
                title: Text(file.path.split('/').last),
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
    final song = File(selectedFilePath!);

    final size = await song.length();
    if (size > 10 * 1024 * 1024) {
      _showMessage("קובץ גדול מ-10MB, לא ניתן להעלות");
      return;
    }

    final fileName = selectedFileName ?? song.path.split('/').last;
    final ref = FirebaseStorage.instance.ref("songs/$fileName");

    try {
      await ref.getDownloadURL();
      _showMessage("הקובץ כבר קיים ב-Firebase");
    } catch (_) {
      try {
        await ref.putFile(song);
        _showMessage("השיר עלה בהצלחה: $fileName");
      } catch (e) {
        print("Upload error: $e");
        _showMessage("נכשלה העלאת השיר ל-Firebase");
      }
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
      _showMessage("קישור יוטיוב לא תקין");
      return;
    }

    try {
      final response = await http.post(
        Uri.parse("http://5.102.238.242:3000/download-youtube"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"youtubeUrl": url}),
      );
      if (response.statusCode == 200) {
        await _loadDownloadedSongs();
        youtubeController.clear();
        _showMessage("השיר הורד ונשמר בהצלחה");
      } else {
        _showMessage("שגיאה בשרת");
      }
    } catch (e) {
      print("Download error:");
      _showMessage("הורדה נכשלה, נסה שוב מאוחר יותר");
    }
  }

  void _openYouTube() async {
    final url = Uri.parse("https://www.youtube.com/");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _showMessage("לא ניתן לפתוח את YouTube");
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
    }
  }

  Future<void> _deleteSong(File song) async {
    try {
      await song.delete();
      await _loadDownloadedSongs();
      _showMessage("השיר נמחק");
    } catch (e) {
      print("Delete error: $e");
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildSongList() {
    if (downloadedSongs.isEmpty) {
      return const Text("אין שירים בתיקייה");
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: downloadedSongs.length,
      itemBuilder: (_, index) {
        final song = downloadedSongs[index];
        final isPlaying = currentlyPlayingFile == song;
        return ListTile(
          title: Text(song.path.split('/').last),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    isPlaying ? Icons.stop : Icons.play_arrow,
                    key: ValueKey(isPlaying),
                  ),
                ),
                onPressed: () => _playOrStopSong(song),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _deleteSong(song),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("שליחת שיר ל-Firebase")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child:
                  selectedFileName == null
                      ? const Text("\u2022 לא נבחר שיר")
                      : Text(
                        "\u2022 שיר נבחר: $selectedFileName",
                        key: ValueKey(selectedFileName),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _pickMusicFromFolder,
              child: const Text("בחר שיר מתיקיית my_songs"),
            ),
            ElevatedButton(
              onPressed: _pickMusicFromDevice,
              child: const Text("בחר שיר מהגלריה הכללית"),
            ),
            ElevatedButton(
              onPressed: selectedFilePath == null ? null : _sendSongToFirebase,
              child: const Text("שלח שיר ל-Firebase"),
            ),
            const Divider(height: 30),
            ElevatedButton(
              onPressed: _openYouTube,
              child: const Text("פתח YouTube"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: youtubeController,
              decoration: const InputDecoration(
                labelText: "קישור לשיר ביוטיוב",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _saveYouTubeSong,
              child: const Text("הורד ושמור שיר מהיוטיוב"),
            ),
            const Divider(height: 30),
            const Text(
              "\u2022 שירים שהורדו",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            _buildSongList(),
          ],
        ),
      ),
    );
  }
}
