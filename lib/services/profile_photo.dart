import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Square crop used by the profile editor.
/// `centerX` and `centerY` are 0..1. `zoom` 1 shows the largest square that fits.
Uint8List? cropSquareJpeg(
  Uint8List source, {
  double centerX = 0.5,
  double centerY = 0.5,
  double zoom = 1,
  int edge = 512,
  int quality = 80,
}) {
  final decoded = img.decodeImage(source);
  if (decoded == null || decoded.width < 1 || decoded.height < 1) return null;
  final minSide = decoded.width < decoded.height ? decoded.width : decoded.height;
  final safeZoom = zoom < 1 ? 1.0 : zoom;
  var side = (minSide / safeZoom).round();
  if (side < 1) side = 1;
  if (side > minSide) side = minSide;
  final cx = centerX.clamp(0.0, 1.0) * decoded.width;
  final cy = centerY.clamp(0.0, 1.0) * decoded.height;
  var left = (cx - side / 2).round();
  var top = (cy - side / 2).round();
  if (left < 0) left = 0;
  if (top < 0) top = 0;
  if (left > decoded.width - side) left = decoded.width - side;
  if (top > decoded.height - side) top = decoded.height - side;
  final cropped = img.copyCrop(decoded, x: left, y: top, width: side, height: side);
  final resized = img.copyResize(cropped, width: edge, height: edge);
  return Uint8List.fromList(img.encodeJpg(resized, quality: quality));
}

class ProfilePhotoStore {
  static Future<Directory> appFolder() async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory('${root.path}/profile_photos');
    await dir.create(recursive: true);
    return dir;
  }

  static Future<String> saveBytes(Directory folder, String studentId, Uint8List jpeg) async {
    if (studentId.isEmpty || jpeg.isEmpty) {
      throw ArgumentError('Акс холӣ аст');
    }
    await folder.create(recursive: true);
    final file = File('${folder.path}/$studentId.jpg');
    await file.writeAsBytes(jpeg, flush: true);
    return file.path;
  }

  static bool owns(String path) {
    final normalized = path.replaceAll('\\', '/');
    return normalized.contains('/profile_photos/');
  }

  static Future<void> deleteIfOwned(String? path) async {
    if (path == null || path.isEmpty || !owns(path)) return;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
