import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://fanclash-api.onrender.com',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Accept': 'application/json'},
    ),
  );

  ApiService() {
    _dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestBody: true,
        responseBody: true,
        error: true,
        logPrint: (object) => debugPrint(object.toString()),
      ),
    );
  }

  // FIXED: Create Post - Image is now REQUIRED
  Future<Map<String, dynamic>> createPost({
    required String userId,
    required String userName,
    required String caption,
    required File image, // Changed to required
    // Removed hashtags as backend doesn't support it
  }) async {
    try {
      debugPrint('🟡 Starting post creation...');
      debugPrint('📱 User ID: $userId');
      debugPrint('👤 User Name: $userName');
      debugPrint('📝 Caption: $caption');
      debugPrint('📁 Image path: ${image.path}');

      // Validate image file
      if (!await image.exists()) {
        throw Exception('Image file does not exist');
      }

      int fileSize = await image.length();
      debugPrint('📏 Image size: ${(fileSize / 1024).toStringAsFixed(2)} KB');

      // Validate file size (max 10MB)
      if (fileSize > 10 * 1024 * 1024) {
        throw Exception('Image too large. Max size: 10MB');
      }

      // Get file extension
      String extension = image.path.split('.').last.toLowerCase();
      List<String> allowedExtensions = ['jpg', 'jpeg', 'png', 'gif'];
      if (!allowedExtensions.contains(extension)) {
        throw Exception('Invalid image format. Allowed: jpg, jpeg, png, gif');
      }

      // Create FormData with EXACT field names backend expects
      FormData formData = FormData.fromMap({
        'userId': userId,
        'userName': userName,
        'caption': caption,
      });

      // Add image with field name 'image' (must be exact)
      formData.files.add(
        MapEntry(
          'image',
          await MultipartFile.fromFile(
            image.path,
            filename:
                'post_${DateTime.now().millisecondsSinceEpoch}.$extension',
          ),
        ),
      );

      debugPrint('🚀 Sending POST request to /api/posts');
      debugPrint('📋 Fields: userId, userName, caption, image');

      Response response = await _dio.post(
        '/api/posts',
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
          validateStatus: (status) => status! < 500, // Allow 400 errors
        ),
      );

      debugPrint('📊 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        Map<String, dynamic> data = response.data;
        if (data['success'] == true) {
          debugPrint('✅ Post created successfully!');
          return data;
        } else {
          throw Exception(data['message'] ?? 'Failed to create post');
        }
      } else if (response.statusCode == 400) {
        // Handle bad request
        Map<String, dynamic>? errorData = response.data;
        String errorMsg = 'Bad Request';

        if (errorData != null) {
          if (errorData['message'] != null) {
            errorMsg = errorData['message'];
          } else if (errorData['error'] != null) {
            errorMsg = errorData['error'];
          }
        }

        throw Exception('Failed: $errorMsg');
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('❌ Dio Error: ${e.type}');
      debugPrint('❌ Error Message: ${e.message}');

      if (e.response != null) {
        debugPrint('❌ Status: ${e.response!.statusCode}');
        debugPrint('❌ Response: ${e.response!.data}');

        // Try to extract error message
        try {
          if (e.response!.data is Map) {
            Map<String, dynamic> errorData = e.response!.data;
            String errorMsg =
                errorData['message'] ??
                errorData['error'] ??
                e.response!.statusMessage ??
                'Unknown error';
            throw Exception(errorMsg);
          }
        } catch (_) {}
      }

      throw Exception('Network error: ${e.message}');
    } catch (e) {
      debugPrint('❌ Error: $e');
      rethrow;
    }
  }

  // Other methods remain the same...
  Future<Map<String, dynamic>> getPosts({
    int page = 1,
    int limit = 20,
    String? userId,
  }) async {
    try {
      Map<String, dynamic> queryParams = {
        'page': page,
        'limit': limit,
        if (userId != null) 'user_id': userId,
      };

      Response response = await _dio.get(
        '/api/posts',
        queryParameters: queryParams,
      );

      return response.data;
    } on DioException catch (e) {
      throw Exception('Error fetching posts: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> getPostById(String postId) async {
    try {
      Response response = await _dio.get('/api/posts/$postId');
      return response.data;
    } on DioException catch (e) {
      throw Exception('Error fetching post: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> getUserPosts(
    String userId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      Response response = await _dio.get(
        '/api/posts/user/$userId',
        queryParameters: {'page': page, 'limit': limit},
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception('Error fetching user posts: ${e.message}');
    }
  }

  Future<bool> deletePost(String postId) async {
    try {
      Response response = await _dio.delete('/api/posts/$postId');
      return response.data['success'] == true;
    } on DioException catch (e) {
      debugPrint('Error deleting post: ${e.message}');
      return false;
    }
  }

  Future<bool> updatePostCaption(String postId, String newCaption) async {
    try {
      Response response = await _dio.put(
        '/api/posts/$postId/caption',
        data: {'caption': newCaption},
      );
      return response.data['success'] == true;
    } on DioException catch (e) {
      debugPrint('Error updating caption: ${e.message}');
      return false;
    }
  }

  Future<Map<String, dynamic>> getPostStats() async {
    try {
      Response response = await _dio.get('/api/posts/stats');
      return response.data;
    } on DioException catch (e) {
      throw Exception('Error fetching stats: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> getUserPostStats(String userId) async {
    try {
      Response response = await _dio.get('/api/posts/user/$userId/stats');
      return response.data;
    } on DioException catch (e) {
      throw Exception('Error fetching user stats: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> healthCheck() async {
    try {
      Response response = await _dio.get('/api/health');
      return response.data;
    } on DioException catch (e) {
      debugPrint('Health check failed: ${e.message}');
      return {'status': 'unhealthy', 'error': e.message};
    }
  }
}
