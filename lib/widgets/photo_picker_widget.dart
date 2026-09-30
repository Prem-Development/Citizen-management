import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class PhotoPickerWidget extends StatelessWidget {
  final String? photoPath;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback? onRemove;
  final double size;

  const PhotoPickerWidget({
    super.key,
    this.photoPath,
    required this.onCamera,
    required this.onGallery,
    this.onRemove,
    this.size = 110,
  });

  bool get _hasPhoto {
    if (photoPath == null || photoPath!.isEmpty) return false;
    return File(photoPath!).existsSync();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onTap: () => _showSourcePicker(context),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceLight,
                border: Border.all(color: AppColors.primary, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(50),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipOval(
                child: _hasPhoto
                    ? Image.file(
                        File(photoPath!),
                        fit: BoxFit.cover,
                        width: size,
                        height: size,
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_rounded,
                            size: size * 0.4,
                            color: AppColors.textHint,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add Photo',
                            style: TextStyle(
                              color: AppColors.textHint,
                              fontSize: size * 0.11,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          // Camera button overlay
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => _showSourcePicker(context),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 2.5,
                  ),
                ),
                child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
              ),
            ),
          ),
          // Remove button
          if (_hasPhoto && onRemove != null)
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 2,
                    ),
                  ),
                  child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showSourcePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Photo Source',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.primaryDark,
                child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
              ),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(ctx);
                onCamera();
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.black,
                child: Icon(Icons.photo_library_rounded, size: 20),
              ),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                onGallery();
              },
            ),
            if (_hasPhoto && onRemove != null)
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.error,
                  child: Icon(Icons.delete_rounded, color: Colors.white, size: 20),
                ),
                title: const Text('Remove Photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  onRemove!();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
