import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class SupplierVerificationStorageService {
  const SupplierVerificationStorageService();

  static const int maxPermitBytes = 8 * 1024 * 1024;

  Future<String> uploadBusinessPermit({
    required String uid,
    required XFile image,
  }) async {
    final bytes = await image.readAsBytes();

    if (bytes.isEmpty) {
      throw StateError('The selected permit image is empty.');
    }

    if (bytes.length > maxPermitBytes) {
      throw StateError('The permit image must be 8 MB or smaller.');
    }

    final reference = FirebaseStorage.instance.ref(
      'supplier_verification/$uid/permits/'
      '${DateTime.now().microsecondsSinceEpoch}',
    );

    final metadata = SettableMetadata(
      contentType: _contentType(image),
      cacheControl: 'private, max-age=300',
      customMetadata: <String, String>{
        'ownerUid': uid,
        'evidenceType': 'business_permit',
      },
    );

    await reference.putData(bytes, metadata);
    return reference.fullPath;
  }

  Future<Uint8List?> loadEvidenceBytes(String storagePath) {
    return FirebaseStorage.instance
        .ref(storagePath.trim())
        .getData(maxPermitBytes);
  }

  Future<void> deleteEvidence(String storagePath) async {
    final path = storagePath.trim();

    if (!isManagedPermitPath(path)) {
      return;
    }

    try {
      await FirebaseStorage.instance.ref(path).delete();
    } on FirebaseException catch (error) {
      if (error.code != 'object-not-found') {
        rethrow;
      }
    }
  }

  bool isManagedPermitPath(String storagePath) {
    return storagePath.trim().startsWith('supplier_verification/') &&
        storagePath.trim().contains('/permits/');
  }

  String _contentType(XFile image) {
    final reportedType = image.mimeType?.trim().toLowerCase() ?? '';
    const allowedTypes = <String>{
      'image/jpeg',
      'image/png',
      'image/webp',
      'image/heic',
      'image/heif',
    };

    if (allowedTypes.contains(reportedType)) {
      return reportedType;
    }

    final path = image.path.toLowerCase();

    if (path.endsWith('.png')) {
      return 'image/png';
    }
    if (path.endsWith('.webp')) {
      return 'image/webp';
    }
    if (path.endsWith('.heic')) {
      return 'image/heic';
    }
    if (path.endsWith('.heif')) {
      return 'image/heif';
    }

    return 'image/jpeg';
  }
}
