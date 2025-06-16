import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class FivemanageImageService {
  static const String apiUrl = 'https://api.fivemanage.com/api/image';
  static const String apiKey = 'MNgzjG3SRaGJEsr1pEJUK2w3GUtPtOHO';

  Future<String> uploadImage(File file, Map<String, dynamic> metadata) async {
    var request = http.MultipartRequest('POST', Uri.parse(apiUrl));

    // Attach file
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    // Attach metadata as stringified JSON
    request.fields['metadata'] = jsonEncode(metadata);

    // Add headers
    request.headers['Authorization'] = apiKey;

    try {
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final decoded = json.decode(responseBody);
        return decoded['url']; // Assuming API returns a `url` field
      } else {
        throw Exception('Upload failed: \\${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Upload error: $e');
    }
  }
}
