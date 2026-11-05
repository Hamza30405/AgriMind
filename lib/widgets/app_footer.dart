import 'package:flutter/material.dart';

import '../constants.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Text(
          '$kAppName · v$kAppVersion',
          style: TextStyle(color: muted, fontSize: 11),
        ),
      ),
    );
  }
}
