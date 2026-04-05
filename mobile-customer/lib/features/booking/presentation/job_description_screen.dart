import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/colors.dart';
import 'booking_provider.dart';

class JobDescriptionScreen extends ConsumerStatefulWidget {
  const JobDescriptionScreen({super.key});

  @override
  ConsumerState<JobDescriptionScreen> createState() => _JobDescriptionScreenState();
}

class _JobDescriptionScreenState extends ConsumerState<JobDescriptionScreen> {
  final _controller = TextEditingController();
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final desc = ref.read(bookingNotifierProvider).valueOrNull?.description ?? '';
    _controller.text = desc;
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isValid => _controller.text.trim().length >= 20;

  Future<void> _pickPhoto() async {
    final booking = ref.read(bookingNotifierProvider).valueOrNull;
    if (booking == null || booking.photos.length >= 3) return;

    final xFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1920,
    );
    if (xFile == null) return;

    ref.read(bookingNotifierProvider.notifier).addPhoto(File(xFile.path));
  }

  @override
  Widget build(BuildContext context) {
    final booking = ref.watch(bookingNotifierProvider).valueOrNull;
    final photos = booking?.photos ?? [];
    final categoryName = booking?.categoryName ?? '';
    final charCount = _controller.text.trim().length;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.brandBlue,
          foregroundColor: Colors.white,
          title: const Text(
            'تفاصيل الخدمة',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/booking/category'),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category chip
              if (categoryName.isNotEmpty)
                Chip(
                  label: Text(
                    categoryName,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: AppColors.brandBlue,
                ),
              const SizedBox(height: 16),

              // Description field
              TextField(
                controller: _controller,
                maxLines: 6,
                maxLength: 500,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  hintText: 'صِف المشكلة أو الخدمة المطلوبة',
                  hintStyle: const TextStyle(fontFamily: 'Cairo'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.brandBlue, width: 2),
                  ),
                  counterText: '',
                ),
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 15),
                onChanged: (v) {
                  ref.read(bookingNotifierProvider.notifier).setDescription(v);
                },
              ),

              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (!_isValid && charCount > 0)
                    const Text(
                      'الوصف قصير جداً، أضف تفاصيل أكثر',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  Text(
                    '$charCount / 500',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: _isValid ? Colors.grey : Colors.red,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Photo upload
              Row(
                children: [
                  const Text(
                    'صور (اختياري)',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${photos.length}/3',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  // Add photo button
                  if (photos.length < 3)
                    GestureDetector(
                      onTap: _pickPhoto,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.brandBlue, width: 1.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.add_a_photo,
                            color: AppColors.brandBlue, size: 32),
                      ),
                    ),

                  const SizedBox(width: 8),

                  // Thumbnails
                  ...photos.asMap().entries.map((entry) {
                    final i = entry.key;
                    final file = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              file,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: GestureDetector(
                              onTap: () => ref
                                  .read(bookingNotifierProvider.notifier)
                                  .removePhoto(i),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(2),
                                child: const Icon(Icons.close,
                                    color: Colors.white, size: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),

              const SizedBox(height: 40),

              // Next button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isValid
                      ? () {
                          ref
                              .read(bookingNotifierProvider.notifier)
                              .setDescription(_controller.text.trim());
                          context.go('/booking/location');
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                  child: const Text(
                    'التالي',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
