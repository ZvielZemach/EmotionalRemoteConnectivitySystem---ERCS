import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class Sendphoto extends StatefulWidget {
  const Sendphoto({super.key});

  @override
  State<Sendphoto> createState() => _SendphotoState();
}

class _SendphotoState extends State<Sendphoto> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _requestPermissions() async {
    await [Permission.camera, Permission.photos, Permission.storage].request();
  }

  Future<void> _pickImage() async {
    await _requestPermissions();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _takePhoto() async {
    await _requestPermissions();
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _saveImageToDevice() async {
    if (_selectedImage == null) return;

    final bytes = await _selectedImage!.readAsBytes();
    final result = await ImageGallerySaverPlus.saveImage(
      Uint8List.fromList(bytes),
      quality: 100,
      name: "saved_image_${DateTime.now().millisecondsSinceEpoch}",
    );

    final success = result['isSuccess'] ?? result['success'];
    if (success == true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("התמונה נשמרה בגלריה")));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("שמירת התמונה נכשלה")));
    }
  }

  /// העלאת תמונה ל-Firebase ושמירת URL ב-Database
  // Future<void> _uploadImageToFirebase() async {
  //   if (_selectedImage == null) return;

  //   try {
  //     final fileName = path.basename(_selectedImage!.path);
  //     final storageRef = FirebaseStorage.instance.ref().child(
  //       "images/$fileName",
  //     );

  //     final uploadTask = await storageRef.putFile(_selectedImage!);
  //     final downloadUrl = await uploadTask.ref.getDownloadURL();

  //     final dbRef = FirebaseDatabase.instance.ref("esp32/image");
  //     await dbRef.set(downloadUrl);

  // תקין
  // Future<void> _uploadImageToFirebase() async {
  //   if (_selectedImage == null) return;

  //   try {
  //     final fileName = path.basename(_selectedImage!.path);
  //     final storageRef = FirebaseStorage.instance.ref().child(
  //       "images/$fileName",
  //     );

  //     // העלאת הקובץ
  //     final uploadTask = await storageRef.putFile(_selectedImage!);
  //     final downloadUrl = await uploadTask.ref.getDownloadURL();

  //     // תאריך ושעה בפורמט ISO 8601
  //     final timestamp = DateTime.now().toIso8601String();

  //     // עדכון במסד נתונים
  //     final dbRef = FirebaseDatabase.instance.ref("images/latest");
  //     await dbRef.set({"url": downloadUrl, "timestamp": timestamp});

  //     print("התמונה והמידע נשמרו בהצלחה.");

  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(const SnackBar(content: Text("התמונה הועלתה ל-Firebase")));
  //   } catch (e) {
  //     print("שגיאה בהעלאת תמונה: $e");
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(const SnackBar(content: Text("שליחת התמונה נכשלה!")));
  //   }
  // }

  // new function // 28/5/25
  Future<void> _uploadImageToFirebase() async {
    if (_selectedImage == null) return;

    try {
      // יצירת קובץ זמני לדחיסה
      final dir = await getTemporaryDirectory();
      final compressedPath = path.join(
        dir.path,
        "compressed_${DateTime.now().millisecondsSinceEpoch}.jpg",
      );

      // דחיסה ושינוי גודל
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        _selectedImage!.path,
        compressedPath,
        quality: 100,
        minWidth: 480,
        minHeight: 320,
        format: CompressFormat.jpeg,
        keepExif: false,
      );

      if (compressedFile == null) {
        throw Exception("כשל בדחיסת התמונה");
      }

      final fileSizeKB = await compressedFile.length() / 1024;
      print("✅ גודל לאחר דחיסה: ${fileSizeKB.toStringAsFixed(2)} KB");

      // העלאה ל־Firebase – ודא שמועבר File ולא XFile
      final fileName = path.basename(compressedFile.path);
      final storageRef = FirebaseStorage.instance.ref().child(
        "images/$fileName",
      );
      final uploadTask = await storageRef.putFile(
        File(compressedFile.path),
      ); // <- שים לב להמרה ל־File
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      final timestamp = DateTime.now().toIso8601String();

      final dbRef = FirebaseDatabase.instance.ref("images/latest");
      await dbRef.set({"url": downloadUrl, "timestamp": timestamp});

      print("✅ תמונה הועלתה ונשמרה במסד");

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("התמונה הועלתה ל-Firebase")));
    } catch (e) {
      print("❌ שגיאה בהעלאת תמונה: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("שליחת התמונה נכשלה!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("שלח תמונה ל-Firebase")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _selectedImage != null
                ? Image.file(_selectedImage!, height: 200)
                : const Icon(Icons.image, size: 100, color: Colors.grey),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo),
              label: const Text("בחר מהגלריה"),
            ),
            ElevatedButton.icon(
              onPressed: _takePhoto,
              icon: const Icon(Icons.camera),
              label: const Text("צלם תמונה"),
            ),
            ElevatedButton.icon(
              onPressed: _saveImageToDevice,
              icon: const Icon(Icons.save),
              label: const Text("שמור במכשיר"),
            ),
            ElevatedButton.icon(
              onPressed: _uploadImageToFirebase,
              icon: const Icon(Icons.cloud_upload),
              label: const Text("שלח ל-Firebase"),
            ),
          ],
        ),
      ),
    );
  }
}
