import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/onboarding_providers.dart';

class IdUploadScreen extends ConsumerStatefulWidget {
  const IdUploadScreen({super.key});

  @override
  ConsumerState<IdUploadScreen> createState() => _IdUploadScreenState();
}

class _IdUploadScreenState extends ConsumerState<IdUploadScreen> {
  final _picker = ImagePicker();
  String _documentType = 'NationalId';
  XFile? _frontImage;
  XFile? _backImage;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('رفع وثائق الهوية'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'ارفع صورة واضحة من بطاقة هويتك الوطنية أو جواز سفرك',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          const Text(
            'نوع الوثيقة',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _documentType,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(
                value: 'NationalId',
                child: Text('بطاقة هوية وطنية'),
              ),
              DropdownMenuItem(
                value: 'Passport',
                child: Text('جواز سفر'),
              ),
              DropdownMenuItem(
                value: 'ResidencePermit',
                child: Text('تصريح إقامة'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _documentType = value!;
                // If passport selected, back image not needed
                if (_documentType == 'Passport') _backImage = null;
              });
            },
          ),
          const SizedBox(height: 24),
          _buildImagePicker(
            title: 'الوجه الأمامي',
            image: _frontImage,
            onPick: () => _pickImage(front: true),
            onRemove: () => setState(() => _frontImage = null),
          ),
          if (_documentType != 'Passport') ...[
            const SizedBox(height: 16),
            _buildImagePicker(
              title: 'الوجه الخلفي',
              image: _backImage,
              onPick: () => _pickImage(front: false),
              onRemove: () => setState(() => _backImage = null),
            ),
          ],
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _canSubmit ? _submitDocuments : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isSubmitting
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('إرسال للمراجعة', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker({
    required String title,
    required XFile? image,
    required VoidCallback onPick,
    required VoidCallback onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onPick,
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: image == null
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate,
                          size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('اضغط لاختيار صورة'),
                    ],
                  )
                : Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(image.path),
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: onRemove,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage({required bool front}) async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختر مصدر الصورة'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop(ImageSource.camera),
            icon: const Icon(Icons.camera_alt),
            label: const Text('الكاميرا'),
          ),
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
            icon: const Icon(Icons.photo_library),
            label: const Text('المعرض'),
          ),
        ],
      ),
    );

    if (source == null) return;

    final image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        if (front) {
          _frontImage = image;
        } else {
          _backImage = image;
        }
      });
    }
  }

  bool get _canSubmit {
    if (_isSubmitting) return false;
    if (_frontImage == null) return false;
    if (_documentType != 'Passport' && _backImage == null) return false;
    return true;
  }

  Future<void> _submitDocuments() async {
    setState(() => _isSubmitting = true);

    try {
      final service = ref.read(onboardingApiServiceProvider);
      await service.submitDocuments(
        documentType: _documentType,
        frontImage: _frontImage!,
        backImage: _backImage,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إرسال وثائقك، سيتم المراجعة خلال 24 ساعة'),
          backgroundColor: Colors.green,
        ),
      );

      ref.invalidate(onboardingStatusProvider);
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
