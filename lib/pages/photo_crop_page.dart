import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../services/profile_photo.dart';

Future<Uint8List?> pickCroppedProfilePhoto(BuildContext context) async {
  final shot = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 2048,
    imageQuality: 85,
  );
  if (shot == null || !context.mounted) return null;
  final bytes = await shot.readAsBytes();
  if (!context.mounted) return null;
  if (bytes.isEmpty) {
    throw PlatformException(code: 'empty_image', message: 'Акс холӣ аст');
  }
  return Navigator.push<Uint8List>(
    context,
    MaterialPageRoute(builder: (_) => PhotoCropPage(bytes: bytes)),
  );
}

class PhotoCropPage extends StatefulWidget {
  final Uint8List bytes;

  const PhotoCropPage({super.key, required this.bytes});

  @override
  State<PhotoCropPage> createState() => _PhotoCropPageState();
}

class _PhotoCropPageState extends State<PhotoCropPage> {
  double centerX = 0.5;
  double centerY = 0.5;
  double zoom = 1;
  bool saving = false;
  String? error;

  Future<void> _save() async {
    if (saving) return;
    setState(() {
      saving = true;
      error = null;
    });
    final cropped = cropSquareJpeg(
      widget.bytes,
      centerX: centerX,
      centerY: centerY,
      zoom: zoom,
    );
    if (!mounted) return;
    if (cropped == null) {
      setState(() {
        saving = false;
        error = 'Акс хонда нашуд. Акси дигар интихоб кунед.';
      });
      return;
    }
    Navigator.pop(context, cropped);
  }

  @override
  Widget build(BuildContext context) {
    final align = Alignment((centerX - 0.5) * 2, (centerY - 0.5) * 2);
    return Scaffold(
      appBar: AppBar(title: const Text('Буридани акс')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            children: [
              const Text(
                'Аксро кашед ва наздик кунед. Шакли чоркунҷа захира мешавад.',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          centerX = (centerX - details.delta.dx / (280 * zoom)).clamp(0.0, 1.0);
                          centerY = (centerY - details.delta.dy / (280 * zoom)).clamp(0.0, 1.0);
                        });
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: ColoredBox(
                          color: const Color(0xFFE2E8F0),
                          child: Transform.scale(
                            scale: zoom,
                            child: Image.memory(
                              widget.bytes,
                              fit: BoxFit.cover,
                              alignment: align,
                              gaplessPlayback: true,
                              errorBuilder: (_, __, ___) => const Center(child: Text('Акс кушода нашуд')),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  const Text('Наздик'),
                  Expanded(
                    child: Slider(
                      value: zoom,
                      min: 1,
                      max: 4,
                      onChanged: saving ? null : (value) => setState(() => zoom = value),
                    ),
                  ),
                ],
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
                ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: saving ? null : _save,
                  child: Text(saving ? 'Сохта мешавад...' : 'Захира кардан'),
                ),
              ),
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(context),
                child: const Text('Бекор'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
