import 'package:flutter/material.dart';

class AppColors {
  // ── Brand ───────────────────────────────────────────────────────────────────
  // brandBlue corrected from #3B1704 → #1B4F72 per project brand system.
  static const Color brandBlue = Color(0xFF1B4F72);
  static const Color brandBlueDeep = Color(0xFF123449);
  static const Color brandBlueSoft = Color(0xFF2A6A95);

  // ── Amber accent ────────────────────────────────────────────────────────────
  static const Color amber = Color(0xFFF39C12);
  static const Color amberDeep = Color(0xFFD6860A);
  static const Color amberSoft = Color(0xFFFCE7C3);

  // ── Warm surfaces ──────────────────────────────────────────────────────────
  static const Color cream = Color(0xFFFBF7F1);
  static const Color canvas = Color(0xFFFAF7F2);
  static const Color paper = Color(0xFFFFFFFF);

  // ── Warm ink palette ───────────────────────────────────────────────────────
  static const Color ink = Color(0xFF1C1713);
  static const Color inkMid = Color(0xFF5D534A);
  static const Color inkSoft = Color(0xFF8E857B);

  // ── Dividers ───────────────────────────────────────────────────────────────
  static const Color line = Color(0xFFE8E2D7);
  static const Color lineSoft = Color(0xFFF1EBE0);

  // ── Status ─────────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF2E7D57);
  static const Color danger = Color(0xFFE74C3C);

  // ── Legacy tokens (still referenced by non-redesigned screens) ─────────────
  static const Color surface = Color(0xFFF5F7FA);
  static const Color textPrimary = Color(0xFF2C3E50);
  static const Color textSecondary = Color(0xFF7F8C8D);
}
