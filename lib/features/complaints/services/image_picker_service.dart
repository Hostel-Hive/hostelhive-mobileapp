import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

enum PhotoSource { camera, gallery }

class PickedImage {
  const PickedImage({required this.path, required this.sizeBytes});

  final String path;
  final int sizeBytes;
}

/// Lets the student choose a photo; replaced in tests.
abstract class ImagePickerService {
  /// Returns null when the student cancels.
  Future<PickedImage?> pick(PhotoSource source);
}

class DeviceImagePicker implements ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  @override
  Future<PickedImage?> pick(PhotoSource source) async {
    final file = await _picker.pickImage(
      source: source == PhotoSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
    );
    if (file == null) return null;
    return PickedImage(
      path: file.path,
      sizeBytes: await File(file.path).length(),
    );
  }
}

final imagePickerServiceProvider = Provider<ImagePickerService>((ref) {
  return DeviceImagePicker();
});

/// Largest photo that can be attached (UC013).
const int maxImageBytes = 5 * 1024 * 1024;

/// Returns an error message when the photo cannot be attached, otherwise null.
String? validateComplaintImage({required String path, required int sizeBytes}) {
  final extension = path.contains('.')
      ? path.split('.').last.toLowerCase()
      : '';
  if (!const {'jpg', 'jpeg', 'png'}.contains(extension)) {
    return 'Please use a JPG or PNG photo.';
  }
  if (sizeBytes > maxImageBytes) {
    return 'This photo is larger than 5 MB. Please choose a smaller one.';
  }
  return null;
}
