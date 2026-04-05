import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';

class JobsPage extends StatefulWidget {
  const JobsPage({super.key});

  @override
  State<JobsPage> createState() => _JobsPageState();
}

class _JobsPageState extends State<JobsPage> {
  bool _isOnline = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الطلبات المتاحة'),
        actions: [
          Row(
            children: [
              Text(_isOnline ? 'متصل' : 'غير متصل',
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
              Switch(
                value: _isOnline,
                onChanged: (v) => setState(() => _isOnline = v),
                activeColor: AppColors.success,
                inactiveThumbColor: Colors.white54,
              ),
            ],
          ),
        ],
      ),
      body: _isOnline
          ? ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 5,
              itemBuilder: (context, i) => _JobCard(
                jobId: '${2000 + i}',
                service: ['تنظيف منزلي', 'سباكة', 'كهرباء', 'نقل عفش', 'دهانات'][i],
                distance: '${(i + 1) * 1.5} كم',
                price: (150 + i * 50).toDouble(),
                onTap: () => context.go('/job-detail/${2000 + i}'),
              ),
            )
          : const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi_off, size: 64, color: AppColors.textSecondary),
                  SizedBox(height: 16),
                  Text('أنت غير متصل',
                      style: TextStyle(
                          fontSize: 18, color: AppColors.textSecondary)),
                  SizedBox(height: 8),
                  Text('فعّل التوافر لاستقبال الطلبات',
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: AppColors.brandBlue,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.work), label: 'الطلبات'),
          BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: 'الأرباح'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'الملف الشخصي'),
        ],
        onTap: (i) {
          if (i == 1) context.go('/earnings');
          if (i == 2) context.go('/profile');
        },
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final String jobId;
  final String service;
  final String distance;
  final double price;
  final VoidCallback onTap;

  const _JobCard({
    required this.jobId,
    required this.service,
    required this.distance,
    required this.price,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.amber.withOpacity(0.15),
                radius: 24,
                child: const Icon(Icons.work, color: AppColors.amber),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('طلب #$jobId',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(service,
                        style: const TextStyle(color: AppColors.textSecondary)),
                    Text(distance,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${price.toInt()} ر.س',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.success),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
