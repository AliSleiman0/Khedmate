import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../data/ai_repository.dart';
import 'booking_provider.dart';

const _tag = 'JobDescription';

class JobDescriptionScreen extends ConsumerStatefulWidget {
  const JobDescriptionScreen({super.key});

  @override
  ConsumerState<JobDescriptionScreen> createState() =>
      _JobDescriptionScreenState();
}

class _JobDescriptionScreenState
    extends ConsumerState<JobDescriptionScreen> {
  final _controller = TextEditingController();
  final _picker = ImagePicker();
  bool _isImprovingWithAi = false;

  @override
  void initState() {
    super.initState();
    final desc =
        ref.read(bookingNotifierProvider).valueOrNull?.description ?? '';
    _controller.text = desc;
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isValid => _controller.text.trim().length >= 20;

  Future<void> _improveWithAi() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      log.d(_tag, 'improve blocked', data: {'reason': 'empty'});
      return;
    }

    final categoryName =
        ref.read(bookingNotifierProvider).valueOrNull?.categoryName ?? '';

    log.d(_tag, 'improve start',
        data: {'inputLen': text.length, 'category': categoryName});
    setState(() => _isImprovingWithAi = true);

    try {
      final repo = ref.read(aiRepositoryProvider);
      final improved = await repo.improveDescription(
        roughDescription: text,
        categoryName: categoryName,
      );
      if (!mounted) return;
      log.i(_tag, 'improve ok', data: {'outputLen': improved.length});
      _showAiPreviewSheet(improved);
    } catch (e) {
      log.w(_tag, 'improve failed', error: e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            S.read(ref).descAiError,
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isImprovingWithAi = false);
    }
  }

  void _showAiPreviewSheet(String improved) {
    final s = S.read(ref);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              16, 20, 16, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.auto_awesome,
                      color: AppColors.amber, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    s.descAiImproved,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  improved,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.brandBlue),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        s.descAiDismiss,
                        style: const TextStyle(
                            fontFamily: 'Cairo',
                            color: AppColors.brandBlue),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        log.d(_tag, 'ai use tap',
                            data: {'len': improved.length});
                        _controller.text = improved;
                        ref
                            .read(bookingNotifierProvider.notifier)
                            .setDescription(improved);
                        Navigator.of(ctx).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        s.descAiUse,
                        style: const TextStyle(fontFamily: 'Cairo'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

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
    final s = S.of(ref);
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
          title: Text(
            s.descScreenTitle,
            style: const TextStyle(
                fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
          leading: const AppBackButton(),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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

              TextField(
                controller: _controller,
                maxLines: 6,
                maxLength: 500,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  hintText: s.descHint,
                  hintStyle: const TextStyle(fontFamily: 'Cairo'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppColors.brandBlue, width: 2),
                  ),
                  counterText: '',
                ),
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 15),
                onChanged: (v) {
                  ref
                      .read(bookingNotifierProvider.notifier)
                      .setDescription(v);
                },
              ),

              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (!_isValid && charCount > 0)
                    Text(
                      s.descTooShort,
                      style: const TextStyle(
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

              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: (charCount > 0 && !_isImprovingWithAi)
                      ? _improveWithAi
                      : null,
                  icon: _isImprovingWithAi
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.amber),
                          ),
                        )
                      : const Icon(Icons.auto_awesome,
                          color: AppColors.amber, size: 18),
                  label: Text(
                    _isImprovingWithAi
                        ? s.descAiImproving
                        : s.descAiButton,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      color: AppColors.amber,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: const BorderSide(color: AppColors.amber),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    disabledForegroundColor: Colors.grey,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Text(
                    s.descPhotos,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${photos.length}/3',
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  if (photos.length < 3)
                    GestureDetector(
                      onTap: _pickPhoto,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: AppColors.brandBlue, width: 1.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.add_a_photo,
                            color: AppColors.brandBlue, size: 32),
                      ),
                    ),
                  const SizedBox(width: 8),
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

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isValid
                      ? () {
                          log.d(_tag, 'next tap',
                              data: {'len': _controller.text.trim().length});
                          ref
                              .read(bookingNotifierProvider.notifier)
                              .setDescription(_controller.text.trim());
                          context.go('/customer/booking/location');
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
                  child: Text(
                    s.next,
                    style: const TextStyle(
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
