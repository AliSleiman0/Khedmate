import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_config.dart';
import '../../../core/constants/colors.dart';
import 'job_detail_provider.dart';
import 'job_feed_provider.dart';

class JobDetailScreen extends ConsumerWidget {
  final String jobId;

  const JobDetailScreen({super.key, required this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(jobDetailNotifierProvider(jobId));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.brandBlue,
          foregroundColor: Colors.white,
          title: const Text(
            'تفاصيل الطلب',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/jobs'),
          ),
        ),
        body: asyncState.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.brandBlue)),
          error: (e, _) => _ExpiredState(onBack: () => context.go('/jobs')),
          data: (state) {
            // Auto-navigate back when expired
            if (state.isExpired && !state.isAccepted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  Future.delayed(const Duration(seconds: 2), () {
                    if (context.mounted) context.go('/jobs');
                  });
                }
              });
            }

            // Navigate to active on accept
            if (state.isAccepted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  ref.read(jobFeedNotifierProvider.notifier).removeJob(jobId);
                  context.go('/navigation/$jobId');
                }
              });
            }

            return _JobDetailBody(
              state: state,
              onAccept: () => ref
                  .read(jobDetailNotifierProvider(jobId).notifier)
                  .acceptJob(),
              onReject: () async {
                await ref
                    .read(jobDetailNotifierProvider(jobId).notifier)
                    .rejectJob();
                if (context.mounted) context.go('/jobs');
              },
            );
          },
        ),
      ),
    );
  }
}

class _JobDetailBody extends StatelessWidget {
  final JobDetailState state;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _JobDetailBody({
    required this.state,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final job = state.job;
    final secs = state.secondsRemaining;
    final mins = secs ~/ 60;
    final sec = secs % 60;

    Color timerColor;
    if (secs > 60) {
      timerColor = Colors.green;
    } else if (secs > 30) {
      timerColor = AppColors.amber;
    } else {
      timerColor = AppColors.danger;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Countdown timer
          _CountdownTimer(
            mins: mins,
            secs: sec,
            color: timerColor,
            totalSecs: secs,
            isExpired: state.isExpired,
          ),

          const SizedBox(height: 20),

          // Category + posted time
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.brandBlue.withOpacity(0.1),
                child:
                    const Icon(Icons.build, color: AppColors.brandBlue, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.categoryName,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'منذ ${DateTime.now().difference(job.postedAt).inMinutes} دقيقة',
                      style: const TextStyle(
                          fontFamily: 'Cairo',
                          color: AppColors.textSecondary,
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Description
          _SectionCard(
            title: 'وصف الخدمة',
            child: Text(
              job.description,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
            ),
          ),

          const SizedBox(height: 12),

          // Map (non-interactive)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 180,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(job.latitude, job.longitude),
                  initialZoom: 14,
                  interactionOptions:
                      const InteractionOptions(flags: InteractiveFlag.none),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.khudmati.provider',
                  ),
                  MarkerLayer(markers: [
                    Marker(
                      point: LatLng(job.latitude, job.longitude),
                      child: const Icon(Icons.location_pin,
                          color: Colors.red, size: 36),
                    ),
                  ]),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Location info
          _SectionCard(
            title: 'الموقع',
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    color: AppColors.brandBlue, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${job.district}  •  ${job.distanceKm} كم',
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
                  ),
                ),
              ],
            ),
          ),

          // Photos (before only — job is still pending/available at this screen)
          if (job.beforePhotoUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            _SectionCard(
              title: 'صور قبل العمل',
              child: SizedBox(
                height: 80,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: job.beforePhotoUrls
                      .map((url) => Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                '${AppConfig.backendHost}$url',
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
          ],

          const SizedBox(height: 28),

          // Expired message
          if (state.isExpired)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'انتهت مدة القبول',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: AppColors.danger,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

          if (!state.isExpired) ...[
            // Accept button
            ElevatedButton(
              onPressed: onAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'قبول الطلب',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Reject button
            OutlinedButton(
              onPressed: onReject,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey,
                side: const BorderSide(color: Colors.grey),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'رفض',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 17),
              ),
            ),
          ],

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _CountdownTimer extends StatelessWidget {
  final int mins;
  final int secs;
  final Color color;
  final int totalSecs;
  final bool isExpired;

  const _CountdownTimer({
    required this.mins,
    required this.secs,
    required this.color,
    required this.totalSecs,
    required this.isExpired,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 130,
              height: 130,
              child: CircularProgressIndicator(
                value: isExpired ? 0 : totalSecs / 120,
                strokeWidth: 10,
                backgroundColor: Colors.grey.shade200,
                color: color,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isExpired
                      ? '0:00'
                      : '$mins:${secs.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'الوقت المتبقي للقبول',
          style: TextStyle(
            fontFamily: 'Cairo',
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _ExpiredState extends StatelessWidget {
  final VoidCallback onBack;

  const _ExpiredState({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timer_off_outlined,
                size: 64, color: AppColors.danger),
            const SizedBox(height: 16),
            const Text(
              'الطلب لم يعد متاحاً',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onBack,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandBlue,
                  foregroundColor: Colors.white),
              child: const Text('العودة للطلبات',
                  style: TextStyle(fontFamily: 'Cairo')),
            ),
          ],
        ),
      ),
    );
  }
}
