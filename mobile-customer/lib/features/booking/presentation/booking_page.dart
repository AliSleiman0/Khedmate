import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';

class BookingPage extends StatefulWidget {
  const BookingPage({super.key});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  int _step = 0;
  final _descController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void dispose() {
    _descController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حجز جديد')),
      body: Stepper(
        currentStep: _step,
        onStepContinue: () {
          if (_step < 2) {
            setState(() => _step++);
          } else {
            _submitBooking(context);
          }
        },
        onStepCancel: () {
          if (_step > 0) setState(() => _step--);
          else context.go('/home');
        },
        controlsBuilder: (context, details) => Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Row(
            children: [
              ElevatedButton(
                onPressed: details.onStepContinue,
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(120, 48)),
                child: Text(_step < 2 ? 'التالي' : 'تأكيد الحجز'),
              ),
              if (_step > 0) ...[
                const SizedBox(width: 12),
                TextButton(
                  onPressed: details.onStepCancel,
                  child: const Text('السابق'),
                ),
              ],
            ],
          ),
        ),
        steps: [
          Step(
            title: const Text('وصف الخدمة'),
            content: TextField(
              controller: _descController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'صف الخدمة المطلوبة بالتفصيل...',
              ),
            ),
            isActive: _step >= 0,
            state: _step > 0 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('الموقع'),
            content: Column(
              children: [
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    hintText: 'العنوان',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.my_location),
                  label: const Text('استخدام موقعي الحالي'),
                ),
              ],
            ),
            isActive: _step >= 1,
            state: _step > 1 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('تأكيد الطلب'),
            content: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ملخص الطلب',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const Divider(),
                    Text('الوصف: ${_descController.text}'),
                    const SizedBox(height: 4),
                    Text('العنوان: ${_addressController.text}'),
                  ],
                ),
              ),
            ),
            isActive: _step >= 2,
          ),
        ],
      ),
    );
  }

  void _submitBooking(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم إرسال طلبك بنجاح — بانتظار مزود الخدمة'),
        backgroundColor: AppColors.success,
      ),
    );
    context.go('/tracking/demo-job-id');
  }
}
