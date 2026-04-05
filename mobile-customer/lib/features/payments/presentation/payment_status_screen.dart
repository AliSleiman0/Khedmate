import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../data/payment_repository.dart';
import '../../booking/presentation/booking_provider.dart';

/// Shows the payment lifecycle for a past job.
/// Reachable from booking history: context.push('/payment/status/$jobId')
class PaymentStatusScreen extends ConsumerStatefulWidget {
  final String jobId;
  const PaymentStatusScreen({super.key, required this.jobId});

  @override
  ConsumerState<PaymentStatusScreen> createState() => _PaymentStatusScreenState();
}

class _PaymentStatusScreenState extends ConsumerState<PaymentStatusScreen> {
  Map<String, dynamic>? _transaction;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(paymentRepositoryProvider);
      final transactions = await repo.getMyTransactions();
      final tx = transactions.firstWhere(
        (t) => t['jobId'] == widget.jobId,
        orElse: () => {},
      );
      setState(() {
        _transaction = tx.isEmpty ? null : tx;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'تعذّر تحميل بيانات الدفع';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.brandBlue,
          foregroundColor: Colors.white,
          title: const Text('حالة الدفع',
              style: TextStyle(
                  fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        ),
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.brandBlue))
            : _error != null
                ? _ErrorView(message: _error!, onRetry: _load)
                : _transaction == null
                    ? const _NotFoundView()
                    : _TransactionBody(tx: _transaction!),
      ),
    );
  }
}

class _TransactionBody extends StatelessWidget {
  final Map<String, dynamic> tx;
  const _TransactionBody({required this.tx});

  @override
  Widget build(BuildContext context) {
    final status = tx['status'] as String? ?? '';
    final amount = (tx['grossAmount'] as num?)?.toDouble() ?? 0;
    final holdUntil = tx['holdUntil'] != null
        ? DateTime.tryParse(tx['holdUntil'] as String)
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status chip
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: _statusColor(status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _statusColor(status)),
              ),
              child: Text(
                _statusLabel(status),
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  color: _statusColor(status),
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _Row('المبلغ المدفوع', '\$${amount.toStringAsFixed(2)}'),
                  const Divider(height: 20),
                  _Row('رسوم الخدمة', 'شامل رسوم الخدمة (20%)'),
                  if (holdUntil != null) ...[
                    const Divider(height: 20),
                    _Row(
                      'تاريخ الإفراج',
                      'سيتم الإفراج عن الدفعة بتاريخ '
                          '${holdUntil.day}/${holdUntil.month}/${holdUntil.year}',
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status) => switch (status) {
        'Pending' => 'في الانتظار',
        'Paid' => 'مدفوع',
        'Held' => 'محجوز (فترة النزاع)',
        'Released' => 'تم التحويل',
        'Disputed' => 'نزاع',
        'Refunded' => 'مسترجع',
        _ => status,
      };

  Color _statusColor(String status) => switch (status) {
        'Released' => AppColors.success,
        'Disputed' => Colors.red,
        'Refunded' => Colors.orange,
        'Held' => AppColors.amber,
        _ => AppColors.brandBlue,
      };
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(label,
              style: const TextStyle(
                  fontFamily: 'Cairo', fontSize: 13, color: Colors.grey)),
        ),
        Expanded(
          flex: 3,
          child: Text(value,
              style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  color: AppColors.textPrimary),
              textAlign: TextAlign.left),
        ),
      ],
    );
  }
}

class _NotFoundView extends StatelessWidget {
  const _NotFoundView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'لا توجد بيانات دفع لهذا الطلب',
        style: TextStyle(fontFamily: 'Cairo', fontSize: 16, color: Colors.grey),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandBlue,
                foregroundColor: Colors.white),
            child: const Text('إعادة المحاولة',
                style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }
}
