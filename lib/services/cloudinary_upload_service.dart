import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:isdalink/config/cloudinary_config.dart';

class CloudinaryUploadService {
  const CloudinaryUploadService();

  Future<String> uploadImage(
    XFile image, {
    String folder = CloudinaryConfig.fishStockFolder,
  }) async {
    if (CloudinaryConfig.cloudName == 'YOUR_CLOUD_NAME' ||
        CloudinaryConfig.unsignedUploadPreset == 'YOUR_UNSIGNED_UPLOAD_PRESET') {
      throw Exception(
        'Cloudinary is not configured. Update lib/config/cloudinary_config.dart first.',
      );
    }

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/upload',
    );

    final request = http.MultipartRequest('POST', uri);
    request.fields['upload_preset'] = CloudinaryConfig.unsignedUploadPreset;
    request.fields['folder'] = folder;
    request.files.add(
      await http.MultipartFile.fromPath('file', image.path),
    );

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Cloudinary upload failed: $responseBody');
    }

    final decodedBody = jsonDecode(responseBody) as Map<String, dynamic>;
    final secureUrl = decodedBody['secure_url']?.toString() ?? '';

    if (secureUrl.isEmpty) {
      throw Exception('Cloudinary upload succeeded but no image URL was returned.');
    }

    return secureUrl;
  }
}
