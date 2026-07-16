import 'package:flutter/material.dart';

class BrowseSuppliersLoadingBody
    extends
        StatelessWidget {
  const BrowseSuppliersLoadingBody({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        18,
        22,
        18,
        20,
      ),
      children: List.generate(
        3,
        (
          index,
        ) => Container(
          height: 176,
          margin: const EdgeInsets.only(
            bottom: 16,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              24,
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
        ),
      ),
    );
  }
}

class BrowseSuppliersEmptyBody
    extends
        StatelessWidget {
  const BrowseSuppliersEmptyBody({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(
    BuildContext context,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        18,
        22,
        18,
        20,
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(
            22,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              24,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(
                  0x10000000,
                ),
                blurRadius: 14,
                offset: Offset(
                  0,
                  7,
                ),
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(
                Icons.storefront_outlined,
                color: Color(
                  0xFF146BFF,
                ),
                size: 44,
              ),
              const SizedBox(
                height: 10,
              ),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(
                    0xFF102C44,
                  ),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(
                height: 5,
              ),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(
                    0xFF7B8FA3,
                  ),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class BrowseSuppliersErrorBody
    extends
        StatelessWidget {
  const BrowseSuppliersErrorBody({
    super.key,
    required this.error,
  });

  final Object error;

  @override
  Widget build(
    BuildContext context,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        18,
        22,
        18,
        20,
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(
            18,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              24,
            ),
          ),
          child: Text(
            'Unable to load supplier profiles: $error',
            style: const TextStyle(
              color: Color(
                0xFFD32F2F,
              ),
              fontSize: 12,
              height: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
