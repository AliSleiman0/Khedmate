import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';

class JobDetailPage extends StatefulWidget {
  final String jobId;
  const JobDetailPage({super.key, required this.jobId});

  @override
  State<JobDetailPage> createState() => _JobDetailPageState();
}

class _JobDetailPageState extends State<JobDetailPage> {
  static const _timeoutSeconds = 120;
  int _remaining = _timeoutSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining <= 1) {
        _autoReject();
      } else {
        setState(() => _remaining--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _autoReject() {
    _timer?.cancel();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('انتهى الوقت — تم رفض الطلب تلقائيًا'),
        backgroundColor: AppColors.danger,
      ),
    );
    context.go('/jobs');
  }

  void _accept() {
    _timer?.cancel();
    context.go('/navigation/${widget.jobId}');
  }

  void _reject() {
    _timer?.cancel();
    context.go('/jobs');
  }

  Color get _timerColor {
    if (_remaining > 60) return AppColors.brandBlue;
    if (_remaining > 30) return AppColors.amber;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    final progress = _remaining / _timeoutSeconds;

    return Scaffold(
      appBar: AppBar(title: Text('طلب #${widget.jobId}')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Countdown timer
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 10,
                      backgroundColor: Colors.grey.shade200,
                      color: _timerColor,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$_remaining',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: _timerColor,
                        ),
                      ),
                      const Text('ثانية', style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _remaining <= 30
                    ? 'انتبه! الوقت ينفد'
                    : 'لديك دقيقتان للرد',
                style: TextStyle(
                  color: _timerColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Job details card
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('تفاصيل الطلب',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const Divider(),
                    _detailRow(Icons.cleaning_services, 'الخدمة', 'تنظيف منزلي'),
                    const SizedBox(height: 8),
                    _detailRow(Icons.location_on, 'الموقع', 'حي النزهة، الرياض'),
                    const SizedBox(height: 8),
                    _detailRow(Icons.directions, 'المسافة', '${(widget.jobId.length % 5) + 1}.${widget.jobId.length % 10} كم'),
                    const SizedBox(height: 8),
                    _detailRow(Icons.description, 'الوصف',
                        'تنظيف شامل للمنزل — 3 غرف وصالة ومطبخ'),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('المبلغ المتوقع',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          '${150 + (widget.jobId.length % 4) * 50} ر.س',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Accept / Reject buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _reject,
                    icon: const Icon(Icons.close),
                    label: const Text('رفض', style: TextStyle(fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      minimumSize: const Size(0, 60),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _accept,
                    icon: const Icon(Icons.check),
                    label: const Text('قبول', style: TextStyle(fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      minimumSize: const Size(0, 60),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 18, color: AppColors.brandBlue),
      const SizedBox(width: 8),
      Text('$label: ', style: const TextStyle(color: AppColors.textSecondary)),
      Expanded(
        child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
      ),
    ],
  );
}
