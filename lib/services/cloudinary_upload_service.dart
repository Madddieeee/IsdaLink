import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:isdalink/config/cloudinary_config.dart';

class CloudinaryUploadService {
  const CloudinaryUploadService();

  static const int maxImageBytes = 8 * 1024 * 1024;
  static const Duration uploadTimeout = Duration(seconds: 45);

  static const Set<String> allowedStaticFolders = <String>{
    CloudinaryConfig.fishStockFolder,
    CloudinaryConfig.profileFolder,
  };

  static const Set<String> allowedMimeTypes = <String>{
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/heic',
    'image/heif',
  };

  Future<String> uploadImage(
    XFile image, {
    String folder = CloudinaryConfig.fishStockFolder,
  }) async {
    if (CloudinaryConfig.cloudName.trim().isEmpty ||
        CloudinaryConfig.unsignedUploadPreset.trim().isEmpty) {
      throw StateError('Image upload is not configured yet.');
    }

    if (!_isAllowedFolder(folder)) {
      throw StateError('The selected upload destination is not allowed.');
    }

    await _validateImage(image);

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/upload',
    );

    final request = http.MultipartRequest(
      'POST',
      uri,
    );

    request.fields['upload_preset'] = CloudinaryConfig.unsignedUploadPreset;
    request.fields['folder'] = folder;
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        image.path,
      ),
    );

    final response = await request.send().timeout(uploadTimeout);
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Image upload failed. Please try again.');
    }

    Map<String, dynamic> decodedBody;

    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException();
      }
      decodedBody = decoded;
    } on FormatException {
      throw Exception('Image upload returned an invalid response. Please try again.');
    }

    final secureUrl = decodedBody['secure_url']?.toString().trim() ?? '';
    final resourceType = decodedBody['resource_type']?.toString().trim() ?? '';

    if (secureUrl.isEmpty ||
        !secureUrl.startsWith('https://') ||
        (resourceType.isNotEmpty && resourceType != 'image')) {
      throw Exception('Image upload finished but no valid image link was returned.');
    }

    return secureUrl;
  }

  bool _isAllowedFolder(String folder) {
    final normalized = folder.trim();

    if (allowedStaticFolders.contains(normalized)) {
      return true;
    }

    final verificationPrefix = '${CloudinaryConfig.supplierVerificationFolder}/';
    if (!normalized.startsWith(verificationPrefix)) {
      return false;
    }

    final remainder = normalized.substring(verificationPrefix.length);
    final segments = remainder.split('/');

    if (segments.length == 2 && segments[1] == 'stores') {
      return _isSafeFolderSegment(segments[0]);
    }

    if (segments.length == 4 &&
        segments[1] == 'change_requests' &&
        segments[2] == 'stores') {
      // Kept for forward compatibility if a request identifier is appended.
      return _isSafeFolderSegment(segments[0]) &&
          _isSafeFolderSegment(segments[3]);
    }

    if (segments.length == 3 &&
        segments[1] == 'change_requests' &&
        segments[2] == 'stores') {
      return _isSafeFolderSegment(segments[0]);
    }

    return false;
  }

  bool _isSafeFolderSegment(String value) {
    return RegExp(r'^[A-Za-z0-9_-]{1,128}$').hasMatch(value);
  }

  Future<void> _validateImage(XFile image) async {
    final length = await image.length();

    if (length <= 0) {
      throw StateError('The selected image is empty.');
    }

    if (length > maxImageBytes) {
      throw StateError('The selected image must be 8 MB or smaller.');
    }

    final reportedMimeType = image.mimeType?.trim().toLowerCase() ?? '';
    if (reportedMimeType.isNotEmpty &&
        !allowedMimeTypes.contains(reportedMimeType)) {
      throw StateError('Choose a JPEG, PNG, WebP, HEIC, or HEIF image.');
    }

    if (reportedMimeType.isEmpty && !_hasAllowedExtension(image.path)) {
      throw StateError('Choose a JPEG, PNG, WebP, HEIC, or HEIF image.');
    }
  }

  bool _hasAllowedExtension(String path) {
    final normalized = path.toLowerCase();
    return normalized.endsWith('.jpg') ||
        normalized.endsWith('.jpeg') ||
        normalized.endsWith('.png') ||
        normalized.endsWith('.webp') ||
        normalized.endsWith('.heic') ||
        normalized.endsWith('.heif');
  }
}
