import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminChangeRequestCard extends StatelessWidget {
  const AdminChangeRequestCard({
    super.key,
    required this.document,
    required this.onOpen,
  });

  final QueryDocumentSnapshot<Map<String, dynamic>> document;
  final VoidCallback onOpen;

  String stringValue(
    Map<String, dynamic> data,
    String key, [
    String fallback = '',
  ]) {
    final value = data[key]?.toString().trim() ?? '';
    return value.isEmpty ? fallback : value;
  }

  String formattedDate(dynamic value) {
    if (value is! Timestamp) {
      return 'Recently submitted';
    }

    final date = value.toDate();

    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  List<String> changedFields(
    Map<String, dynamic> data,
  ) {
    final raw = data['changedFields'];

    if (raw is! List) {
      return const <String>[];
    }

    return raw
        .map((value) => value.toString().trim())
        .where((value) => value.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final data = document.data();

    final supplierName = stringValue(
      data,
      'supplierName',
      'Approved Supplier',
    );
    final requestedLocation = stringValue(
      data,
      'requestedLocation',
      'Requested business location',
    );
    final requestedPhoto = stringValue(
      data,
      'requestedStorePhotoUrl',
    );
    final reason = stringValue(
      data,
      'reason',
      'No reason provided',
    );
    final changes = changedFields(data);

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: const Color(0xFFE0E9F1),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0E102C44),
            blurRadius: 15,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 49,
                  height: 49,
                  color: const Color(0xFFEAF5FF),
                  child: requestedPhoto.isEmpty
                      ? const Icon(
                          Icons.storefront_rounded,
                          color: Color(0xFF146BFF),
                        )
                      : Image.network(
                          requestedPhoto,
                          fit: BoxFit.cover,
                          errorBuilder: (
                            context,
                            error,
                            stackTrace,
                          ) {
                            return const Icon(
                              Icons.storefront_rounded,
                              color: Color(0xFF146BFF),
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      supplierName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF102C44),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Submitted ${formattedDate(data['submittedAt'])}',
                      style: const TextStyle(
                        color: Color(0xFF7B8FA3),
                        fontSize: 8.8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3DC),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.hourglass_top_rounded,
                      size: 11,
                      color: Color(0xFFA76F15),
                    ),
                    SizedBox(width: 3),
                    Text(
                      'PENDING',
                      style: TextStyle(
                        color: Color(0xFFA76F15),
                        fontSize: 7.4,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F9FC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: Color(0xFF5E7F97),
                  size: 16,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    requestedLocation,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF526A7C),
                      fontSize: 9.2,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (changes.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              'REQUESTED CHANGES',
              style: TextStyle(
                color: Color(0xFF8A9BAA),
                fontSize: 7.6,
                letterSpacing: 0.7,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: changes
                  .map(
                    (change) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF4FF),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        change,
                        style: const TextStyle(
                          color: Color(0xFF146BFF),
                          fontSize: 7.8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFF0E0B5),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: Color(0xFF9B721F),
                  size: 15,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    reason,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF745A25),
                      fontSize: 8.5,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 43,
            child: ElevatedButton.icon(
              onPressed: onOpen,
              icon: const Icon(
                Icons.fact_check_outlined,
                size: 17,
              ),
              label: const Text(
                'Review Current vs Requested',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 10.2,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF146BFF),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
