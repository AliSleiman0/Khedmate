import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/colors.dart';
import '../../../core/domain/service_category.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/providers/categories_provider.dart';
import '../../../core/providers/locale_provider.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../shared/notifications/presentation/notifications_provider.dart';
import '../../shared/rating/data/rating_repository.dart';
import '../../shared/rating/presentation/rating_bottom_sheet.dart';
import '../booking/presentation/booking_provider.dart';

const _tag = 'CustomerHome';

/// Holds the home ask-bar query. Empty string = show full home layout.
final _searchQueryProvider = StateProvider<String>((ref) => '');

/// Recent Paid/Completed jobs for the Book-Again strip. Empty list on error.
final _recentJobsProvider = FutureProvider<List<_RecentJob>>((ref) async {
  try {
    final client = ref.read(apiClientProvider);
    final response = await client.dio.get('/bookings/jobs');
    final data = response.data as Map<String, dynamic>;
    final items = (data['data'] as List? ?? []);
    final jobs = items
        .map((e) => _RecentJob.fromJson(e as Map<String, dynamic>))
        .where((j) => j.status == 'Paid' || j.status == 'Completed')
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return jobs.take(5).toList();
  } catch (_) {
    return const <_RecentJob>[];
  }
});

class _RecentJob {
  final String id;
  final String categoryId;
  final String? providerName;
  final String status;
  final DateTime createdAt;

  const _RecentJob({
    required this.id,
    required this.categoryId,
    required this.status,
    required this.createdAt,
    this.providerName,
  });

  factory _RecentJob.fromJson(Map<String, dynamic> j) => _RecentJob(
        id: (j['jobId'] ?? j['id'] ?? '').toString(),
        categoryId: j['categoryId'] as String? ?? '',
        status: j['status'] as String? ?? '',
        providerName: j['providerName'] as String?,
        createdAt: j['createdAt'] != null
            ? DateTime.parse(j['createdAt'] as String)
            : DateTime.now(),
      );
}

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    final auth = ref.watch(authNotifierProvider);
    final query = ref.watch(_searchQueryProvider);
    final pendingAsync = ref.watch(pendingRatingsProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    final initial = auth.when(
      data: (state) {
        if (state is AuthAuthenticated) {
          final name = state.user.fullName.trim();
          if (name.isNotEmpty) return name.characters.first.toUpperCase();
        }
        return 'K';
      },
      loading: () => 'K',
      error: (_, __) => 'K',
    );

    final isSearching = query.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 96),
          physics: const BouncingScrollPhysics(),
          children: [
            _TopBar(
              initial: initial,
              unreadCount: unreadCount,
              onBell: () => context.push('/customer/notifications'),
            ),
            pendingAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (pending) {
                if (pending.isEmpty) return const SizedBox.shrink();
                final first = pending.first;
                return _PendingRatingStrip(
                  pendingLabel: s.homePendingRating,
                  rateNowLabel: s.homeRateNow,
                  onRate: () async {
                    log.d(_tag, 'rating banner tap',
                        data: {'jobId': first.jobId});
                    await RatingBottomSheet.show(
                      context,
                      jobId: first.jobId,
                      otherPartyName: first.rateTarget,
                    );
                    ref.invalidate(pendingRatingsProvider);
                  },
                  onDismiss: () {
                    log.d(_tag, 'rating banner dismiss',
                        data: {'jobId': first.jobId});
                    ref.invalidate(pendingRatingsProvider);
                  },
                );
              },
            ),
            _AskSection(
                s: s,
                onSpeak: () => context.go('/customer/booking/description')),
            if (!isSearching) ...[
              _ContextChips(s: s, ref: ref, context: context),
              _BrowseSection(s: s, ref: ref, context: context, query: query),
              _BookAgainSection(s: s, ref: ref, context: context),
              _ReferralStrip(s: s, onTap: () => context.push('/customer/referral')),
            ] else
              _FilteredGrid(s: s, ref: ref, context: context, query: query),
          ],
        ),
      ),
    );
  }
}

// ─── Top bar ──────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.initial,
    required this.unreadCount,
    required this.onBell,
  });

  final String initial;
  final int unreadCount;
  final VoidCallback onBell;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.brandBlue,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
          const Spacer(),
          _LocationPill(),
          const Spacer(),
          _BellButton(unreadCount: unreadCount, onTap: onBell),
        ],
      ),
    );
  }
}

class _LocationPill extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.comingSoon)),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              s.homeLocationLabel,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.inkSoft,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.place_outlined,
                    size: 14, color: AppColors.ink),
                const SizedBox(width: 4),
                Text(
                  s.homeLocationPrompt,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BellButton extends StatelessWidget {
  const _BellButton({required this.unreadCount, required this.onTap});

  final int unreadCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.paper,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            const Icon(Icons.notifications_none_rounded,
                size: 20, color: AppColors.ink),
            if (unreadCount > 0)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.amber,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.paper, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Pending rating strip ─────────────────────────────────────────────────────

class _PendingRatingStrip extends StatelessWidget {
  const _PendingRatingStrip({
    required this.pendingLabel,
    required this.rateNowLabel,
    required this.onRate,
    required this.onDismiss,
  });

  final String pendingLabel;
  final String rateNowLabel;
  final VoidCallback onRate;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.amberSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.amber.withOpacity(0.5)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.star_rounded, color: AppColors.amberDeep, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                pendingLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                  fontSize: 13,
                ),
              ),
            ),
            GestureDetector(
              onTap: onRate,
              child: Text(
                rateNowLabel,
                style: const TextStyle(
                  color: AppColors.amberDeep,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onDismiss,
              child: const Icon(Icons.close,
                  size: 16, color: AppColors.inkSoft),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Ask section (headline + subtitle + ask bar) ──────────────────────────────

class _AskSection extends ConsumerStatefulWidget {
  const _AskSection({required this.s, required this.onSpeak});

  final S s;
  final VoidCallback onSpeak;

  @override
  ConsumerState<_AskSection> createState() => _AskSectionState();
}

class _AskSectionState extends ConsumerState<_AskSection> {
  late final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.homeAskHeadline,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.1,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            s.homeAskSub,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.inkMid,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.line),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            padding: const EdgeInsetsDirectional.fromSTEB(16, 6, 6, 6),
            child: Row(
              children: [
                const Icon(Icons.search,
                    size: 18, color: AppColors.inkSoft),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onChanged: (v) {
                      log.d(_tag, 'search changed',
                          data: {'len': v.length});
                      ref.read(_searchQueryProvider.notifier).state = v;
                    },
                    onSubmitted: (_) {
                      FocusScope.of(context).unfocus();
                      widget.onSpeak();
                    },
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      filled: false,
                      hintText: s.homeAskPlaceholder,
                      hintStyle: const TextStyle(
                        color: AppColors.inkSoft,
                        fontSize: 14,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.ink,
                    ),
                    textInputAction: TextInputAction.search,
                  ),
                ),
                GestureDetector(
                  onTap: widget.onSpeak,
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.amber, AppColors.amberDeep],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.amber.withOpacity(0.6),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.mic_none_rounded,
                            size: 16, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          s.homeSpeak,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Context chips ────────────────────────────────────────────────────────────

class _ContextChips extends StatelessWidget {
  const _ContextChips({
    required this.s,
    required this.ref,
    required this.context,
  });

  final S s;
  final WidgetRef ref;
  final BuildContext context;

  @override
  Widget build(BuildContext _) {
    void preselect(String id, String label) {
      log.d(_tag, 'category tap',
          data: {'id': id, 'bypassPicker': true, 'source': 'context_chip'});
      ref.read(bookingNotifierProvider.notifier).setCategory(id, label);
      this.context.go('/customer/booking/description');
    }

    final chips = <_ChipSpec>[
      _ChipSpec(
        label: s.homeChipEmergency,
        amber: true,
        iconEmoji: '🚨',
        onTap: () {
          log.d(_tag, 'fab tap', data: {'source': 'emergency_chip'});
          this.context.go('/customer/booking/category');
        },
      ),
      _ChipSpec(
        label: s.homeChipPreGuest,
        onTap: () => preselect('cleaning', s.catCleaning),
      ),
      _ChipSpec(
        label: s.homeChipAcCheck,
        onTap: () => preselect('ac_maintenance', s.catAC),
      ),
      _ChipSpec(
        label: s.homeChipQuickPlumb,
        onTap: () => preselect('plumbing', s.catPlumbing),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsetsDirectional.only(start: 20, end: 20),
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            for (int i = 0; i < chips.length; i++) ...[
              _ContextChip(spec: chips[i]),
              if (i != chips.length - 1) const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChipSpec {
  final String label;
  final bool amber;
  final String? iconEmoji;
  final VoidCallback onTap;
  _ChipSpec({
    required this.label,
    required this.onTap,
    this.amber = false,
    this.iconEmoji,
  });
}

class _ContextChip extends StatelessWidget {
  const _ContextChip({required this.spec});
  final _ChipSpec spec;

  @override
  Widget build(BuildContext context) {
    final bg = spec.amber ? AppColors.amberSoft : AppColors.paper;
    final border = spec.amber ? AppColors.amber : AppColors.line;
    final fg = spec.amber ? AppColors.amberDeep : AppColors.ink;
    return InkWell(
      onTap: spec.onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (spec.iconEmoji != null) ...[
              Text(spec.iconEmoji!,
                  style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
            ],
            Text(
              spec.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Browse Services (header + feature tile + 2-col grid) ─────────────────────

class _BrowseSection extends StatelessWidget {
  const _BrowseSection({
    required this.s,
    required this.ref,
    required this.context,
    required this.query,
  });

  final S s;
  final WidgetRef ref;
  final BuildContext context;
  final String query;

  @override
  Widget build(BuildContext _) {
    final asyncCategories = ref.watch(categoriesProvider);
    final locale = ref.watch(localeProvider);

    // Hardcoded fallback used while the API call is in flight or fails on a
    // cold start with no cached value. Renders an immediate 6-tile grid using
    // the existing `s.catX` keys + Material icons so the home screen never
    // shows an empty state. Once `categoriesProvider` resolves, the dynamic
    // list takes over.
    final fallback = <ServiceCategory>[
      const ServiceCategory(slug: 'cleaning', nameEn: 'Cleaning', nameAr: 'التنظيف', iconKey: 'cleaning_services', iconUrl: null, requiresSkillTest: true),
      const ServiceCategory(slug: 'plumbing', nameEn: 'Plumbing', nameAr: 'السباكة', iconKey: 'plumbing', iconUrl: null, requiresSkillTest: true),
      const ServiceCategory(slug: 'electrical', nameEn: 'Electrical', nameAr: 'الكهرباء', iconKey: 'electrical_bolt', iconUrl: null, requiresSkillTest: true),
      const ServiceCategory(slug: 'moving', nameEn: 'Moving', nameAr: 'النقل', iconKey: 'local_shipping', iconUrl: null, requiresSkillTest: false),
      const ServiceCategory(slug: 'painting', nameEn: 'Painting', nameAr: 'الدهان', iconKey: 'format_paint', iconUrl: null, requiresSkillTest: true),
      const ServiceCategory(slug: 'carpentry', nameEn: 'Carpentry', nameAr: 'النجارة', iconKey: 'handyman', iconUrl: null, requiresSkillTest: true),
    ];

    final allCategories = asyncCategories.valueOrNull ?? fallback;
    // The FeatureTile above the grid handles `ac_maintenance` exclusively.
    final cats = allCategories
        .where((c) => c.slug != 'ac_maintenance')
        .toList(growable: false);

    void onPick(String id, String label) {
      log.d(_tag, 'category tap',
          data: {'id': id, 'bypassPicker': true, 'source': 'grid'});
      ref.read(bookingNotifierProvider.notifier).setCategory(id, label);
      this.context.go('/customer/booking/description');
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  s.homeBrowseServices,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Text(
                // +1 for the AC FeatureTile above the grid.
                s.homeCategoriesCount(cats.length + 1),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.inkSoft,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _FeatureTile(
            s: s,
            onTap: () {
              // Resolve the AC category's localized name dynamically when
              // available; fall back to the seeded `s.catAC` string so the
              // booking summary still reads correctly on a cold start.
              final ac = allCategories.firstWhere(
                (c) => c.slug == 'ac_maintenance',
                orElse: () => const ServiceCategory(
                  slug: 'ac_maintenance',
                  nameEn: 'AC Maintenance',
                  nameAr: 'صيانة المكيفات',
                  iconKey: 'ac_unit',
                  iconUrl: null,
                  requiresSkillTest: false,
                ),
              );
              onPick('ac_maintenance', ac.localizedName(locale));
            },
          ),
          const SizedBox(height: 10),
          GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.35,
            children: [
              for (int i = 0; i < cats.length; i++)
                _CategoryTile(
                  label: cats[i].localizedName(locale),
                  icon: cats[i].iconData,
                  popular: i == 0,
                  popularLabel: s.homePopularBadge,
                  onTap: () => onPick(
                    cats[i].slug,
                    cats[i].localizedName(locale),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({required this.s, required this.onTap});
  final S s;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.brandBlue,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(16),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            const PositionedDirectional(
              end: -20,
              bottom: -20,
              child: Opacity(
                opacity: 0.15,
                child: Icon(
                  Icons.ac_unit_rounded,
                  size: 160,
                  color: Colors.white,
                ),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.amber,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      s.homeSummerPick.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brandBlueDeep,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.55,
                    child: Text(
                      s.homeAcService,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.homeAcServiceSub,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.popular,
    required this.popularLabel,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool popular;
  final String popularLabel;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.paper,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(14),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 20, color: AppColors.brandBlue),
                ),
                const Spacer(),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    height: 1.2,
                  ),
                ),
              ],
            ),
            if (popular)
              PositionedDirectional(
                top: 0,
                end: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.amberSoft,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    popularLabel.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: AppColors.amberDeep,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Book Again (horizontal list of recent Paid jobs) ─────────────────────────

class _BookAgainSection extends ConsumerWidget {
  const _BookAgainSection({
    required this.s,
    required this.ref,
    required this.context,
  });

  final S s;
  final WidgetRef ref;
  final BuildContext context;

  @override
  Widget build(BuildContext _, WidgetRef __) {
    final recentAsync = ref.watch(_recentJobsProvider);
    return recentAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (jobs) {
        if (jobs.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        s.homeBookAgain,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => context.go('/customer/history'),
                      child: Text(
                        s.homeHistoryLink,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 150,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsetsDirectional.symmetric(horizontal: 20),
                  itemCount: jobs.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) => _BookAgainCard(
                    s: s,
                    job: jobs[i],
                    onBookAgain: () {
                      // Prefer the dynamic category name from the API; fall
                      // back to the seeded `s.catX` switch when the slug
                      // isn't in the active list (deactivated or new install
                      // before first fetch).
                      final locale = ref.read(localeProvider);
                      final dynamicCat = ref
                          .read(categoryBySlugProvider(jobs[i].categoryId));
                      final label = dynamicCat?.localizedName(locale) ??
                          _labelForCategory(s, jobs[i].categoryId);
                      log.d(_tag, 'category tap', data: {
                        'id': jobs[i].categoryId,
                        'bypassPicker': true,
                        'source': 'book_again',
                      });
                      ref
                          .read(bookingNotifierProvider.notifier)
                          .setCategory(jobs[i].categoryId, label);
                      context.go('/customer/booking/description');
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _labelForCategory(S s, String id) {
    switch (id) {
      case 'cleaning':
        return s.catCleaning;
      case 'plumbing':
        return s.catPlumbing;
      case 'electrical':
        return s.catElectrical;
      case 'moving':
        return s.catMoving;
      case 'painting':
        return s.catPainting;
      case 'ac_maintenance':
        return s.catAC;
      case 'carpentry':
        return s.catCarpentry;
      default:
        return s.catOther;
    }
  }
}

class _BookAgainCard extends StatelessWidget {
  const _BookAgainCard({
    required this.s,
    required this.job,
    required this.onBookAgain,
  });

  final S s;
  final _RecentJob job;
  final VoidCallback onBookAgain;

  @override
  Widget build(BuildContext context) {
    final name = (job.providerName ?? '').trim();
    final displayName = name.isEmpty
        ? _BookAgainSection._labelForCategory(s, job.categoryId)
        : name;
    final initial = displayName.isEmpty ? '•' : displayName.characters.first;
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.brandBlueSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      _BookAgainSection._labelForCategory(s, job.categoryId),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.inkSoft,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: onBookAgain,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.amberSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      s.homeBookAgain,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.amberDeep,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_rounded,
                        size: 14, color: AppColors.amberDeep),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Referral strip ───────────────────────────────────────────────────────────

class _ReferralStrip extends StatelessWidget {
  const _ReferralStrip({required this.s, required this.onTap});
  final S s;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.amber,
              style: BorderStyle.solid,
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.amberSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.auto_awesome,
                    size: 18, color: AppColors.amberDeep),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  s.homeReferTitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right,
                  size: 18, color: AppColors.inkSoft),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Filtered grid (shown when user types in ask bar) ─────────────────────────

class _FilteredGrid extends StatelessWidget {
  const _FilteredGrid({
    required this.s,
    required this.ref,
    required this.context,
    required this.query,
  });

  final S s;
  final WidgetRef ref;
  final BuildContext context;
  final String query;

  @override
  Widget build(BuildContext _) {
    final all = <({String id, String label, IconData icon})>[
      (id: 'cleaning',     label: s.catCleaning,   icon: Icons.cleaning_services),
      (id: 'plumbing',     label: s.catPlumbing,   icon: Icons.plumbing),
      (id: 'electrical',   label: s.catElectrical, icon: Icons.electric_bolt),
      (id: 'moving',       label: s.catMoving,     icon: Icons.local_shipping),
      (id: 'painting',     label: s.catPainting,   icon: Icons.format_paint),
      (id: 'ac_maintenance', label: s.catAC,       icon: Icons.ac_unit),
      (id: 'carpentry',    label: s.catCarpentry,  icon: Icons.carpenter),
      (id: 'other',        label: s.catOther,      icon: Icons.more_horiz),
    ];
    final q = query.toLowerCase();
    final filtered = all
        .where((c) => c.label.toLowerCase().contains(q))
        .toList();

    void onPick(String id, String label) {
      log.d(_tag, 'category tap',
          data: {'id': id, 'bypassPicker': true, 'source': 'search_filtered'});
      ref.read(bookingNotifierProvider.notifier).setCategory(id, label);
      this.context.go('/customer/booking/description');
    }

    if (filtered.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
        child: Center(
          child: Text(
            s.homeNoResults,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.inkSoft,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: GridView.count(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.35,
        children: [
          for (final c in filtered)
            _CategoryTile(
              label: c.label,
              icon: c.icon,
              popular: false,
              popularLabel: s.homePopularBadge,
              onTap: () => onPick(c.id, c.label),
            ),
        ],
      ),
    );
  }
}
