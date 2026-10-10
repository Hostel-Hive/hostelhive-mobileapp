import 'package:flutter/material.dart';

import 'core/placeholder_home.dart';
import 'core/theme/app_theme.dart';

class HostelHiveApp extends StatelessWidget {
  const HostelHiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HostelHive',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const PlaceholderHome(),
    );
  }
}
