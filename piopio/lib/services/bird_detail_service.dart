import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import '../models/bird_detail_model.dart';

class BirdRecognitionService {
  static const String _baseUrl = "http://192.168.1.5:8000"; 
  
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(milliseconds: 5000), 
    receiveTimeout: const Duration(milliseconds: 15000), 
  ));

  Future<BirdDetailResult> identifyBird(String audioFilePath) async {
    final url = '$_baseUrl/identificarAve';
    
    final fileName = audioFilePath.split('/').last; 

    print('*** DEBUG: ENVIANDO SOLICITUD POST ***');
    print('*** URL: $url');
    print('*** ARCHIVO: $fileName (audio/wav)');

    try {
      final audioFilePart = await MultipartFile.fromFile(
        audioFilePath, 
        filename: fileName,
        contentType: MediaType('audio', 'wav'), 
      );
      
      FormData formData = FormData.fromMap({
        "file": audioFilePart,
      });

      final response = await _dio.post(url, data: formData);
      
      if (response.statusCode == 200) {
        print('*** CONEXIÓN EXITOSA. STATUS 200 ***');
        return BirdDetailResult.fromJson(response.data);
      } else {
        throw Exception('Fallo el reconocimiento: ${response.statusCode}. Respuesta: ${response.data}');
      }
    } on DioException catch (e) {
      String errorMsg = e.response?.data != null ? e.response!.data.toString() : e.message ?? 'Unknown Error';
      print('*** FALLO DE CONEXIÓN/SERVIDOR: $errorMsg ***');
      throw Exception('Error al enviar audio al servidor: $errorMsg');
    }
  }

  // Aquí más querys...
}