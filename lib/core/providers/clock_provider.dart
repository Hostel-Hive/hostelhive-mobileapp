import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Source of the current time, replaced in tests.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
