import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

/// Supabase Storage 이미지 업로드 / 이미지 선택 헬퍼.
class StorageService {
  static SupabaseClient get _client => Supabase.instance.client;

  /// 이미지를 업로드하고 접근 가능한 URL 을 반환합니다.
  /// menu-images 는 public URL, 그 외(business-licenses 등)는 서명된 URL.
  static Future<String?> uploadImage({
    required XFile file,
    required String bucket,
    required String path,
  }) async {
    try {
      final bytes = await file.readAsBytes();
      final ext = file.name.contains('.') ? file.name.split('.').last : 'jpg';
      final fileName = '$path.$ext';

      await _client.storage.from(bucket).uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(contentType: 'image/$ext', upsert: true),
          );

      if (bucket == 'menu-images') {
        return _client.storage.from(bucket).getPublicUrl(fileName);
      } else {
        // private bucket - 1년 유효 서명 URL
        return await _client.storage
            .from(bucket)
            .createSignedUrl(fileName, 31536000);
      }
    } catch (e) {
      debugPrint('이미지 업로드 실패: $e');
      return null;
    }
  }

  static Future<XFile?> pickImage() async {
    try {
      final picker = ImagePicker();
      return await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
    } catch (e) {
      debugPrint('이미지 선택 실패: $e');
      return null;
    }
  }
}
