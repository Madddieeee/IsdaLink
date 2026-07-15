import 'package:flutter/material.dart';

class MeLoadingBody
    extends
        StatelessWidget {
  const MeLoadingBody({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return const Scaffold(
      backgroundColor: Color(
        0xFFF4F8FB,
      ),
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
