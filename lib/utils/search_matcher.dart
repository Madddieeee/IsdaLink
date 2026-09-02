class SearchMatcher {
  const SearchMatcher._();

  static String normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  static bool matches({
    required String query,
    required Iterable<String> values,
  }) {
    final normalizedQuery = normalize(query);

    if (normalizedQuery.isEmpty) {
      return true;
    }

    final normalizedValues = values
        .map(normalize)
        .where((value) => value.isNotEmpty)
        .toList();

    if (normalizedValues.isEmpty) {
      return false;
    }

    for (final value in normalizedValues) {
      if (value == normalizedQuery ||
          value.startsWith(normalizedQuery) ||
          value.contains(normalizedQuery)) {
        return true;
      }
    }

    final queryTokens = _tokens(normalizedQuery);
    final valueTokens = normalizedValues.expand(_tokens).toList();

    if (queryTokens.isEmpty || valueTokens.isEmpty) {
      return false;
    }

    return queryTokens.every(
      (queryToken) => valueTokens.any(
        (valueToken) => _tokenMatches(queryToken, valueToken),
      ),
    );
  }

  static int relevance({
    required String query,
    required Iterable<String> values,
  }) {
    final normalizedQuery = normalize(query);

    if (normalizedQuery.isEmpty) {
      return 0;
    }

    final normalizedValues = values
        .map(normalize)
        .where((value) => value.isNotEmpty)
        .toList();

    for (final value in normalizedValues) {
      if (value == normalizedQuery) {
        return 0;
      }
    }

    for (final value in normalizedValues) {
      if (value.startsWith(normalizedQuery)) {
        return 1;
      }
    }

    for (final value in normalizedValues) {
      if (value.contains(normalizedQuery)) {
        return 2;
      }
    }

    return matches(query: normalizedQuery, values: normalizedValues) ? 3 : 4;
  }

  static List<String> _tokens(String value) {
    return value
        .split(RegExp(r'[^a-z0-9]+'))
        .where((token) => token.isNotEmpty)
        .toList();
  }

  static bool _tokenMatches(String queryToken, String valueToken) {
    if (valueToken == queryToken ||
        valueToken.startsWith(queryToken) ||
        valueToken.contains(queryToken)) {
      return true;
    }

    // Very short terms are intentionally not fuzzy matched. This prevents
    // one- or two-letter searches from returning unrelated marketplace data.
    if (queryToken.length <= 2) {
      return false;
    }

    final longestLength = queryToken.length > valueToken.length
        ? queryToken.length
        : valueToken.length;
    final allowedDistance = longestLength >= 6 ? 2 : 1;

    if ((queryToken.length - valueToken.length).abs() > allowedDistance) {
      return false;
    }

    return _levenshteinDistance(
          queryToken,
          valueToken,
          stopAfter: allowedDistance,
        ) <=
        allowedDistance;
  }

  static int _levenshteinDistance(
    String left,
    String right, {
    required int stopAfter,
  }) {
    if (left == right) {
      return 0;
    }

    if (left.isEmpty) {
      return right.length;
    }

    if (right.isEmpty) {
      return left.length;
    }

    var previous = List<int>.generate(right.length + 1, (index) => index);

    for (var leftIndex = 1; leftIndex <= left.length; leftIndex++) {
      final current = List<int>.filled(right.length + 1, 0);
      current[0] = leftIndex;
      for (var rightIndex = 1; rightIndex <= right.length; rightIndex++) {
        final substitutionCost =
            left.codeUnitAt(leftIndex - 1) == right.codeUnitAt(rightIndex - 1)
                ? 0
                : 1;

        final deletion = previous[rightIndex] + 1;
        final insertion = current[rightIndex - 1] + 1;
        final substitution = previous[rightIndex - 1] + substitutionCost;

        var best = deletion < insertion ? deletion : insertion;
        if (substitution < best) {
          best = substitution;
        }

        current[rightIndex] = best;
      }

      previous = current;
    }

    return previous[right.length];
  }
}
