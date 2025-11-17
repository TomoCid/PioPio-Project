import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import '../models/bird_detail_model.dart';

class BirdRecognitionService {
  static const String _baseUrl = ""; // Reemplazar con la URL del FastAPI 
  final Dio _dio = Dio();

  // QUERY #1: POST - ENVIAR AUDIO PARA RECONOCIMIENTO
  // Endpoint: POST /identificarAve
  Future<BirdDetailResult> identifyBird(String audioFilePath) async {
    final url = '$_baseUrl/identificarAve';
    
    final fileName = audioFilePath.split('/').last;

    FormData formData = FormData.fromMap({
      "file": await MultipartFile.fromFile(
        audioFilePath, 
        filename: fileName,
        contentType: MediaType('audio', 'mp3'), 
      ),
    });

    try {
      final response = await _dio.post(url, data: formData);

      if (response.statusCode == 200) {
        return BirdDetailResult.fromJson(response.data);
      } else {
        throw Exception('Fallo el reconocimiento: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Error al enviar audio: ${e.message}');
    }
  }

  // Seguir con las demás querys
}