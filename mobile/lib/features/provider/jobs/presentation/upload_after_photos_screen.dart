import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../data/job_repository.dart';
import 'active_job_provider.dart';

const _tag = 'UploadAfterPhotos';

class _UploadAfterPhotosState {
  final List<XFile> selectedPhotos;
  final bool isUploading;

  const _UploadAfterPhotosState({
    this.selectedPhotos = const [],
    this.isUploading = false,
  });

  _UploadAfterPhotosState copyWith({
    List<XFile>? selectedPhotos,
    bool? isUploading,
  }) =>
      _UploadAfterPhotosState(
        selectedPhotos: selectedPhotos ?? this.selectedPhotos,
        isUploading: isUploading ?? this.isUploading,
      );
}

class _UploadAfterPhotosNotifier
    extends FamilyNotifier<_UploadAfterPhotosState, String> {
  static const int _maxPhotos = 5;
  static const int _maxSizeBytes = 5 * 1024 * 1024;

  @override
  _UploadAfterPhotosState build(String arg) => const _UploadAfterPhotosState();

  Future<void> pickPhoto(BuildContext context, ImageSource source,
      {required String tooLargeMessage}) async {
    if (state.selectedPhotos.length >= _maxPhotos) {
      log.d(_tag, 'pick blocked', data: {'reason': 'max_reached'});
      return;
    }

    log.d(_tag, 'pick image', data: {'source': source.name});
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 90);
    if (file == null) return;

    final bytes = await file.length();
    if (bytes > _maxSizeBytes) {
      log.w(_tag, 'pick rejected',
          data: {'reason': 'too_large', 'bytes': bytes});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tooLargeMessage,
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        );
      }
      return;
    }

    log.d(_tag, 'pick ok',
        data: {'bytes': bytes, 'count': state.selectedPhotos.length + 1});
    state = state.copyWith(
      selectedPhotos: [...state.selectedPhotos, file],
    );
  }

  void removePhoto(int index) {
    log.d(_tag, 'remove', data: {'index': index});
    final updated = List<XFile>.from(state.selectedPhotos)..removeAt(index);
    state = state.copyWith(selectedPhotos: updated);
  }

  Future<void> uploadAndComplete(BuildContext context, WidgetRef ref,
      {required String uploadFailedMessage}) async {
    if (state.selectedPhotos.isEmpty || state.isUploading) {
      log.d(_tag, 'advance blocked', data: {'reason': 'no_after_photo'});
      return;
    }

    log.d(_tag, 'upload start',
        data: {'jobId': arg, 'count': state.selectedPhotos.length});
    state = state.copyWith(isUploading: true);

    try {
      await ref
          .read(jobRepositoryProvider)
          .uploadAfterPhotos(arg, state.selectedPhotos);

      log.i(_tag, 'upload ok', data: {'jobId': arg});
      await ref.read(activeJobNotifierProvider(arg).notifier).advanceStatus();

      if (context.mounted) context.pop(true);
    } catch (e) {
      log.e(_tag, 'upload failed', error: e, data: {'jobId': arg});
      state = state.copyWith(isUploading: false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              uploadFailedMessage,
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        );
      }
    }
  }
}

final _uploadAfterPhotosProvider = NotifierProviderFamily<
    _UploadAfterPhotosNotifier,
    _UploadAfterPhotosState,
    String>(_UploadAfterPhotosNotifier.new);

class UploadAfterPhotosScreen extends ConsumerWidget {
  final String jobId;

  const UploadAfterPhotosScreen({super.key, required this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    final state = ref.watch(_uploadAfterPhotosProvider(jobId));
    final notifier = ref.read(_uploadAfterPhotosProvider(jobId).notifier);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.brandBlue,
          foregroundColor: Colors.white,
          leading: const AppBackButton(),
          title: Text(
            s.uploadAfterTitle,
            style: const TextStyle(
                fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.brandBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: AppColors.brandBlue.withOpacity(0.3)),
                ),
                child: Text(
                  s.uploadAfterInstruction,
                  style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      color: AppColors.textPrimary),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _PhotoGrid(
                  photos: state.selectedPhotos,
                  maxPhotos: 5,
                  onAdd: () => _showSourceSheet(context, ref, notifier),
                  onRemove: notifier.removePhoto,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                s.photoCountOf5(state.selectedPhotos.length),
                style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: state.selectedPhotos.isEmpty || state.isUploading
                      ? null
                      : () => notifier.uploadAndComplete(
                            context,
                            ref,
                            uploadFailedMessage: s.uploadFailed,
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.amber,
                    disabledBackgroundColor: AppColors.amber.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: state.isUploading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          s.uploadAndFinish,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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

  void _showSourceSheet(BuildContext context, WidgetRef ref,
      _UploadAfterPhotosNotifier notifier) {
    final s = S.read(ref);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                s.addPhoto,
                style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading:
                    const Icon(Icons.camera_alt, color: AppColors.brandBlue),
                title: Text(s.camera,
                    style: const TextStyle(fontFamily: 'Cairo')),
                onTap: () {
                  Navigator.pop(ctx);
                  notifier.pickPhoto(context, ImageSource.camera,
                      tooLargeMessage: s.photoTooLarge);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library,
                    color: AppColors.brandBlue),
                title: Text(s.gallery,
                    style: const TextStyle(fontFamily: 'Cairo')),
                onTap: () {
                  Navigator.pop(ctx);
                  notifier.pickPhoto(context, ImageSource.gallery,
                      tooLargeMessage: s.photoTooLarge);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  final List<XFile> photos;
  final int maxPhotos;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;

  const _PhotoGrid({
    required this.photos,
    required this.maxPhotos,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: maxPhotos,
      itemBuilder: (ctx, i) {
        if (i < photos.length) {
          return _FilledSlot(
            photo: photos[i],
            onRemove: () => onRemove(i),
          );
        }
        if (i == photos.length && photos.length < maxPhotos) {
          return _AddSlot(onTap: onAdd);
        }
        return _EmptySlot();
      },
    );
  }
}

class _FilledSlot extends StatelessWidget {
  final XFile photo;
  final VoidCallback onRemove;

  const _FilledSlot({required this.photo, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            File(photo.path),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: AppColors.surface,
              child: const Icon(Icons.image, color: AppColors.textSecondary),
            ),
          ),
        ),
        Positioned(
          top: 4,
          left: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: AppColors.danger,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddSlot extends StatelessWidget {
  final VoidCallback onTap;

  const _AddSlot({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.brandBlue.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: AppColors.brandBlue.withOpacity(0.4),
              style: BorderStyle.solid),
        ),
        child: const Icon(
          Icons.add_a_photo,
          color: AppColors.brandBlue,
          size: 32,
        ),
      ),
    );
  }
}

class _EmptySlot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
    );
  }
}
