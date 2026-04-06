import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Defaults to English. Toggle via [localeProvider.notifier].
final localeProvider = StateProvider<Locale>((ref) => const Locale('en'));
