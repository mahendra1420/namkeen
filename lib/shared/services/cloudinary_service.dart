import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CloudinaryService {
  // IMPORTANT: Replace these with your actual Cloudinary details
  static const String cloudName = 'dfl4amlvc';
  static const String uploadPreset = 'product_images';

  /// Uploads an image to Cloudinary and returns the secure URL
  static Future<String> uploadImage(File imageFile) async {
    if (cloudName == 'YOUR_CLOUD_NAME' || uploadPreset == 'YOUR_UPLOAD_PRESET') {
      throw Exception('Please configure your Cloudinary cloudName and uploadPreset in cloudinary_service.dart');
    }

    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      final request = http.MultipartRequest('POST', url);
      
      // The upload preset must be configured in your Cloudinary Dashboard under Settings -> Upload -> Upload Presets
      // It must be set to "Unsigned" mode.
      request.fields['upload_preset'] = uploadPreset;
      
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonMap = jsonDecode(responseData);

      if (response.statusCode == 200) {
        return jsonMap['secure_url'];
      } else {
        throw Exception(jsonMap['error']?['message'] ?? 'Unknown Cloudinary error');
      }
    } catch (e) {
      throw Exception('Cloudinary upload failed: $e');
    }
  }
}
