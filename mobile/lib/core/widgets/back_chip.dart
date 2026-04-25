import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/colors.dart';
import '../navigation/smart_back.dart';

/// Floating circular back button for screens with no AppBar (Direction-C
/// home, full-screen maps, TabBar roots, custom-header pages). Drop one
/// into the existing `body:` `Stack` — it positions itself top-start via
/// [SafeArea] so it never collides with the system status bar.
class BackChip extends ConsumerWidget {
  const BackChip({super.key, this.background, this.iconColor});

  /// Override the chip background. Defaults to [AppColors.brandBlue].
  final Color? background;

  /// Override the icon colour. Defaults to white.
  final Color? iconColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: 8, top: 8),
          child: Material(
            color: background ?? AppColors.brandBlue,
            elevation: 4,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => smartBack(context, ref),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.arrow_back,
                  color: iconColor ?? Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
