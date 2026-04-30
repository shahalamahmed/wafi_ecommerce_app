import 'dart:io';

import 'package:dio/dio.dart';
import 'package:wafi_ecommerce_app/core/constants/cloudinary.dart';

class CloudinaryMediaService {
  CloudinaryMediaService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<String> uploadProfileImage({
    required String userId,
    required String imagePath,
  }) {
    return _uploadImage(
      imagePath: imagePath,
      assetFolder: 'wafi/profile_photos/$userId',
    );
  }

  Future<List<String>> uploadProductImages(
    List<String> imagePaths, {
    required String folderId,
  }) async {
    final uploads = <String>[];
    for (final imagePath in imagePaths) {
      uploads.add(
        await _uploadImage(
          imagePath: imagePath,
          assetFolder: 'wafi/products/$folderId',
        ),
      );
    }
    return uploads;
  }

  Future<String> _uploadImage({
    required String imagePath,
    required String assetFolder,
  }) async {
    if (!CloudinaryConfig.isConfigured) {
      throw Exception(
        'Cloudinary is not configured. Set CLOUDINARY_CLOUD_NAME and CLOUDINARY_UPLOAD_PRESET.',
      );
    }

    final file = File(imagePath);
    if (!file.existsSync()) {
      throw Exception('Selected image file was not found on device.');
    }

    final fileName = imagePath.split(RegExp(r'[\\/]')).last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(imagePath, filename: fileName),
      'upload_preset': CloudinaryConfig.uploadPreset,
      'asset_folder': assetFolder,
    });

    Response<Map<String, dynamic>> response;
    try {
      response = await _dio.post<Map<String, dynamic>>(
        'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/upload',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          responseType: ResponseType.json,
        ),
      );
    } on DioException catch (error) {
      final payload = error.response?.data;
      final message = switch (payload) {
        Map<String, dynamic>() => payload['error']?['message']?.toString(),
        _ => null,
      };

      throw Exception(
        message?.trim().isNotEmpty == true
            ? 'Cloudinary upload failed: ${message!.trim()}'
            : 'Cloudinary upload failed. Check upload preset configuration and allowed formats.',
      );
    }

    final secureUrl = (response.data?['secure_url'] as String?)?.trim() ?? '';
    if (secureUrl.isEmpty) {
      throw Exception('Cloudinary upload failed to return a valid image URL.');
    }

    return secureUrl;
  }
}
