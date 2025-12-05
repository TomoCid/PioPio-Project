import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import '../models/bird_detail_model.dart';
import 'dart:io';

class BirdRecognitionService {
  // URL de producción/Render
  static const String _baseUrl = "https://piopioapi.onrender.com"; 
  
  // Aumentamos el timeout para el servidor remoto (Render puede ser lento en arrancar)
  final Dio _dio = Dio(BaseOptions(
    // 30 segundos para establecer la conexión 
    connectTimeout: const Duration(milliseconds: 30000), 
    // 60 segundos para recibir toda la respuesta (puede tardar la clasificación del ML)
    receiveTimeout: const Duration(milliseconds: 60000), 
  ));

  /// Envía el archivo de audio local, latitud y longitud al endpoint de identificación.
  Future<BirdDetailResult> identifyBird(String audioFilePath, double lat, double lon) async {
    final url = '$_baseUrl/analyze/'; // Endpoint correcto de Render
    
    final fileName = audioFilePath.split('/').last; 

    // DEBUG LOGS
    print('*** DEBUG: ENVIANDO SOLICITUD POST ***');
    print('*** URL: $url');
    print('*** ARCHIVO: $fileName (audio/wav)'); 
    print('*** DATA: Lat: $lat, Lon: $lon');
    // ------------------------------------

    try {
      // 1. Crear el objeto MultipartFile (audio_sample)
      final audioFilePart = await MultipartFile.fromFile(
        audioFilePath, 
        filename: fileName,
        // ContentType para WAV
        contentType: MediaType('audio', 'wav'), 
      );
      
      // 2. Crear el FormData con el campo de archivo y los campos de datos (lat/lon)
      FormData formData = FormData.fromMap({
        // Campo del archivo: "audio_sample" (Según la API de Render)
        "audio_sample": audioFilePart,
        
        // Campos de datos
        "lat": lat.toString(),
        "lon": lon.toString(),
      });

      // 3. Enviar la solicitud POST
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
}