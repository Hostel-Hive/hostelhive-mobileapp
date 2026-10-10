import 'package:flutter/material.dart';

import 'core/placeholder_home.dart';

class HostelHiveApp extends StatelessWidget {
  const HostelHiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HostelHive',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00A8F0)),
        useMaterial3: true,
      ),
      home: const PlaceholderHome(),
    );
  }
}
