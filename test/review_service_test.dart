import 'package:flutter_test/flutter_test.dart';
import 'package:isdalink/services/review_service.dart';

void main() {
  const service = ReviewService();

  group('review photo validation', () {
    test('accepts up to three IsdaLink Cloudinary image URLs', () {
      final result = service.validatedPhotoUrls([
        'https://res.cloudinary.com/bxcgv4uz/image/upload/one.jpg',
        'https://res.cloudinary.com/bxcgv4uz/image/upload/two.jpg',
        'https://res.cloudinary.com/bxcgv4uz/image/upload/three.jpg',
      ]);

      expect(result, hasLength(3));
    });

    test('trims URLs and removes duplicates and blank values', () {
      final result = service.validatedPhotoUrls([
        ' https://res.cloudinary.com/bxcgv4uz/image/upload/one.jpg ',
        '',
        'https://res.cloudinary.com/bxcgv4uz/image/upload/one.jpg',
      ]);

      expect(result, [
        'https://res.cloudinary.com/bxcgv4uz/image/upload/one.jpg',
      ]);
    });

    test('rejects more than three unique photos', () {
      expect(
        () => service.validatedPhotoUrls([
          'https://res.cloudinary.com/bxcgv4uz/image/upload/one.jpg',
          'https://res.cloudinary.com/bxcgv4uz/image/upload/two.jpg',
          'https://res.cloudinary.com/bxcgv4uz/image/upload/three.jpg',
          'https://res.cloudinary.com/bxcgv4uz/image/upload/four.jpg',
        ]),
        throwsException,
      );
    });

    test('rejects non-HTTPS and non-IsdaLink Cloudinary URLs', () {
      expect(
        () => service.validatedPhotoUrls([
          'http://res.cloudinary.com/bxcgv4uz/image/upload/one.jpg',
        ]),
        throwsException,
      );
      expect(
        () => service.validatedPhotoUrls([
          'https://example.com/not-a-review-photo.jpg',
        ]),
        throwsException,
      );
    });
  });
}
