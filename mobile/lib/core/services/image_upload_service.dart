import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api_client.dart';

final imageUploadServiceProvider = Provider<ImageUploadService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ImageUploadService(apiClient);
});

class ImageUploadService {
  final ApiClient _apiClient;

  ImageUploadService(this._apiClient);

  Future<String?> uploadImage(File imageFile) async {
    try {
      final String mimeType = _getMimeType(imageFile.path);

      // 1. Get Presigned URL
      final response = await _apiClient.post('/upload/presigned-url', data: {
        'mimeType': mimeType,
      });

      final data = response.data;
      final uploadUrl = data['uploadUrl'];
      final publicUrl = data['publicUrl'];

      // 2. Upload to R2 using Dio (PUT)
      await Dio().put(
        uploadUrl,
        data: imageFile.openRead(),
        options: Options(
          headers: {
            'Content-Type': mimeType,
            'Content-Length': await imageFile.length(),
          },
        ),
      );

      return publicUrl;
    } catch (e) {
      print('Image Upload Error: $e');
      return null;
    }
  }

  String _getMimeType(String path) {
    if (path.toLowerCase().endsWith('.png')) return 'image/png';
    if (path.toLowerCase().endsWith('.gif')) return 'image/gif';
    if (path.toLowerCase().endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}
