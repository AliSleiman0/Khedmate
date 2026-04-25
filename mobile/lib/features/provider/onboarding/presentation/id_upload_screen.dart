import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../data/onboarding_api_service.dart';

const _tag = 'IdUploadScreen';

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
    final s = S.of(ref);
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(s.idUploadTitle),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            s.idUploadInstruction,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            s.idDocType,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _documentType,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: [
              DropdownMenuItem(
                value: 'NationalId',
                child: Text(s.idNationalId),
              ),
              DropdownMenuItem(
                value: 'Passport',
                child: Text(s.idPassport),
              ),
              DropdownMenuItem(
                value: 'ResidencePermit',
                child: Text(s.idResidencePermit),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _documentType = value!;
                if (_documentType == 'Passport') _backImage = null;
              });
            },
          ),
          const SizedBox(height: 24),
          _buildImagePicker(
            title: s.idFrontSide,
            tapHint: s.idTapToSelect,
            image: _frontImage,
            onPick: () => _pickImage(front: true),
            onRemove: () => setState(() => _frontImage = null),
          ),
          if (_documentType != 'Passport') ...[
            const SizedBox(height: 16),
            _buildImagePicker(
              title: s.idBackSide,
              tapHint: s.idTapToSelect,
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
                : Text(s.idSubmit, style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker({
    required String title,
    required String tapHint,
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
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_photo_alternate,
                          size: 48, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text(tapHint),
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
    final s = S.read(ref);
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.idChooseSource),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop(ImageSource.camera),
            icon: const Icon(Icons.camera_alt),
            label: Text(s.camera),
          ),
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
            icon: const Icon(Icons.photo_library),
            label: Text(s.gallery),
          ),
        ],
      ),
    );

    if (source == null) return;

    log.d(_tag, 'pick image',
        data: {'source': source.name, 'side': front ? 'front' : 'back'});
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
    log.d(_tag, 'submit tap',
        data: {'type': _documentType, 'hasBack': _backImage != null});
    setState(() => _isSubmitting = true);

    try {
      final service = ref.read(onboardingApiServiceProvider);
      await service.submitDocuments(
        documentType: _documentType,
        frontImage: _frontImage!,
        backImage: _backImage,
      );

      if (!mounted) return;

      log.i(_tag, 'submit ok', data: {'type': _documentType});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.read(ref).idSubmitSuccess),
          backgroundColor: Colors.green,
        ),
      );

      ref.invalidate(onboardingStatusProvider);
      Navigator.of(context).pop();
    } catch (e) {
      log.w(_tag, 'submit failed', error: e);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.read(ref).onboardingError(e.toString())),
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
