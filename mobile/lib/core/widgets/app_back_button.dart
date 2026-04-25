import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../navigation/smart_back.dart';

/// Drop-in `leading:` for any AppBar. Calls [smartBack] on tap so back
/// behaviour is uniform regardless of how the screen was reached
/// (`context.go()` vs `context.push()` vs deep link).
///
/// When [color] is null (the default), the icon inherits the AppBar's
/// `iconTheme` — the right call for screens that use the stock light theme
/// (e.g. provider onboarding). Pass `Colors.white` explicitly for AppBars
/// that override the foreground (most brand-blue AppBars in this app set
/// `foregroundColor: Colors.white` which already does this for the default
/// back glyph; we override it because we want our own onPressed handler).
class AppBackButton extends ConsumerWidget {
  const AppBackButton({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: Icon(Icons.arrow_back, color: color),
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: () => smartBack(context, ref),
    );
  }
}
