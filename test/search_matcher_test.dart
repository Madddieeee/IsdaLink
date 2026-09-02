import 'package:flutter_test/flutter_test.dart';
import 'package:isdalink/utils/search_matcher.dart';

void main() {
  group('SearchMatcher typo tolerance', () {
    test('matches common fish-name typos', () {
      expect(
        SearchMatcher.matches(query: 'bngus', values: const ['Bangus']),
        isTrue,
      );
      expect(
        SearchMatcher.matches(query: 'tilpia', values: const ['Tilapia']),
        isTrue,
      );
      expect(
        SearchMatcher.matches(query: 'pdjanga', values: const ['Pidjanga']),
        isTrue,
      );
    });

    test('matches supplier and location typos', () {
      expect(
        SearchMatcher.matches(
          query: 'choper',
          values: const ['Chopper The Fish Dealer'],
        ),
        isTrue,
      );
      expect(
        SearchMatcher.matches(
          query: 'surgao',
          values: const ['City of Surigao, Surigao del Norte'],
        ),
        isTrue,
      );
      expect(
        SearchMatcher.matches(
          query: 'buenavsta',
          values: const ['Buenavista, Agusan del Norte'],
        ),
        isTrue,
      );
    });

    test('supports multi-word fuzzy searches', () {
      expect(
        SearchMatcher.matches(
          query: 'carla fsh',
          values: const ['Carla Fish'],
        ),
        isTrue,
      );
    });

    test('does not fuzzy match very short unrelated terms', () {
      expect(
        SearchMatcher.matches(query: 'bg', values: const ['Bangus']),
        isFalse,
      );
      expect(
        SearchMatcher.matches(query: 'xyz', values: const ['Bangus']),
        isFalse,
      );
    });

    test('ranks exact and prefix matches above fuzzy matches', () {
      final exact = SearchMatcher.relevance(
        query: 'bangus',
        values: const ['Bangus'],
      );
      final prefix = SearchMatcher.relevance(
        query: 'bang',
        values: const ['Bangus'],
      );
      final fuzzy = SearchMatcher.relevance(
        query: 'bngus',
        values: const ['Bangus'],
      );

      expect(exact, lessThan(prefix));
      expect(prefix, lessThan(fuzzy));
    });
  });
}
