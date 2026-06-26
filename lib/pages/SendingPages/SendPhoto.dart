import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class Sendphoto extends StatefulWidget {
  const Sendphoto({super.key});

  @override
  State<Sendphoto> createState() => _SendphotoState();
}

class _ThemeColors {
  static const primary = Color(0xFF6200EE); // צבע סגול מודרני אחיד
  static const background = Color(0xFFF5F5F7);
}

class _SendphotoState extends State<Sendphoto> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false; // משתנה למניעת לחיצות כפולות והצגת טעינה

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

    if (!mounted) return;

    final success = result['isSuccess'] ?? result['success'];
    if (success == true) {
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
                child: Text(
                  "The photo was successfully saved to your gallery! 📸",
                ),
              ),
            ],
          ),
        ),
      );
    } else {
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
              Expanded(child: Text("Failed to save the photo.")),
            ],
          ),
        ),
      );
    }
  }

  /// העלאת תמונה ל-Firebase ושמירת URL ב-Database
  Future<void> _uploadImageToFirebase() async {
    if (_selectedImage == null) return;

    if (FirebaseAuth.instance.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          content: const Row(
            children: [
              Icon(Icons.lock_outline, color: Colors.white),
              SizedBox(width: 10),
              Expanded(child: Text("Security error: You must be logged in.")),
            ],
          ),
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      // יצירת קובץ זמני לדחיסה
      final dir = await getTemporaryDirectory();
      final compressedPath = path.join(
        dir.path,
        "compressed_${DateTime.now().millisecondsSinceEpoch}.jpg",
      );

      // דחיסה ושינוי גודל תואם למסך ה-TFT של ה-ESP32
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
        throw Exception("Compression failed");
      }

      final fileSizeKB = await compressedFile.length() / 1024;
      print("✅ Compressed size: ${fileSizeKB.toStringAsFixed(2)} KB");

      // העלאה ל־Firebase Storage
      final fileName = path.basename(compressedFile.path);
      final storageRef = FirebaseStorage.instance.ref().child(
        "images/$fileName",
      );
      final uploadTask = await storageRef.putFile(File(compressedFile.path));
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      final timestamp = DateTime.now().toIso8601String();

      // עדכון ה-Realtime Database
      final dbRef = FirebaseDatabase.instance.ref("images/latest");
      await dbRef.set({"url": downloadUrl, "timestamp": timestamp});

      print("✅ Photo updated in database");

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
              Icon(Icons.cloud_done_outlined, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text("The photo successfully sent to my love! 🖼️🎉"),
              ),
            ],
          ),
        ),
      );

      setState(() {
        _selectedImage = null; // ניקוי הבחירה לאחר הצלחה
      });
    } catch (e) {
      print("❌ Error uploading photo: $e");
      if (!mounted) return;
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
              Expanded(child: Text("Error sending: Incorrect permissions")),
            ],
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ThemeColors.background,
      appBar: AppBar(
        title: const Text(
          "Send photo page",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            const Text(
              "Select an image to present on the TFT Screen",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Images will be optimized and scaled down for the ESP32 rendering frame",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 24),

            // כרטיס תצוגה מקדימה לתמונה / תיבת בחירה
            Card(
              elevation: 4,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                height: 250,
                decoration: ContainerDecorationHelper.buildBoxDecoration(),
                child:
                    _selectedImage != null
                        ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.file(
                                _selectedImage!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 10,
                              right: 10,
                              child: CircleAvatar(
                                backgroundColor: Colors.black.withOpacity(0.6),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _selectedImage = null;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        )
                        : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_rounded,
                              size: 70,
                              color: _ThemeColors.primary.withOpacity(0.4),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "No image selected yet",
                              style: TextStyle(
                                color: Colors.black45,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
              ),
            ),
            const SizedBox(height: 24),

            // כפתורי בחירת מקור תמונה (מצלמה / גלריה) בשורה אחת
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isUploading ? null : _pickImage,
                    icon: const Icon(Icons.photo_library_rounded),
                    label: const Text("Gallery"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _ThemeColors.primary,
                      side: const BorderSide(
                        color: _ThemeColors.primary,
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isUploading ? null : _takePhoto,
                    icon: const Icon(Icons.camera_alt_rounded),
                    label: const Text("Camera"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _ThemeColors.primary,
                      side: const BorderSide(
                        color: _ThemeColors.primary,
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // כפתור שמירה במכשיר המקומי
            if (_selectedImage != null) ...[
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _saveImageToDevice,
                icon: const Icon(
                  Icons.save_alt_rounded,
                  color: _ThemeColors.primary,
                ),
                label: const Text(
                  "Save image to local gallery",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _ThemeColors.primary,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // כפתור שליחה והעלאה ראשי ל-Firebase
            ElevatedButton.icon(
              onPressed:
                  (_selectedImage == null || _isUploading)
                      ? null
                      : _uploadImageToFirebase,
              icon:
                  _isUploading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : const Icon(
                        Icons.cloud_upload_rounded,
                        color: Colors.white,
                      ),
              label: Text(
                _isUploading ? "Uploading & Compressing..." : "Send photo",
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
    );
  }
}

// מחלקת עזר לעיצוב קופסת התצוגה המקדימה
class ContainerDecorationHelper {
  static BoxDecoration buildBoxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    );
  }
}
