import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../core/constants/app_constants.dart';
import 'api_client.dart';

/// File service for handling file upload, download, and management
class FileService {
  final ApiClient _apiClient;
  final Dio _dio = Dio();

  FileService(this._apiClient);

  /// Upload file to server
  Future<ApiResponse<FileUploadResponse>> uploadFile({
    required String filePath,
    required String messageType, // image, video, audio, file
  }) async {
    try {
      final response = await _apiClient.postMultipart<FileUploadResponse>(
        ApiConstants.uploadFile,
        fields: {'messageType': messageType},
        filePath: filePath,
        fileFieldName: 'file',
        fromJson: (json) => FileUploadResponse.fromJson(json),
      );
      return response;
    } catch (e) {
      return ApiResponse.error('Failed to upload file: ${e.toString()}');
    }
  }

  /// Download file from server
  Future<ApiResponse<String>> downloadFile(
    String serverFilePath, {
    void Function(int received, int total)? onProgress,
  }) async {
    try {
      // Get the downloads directory
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = await getDownloadsDirectory();
      }

      if (directory == null) {
        return ApiResponse.error('فشل في العثور على مجلد التنزيلات');
      }

      // Create a "SamaNet" folder in downloads
      final samaNetDir = Directory('${directory.path}/SamaNet');
      if (!await samaNetDir.exists()) {
        await samaNetDir.create(recursive: true);
      }

      // Get the file name from server path
      final fileName = serverFilePath.split('/').last;
      final filePath = path.join(samaNetDir.path, fileName);

      // Check if file already exists
      final file = File(filePath);
      if (await file.exists()) {
        // Add timestamp to make filename unique
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final extension = path.extension(fileName);
        final baseName = path.basenameWithoutExtension(fileName);
        final newFileName = '${baseName}_$timestamp$extension';
        final newFilePath = path.join(samaNetDir.path, newFileName);
        return await _downloadFileWithDio(serverFilePath, newFilePath, onProgress);
      }

      return await _downloadFileWithDio(serverFilePath, filePath, onProgress);
    } catch (e) {
      return ApiResponse.error('فشل في تحميل الملف: ${e.toString()}');
    }
  }

  /// Internal method to download file using Dio
  Future<ApiResponse<String>> _downloadFileWithDio(
    String serverFilePath,
    String savePath,
    void Function(int received, int total)? onProgress,
  ) async {
    try {
      final baseUrl = _apiClient.baseUrl;
      final downloadUrl = '$baseUrl${ApiConstants.streamFile}?filePath=${Uri.encodeComponent(serverFilePath)}';

      await _dio.download(
        downloadUrl,
        savePath,
        onReceiveProgress: onProgress,
      );

      return ApiResponse.success(savePath);
    } catch (e) {
      return ApiResponse.error('فشل في تحميل الملف: ${e.toString()}');
    }
  }

  /// Get file stream URL for viewing (images, videos, etc.)
  String getStreamUrl(String serverFilePath) {
    final baseUrl = _apiClient.baseUrl;
    return '$baseUrl${ApiConstants.streamFile}?filePath=${Uri.encodeComponent(serverFilePath)}';
  }

  /// Delete file from server
  Future<ApiResponse<void>> deleteFile(String serverFilePath) async {
    try {
      final response = await _apiClient.delete<void>(
        ApiConstants.deleteFile,
        queryParams: {'filePath': serverFilePath},
      );
      return response;
    } catch (e) {
      return ApiResponse.error('Failed to delete file: ${e.toString()}');
    }
  }

  /// Check if file type is supported
  bool isFileTypeSupported(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    const supportedExtensions = [
      // Images
      'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp',
      // Videos
      'mp4', 'avi', 'mov', 'wmv', 'flv', 'webm',
      // Audio
      'mp3', 'wav', 'aac', 'ogg', 'flac', 'm4a',
      // Documents
      'pdf', 'doc', 'docx', 'txt', 'rtf',
      // Archives
      'zip', 'rar', '7z', 'tar', 'gz',
    ];
    return supportedExtensions.contains(extension);
  }

  /// Get message type based on file extension
  String getMessageTypeFromFile(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();

    const imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'];
    const videoExtensions = ['mp4', 'avi', 'mov', 'wmv', 'flv', 'webm'];
    const audioExtensions = ['mp3', 'wav', 'aac', 'ogg', 'flac', 'm4a'];

    if (imageExtensions.contains(extension)) {
      return 'image';
    } else if (videoExtensions.contains(extension)) {
      return 'video';
    } else if (audioExtensions.contains(extension)) {
      return 'audio';
    } else {
      return 'file';
    }
  }

  /// Get file size
  Future<int> getFileSize(String filePath) async {
    final file = File(filePath);
    final stat = await file.stat();
    return stat.size;
  }

  /// Check if file size is within limits
  bool isFileSizeValid(int sizeInBytes) {
    return sizeInBytes <= AppConstants.maxFileSize;
  }
}

/// File upload response model
class FileUploadResponse {
  final bool success;
  final String? filePath;
  final String? fileName;
  final int? fileSize;
  final String? message;

  const FileUploadResponse({required this.success, this.filePath, this.fileName, this.fileSize, this.message});

  factory FileUploadResponse.fromJson(Map<String, dynamic> json) {
    return FileUploadResponse(
      success: json['success'] as bool? ?? false,
      filePath: json['filePath'] as String?,
      fileName: json['fileName'] as String?,
      fileSize: json['fileSize'] as int?,
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'success': success, 'filePath': filePath, 'fileName': fileName, 'fileSize': fileSize, 'message': message};
  }
}
