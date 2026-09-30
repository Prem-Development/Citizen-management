import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../utils/app_constants.dart';

class PhotoService {
  static final PhotoService instance = PhotoService._internal();
  PhotoService._internal();

  final ImagePicker _picker = ImagePicker();

  Future<Directory> get _photoDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(path.join(appDir.path, AppConstants.photoDir));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Pick photo from camera, compress, save → returns saved file path
  Future<String?> pickFromCamera(String nic) async {
    try {
      final xfile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (xfile == null) return null;
      return await _savePhoto(File(xfile.path), nic);
    } catch (e) {
      debugPrint('PhotoService camera error: $e');
      return null;
    }
  }

  /// Pick photo from gallery, compress, save → returns saved file path
  Future<String?> pickFromGallery(String nic) async {
    try {
      final xfile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (xfile == null) return null;
      return await _savePhoto(File(xfile.path), nic);
    } catch (e) {
      debugPrint('PhotoService gallery error: $e');
      return null;
    }
  }

  /// Pick from either source with bottom sheet
  Future<String?> pickPhoto(BuildContext context, String nic) async {
    ImageSource? source;

    await showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Take Photo'),
              onTap: () {
                source = ImageSource.camera;
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from Gallery'),
              onTap: () {
                source = ImageSource.gallery;
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return null;
    if (source == ImageSource.camera) return pickFromCamera(nic);
    return pickFromGallery(nic);
  }

  Future<String> _savePhoto(File sourceFile, String nic) async {
    final dir = await _photoDir;
    final destPath = path.join(dir.path, '$nic.jpg');

    // Compress with image package
    final bytes = await sourceFile.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded != null) {
      final resized = img.copyResize(decoded, width: 800);
      final compressed = img.encodeJpg(resized, quality: 80);
      await File(destPath).writeAsBytes(compressed);
    } else {
      await sourceFile.copy(destPath);
    }
    return destPath;
  }

  Future<void> deletePhoto(String nic) async {
    try {
      final dir = await _photoDir;
      final file = File(path.join(dir.path, '$nic.jpg'));
      if (await file.exists()) await file.delete();
    } catch (e) {
      debugPrint('PhotoService delete error: $e');
    }
  }

  Future<String?> getPhotoPath(String nic) async {
    try {
      final dir = await _photoDir;
      final file = File(path.join(dir.path, '$nic.jpg'));
      if (await file.exists()) return file.path;
      return null;
    } catch (_) {
      return null;
    }
  }

  File? getPhotoFile(String? photoPath) {
    if (photoPath == null || photoPath.isEmpty) return null;
    final f = File(photoPath);
    return f.existsSync() ? f : null;
  }
}
