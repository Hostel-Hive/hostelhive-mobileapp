import 'package:flutter/material.dart';

class PlaceholderHome extends StatelessWidget {
  const PlaceholderHome({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'HostelHive',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
