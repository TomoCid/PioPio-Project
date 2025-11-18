import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'package:piopio/services/bird_detail_service.dart';

void main() {
  runApp(const PioPio());
}

class PioPio extends StatefulWidget {
  const PioPio({super.key});

  @override
  State<PioPio> createState() => _PioPioState();
}

class _PioPioState extends State<PioPio> with SingleTickerProviderStateMixin {
  // --- Configuración UI y Servicios ---
  int _selectedIndex = 2;
  static const Color _selectedColor = Colors.black;
  static const Color _unselectedColor = Colors.black45;

  final Location _location = Location();
  final AudioRecorder _recorder = AudioRecorder();
  final BirdRecognitionService _recognitionService = BirdRecognitionService();

  // --- Estado de la Aplicación y Animación ---
  late final AnimationController _pulseController;
  bool _isProcessing = false; // Indica si hay grabación o análisis en curso
  String _statusMessage = 'Toca para empezar a grabar y identificar un ave.';
  String? _lastResult; // Resultado final de la identificación

  // --- NUEVAS VARIABLES DE DEPURACIÓN ---
  String? _debugFilePath;
  String? _debugLocation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
      lowerBound: 0.95,
      upperBound: 1.05,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // --- Funciones de Utilidad (Íconos) ---

  Widget _buildCustomIcon(int index) {
    final color = _selectedIndex == index ? _selectedColor : _unselectedColor;
    return Image.asset(
      'assets/logo.png',
      width: 50,
      height: 50,
      color: color,
      colorBlendMode: BlendMode.srcIn,
    );
  }

  Widget _buildStandardIcon(IconData iconData, int index) {
    return Icon(
      iconData,
      color: _selectedIndex == index ? _selectedColor : _unselectedColor,
    );
  }

  // --- Lógica Principal: Grabación, Ubicación y Envío al Servidor ---

  Future<void> _startIdentificationProcess() async {
    if (_isProcessing) return;

    String? savedPath;

    try {
      // 1. Inicializar UI: Preparando
      setState(() {
        _isProcessing = true;
        _statusMessage = 'Grabando por 5 segundos...';
        _lastResult = null;
        _debugFilePath = null; // Limpiar path anterior
      });

      // 2. Comprobar permisos y empezar animación de pulso
      if (!await _recorder.hasPermission()) {
        setState(() {
          _statusMessage = 'Permiso de micrófono denegado.';
        });
        return;
      }
      _pulseController.repeat(reverse: true);

      // Obtener ubicación (de forma asíncrona)
      await _getLocation(); 

      // Configuración de la ruta WAV
      final dir = await getExternalStorageDirectory();
      if (dir == null) {
        setState(() {
          _statusMessage = 'No se pudo acceder al directorio de almacenamiento.';
        });
        return;
      }
      
      final filePath = '${dir.path}/record_${DateTime.now().millisecondsSinceEpoch}.wav';

      // 3. Iniciar grabación (WAV - PCM 16 bits)
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits, // Formato WAV (PCM)
          sampleRate: 16000, 
        ),
        path: filePath,
      );
      print('Grabación iniciada en -> $filePath');

      // Esperar 5 segundos
      await Future.delayed(const Duration(seconds: 5));

      // 4. Detener grabación
      savedPath = await _recorder.stop();
      
      if (savedPath == null) {
        throw Exception('Error: La ruta del archivo grabado es nula.');
      }
      
      // 4.1. ACTUALIZAR PATH DE DEBUG
      setState(() {
        _debugFilePath = savedPath;
      });

      print('¡ÉXITO! Archivo WAV guardado en: $savedPath');
      
      // 5. Actualizar UI: Análisis
      setState(() {
        _statusMessage = 'Enviando audio al servidor FastAPI...';
      });

      // 6. LLAMADA AL SERVICIO DE RECONOCIMIENTO
      final result = await _recognitionService.identifyBird(savedPath);

      // 7. Actualizar UI: Resultado exitoso
      setState(() {
        _statusMessage = 'Identificación Completa!';
        _lastResult = '✅ ${result.commonName}\n(${result.scientificName})\nConfianza: ${result.confidence.toStringAsFixed(2)}';
      });
      
      // Opcional: Eliminar el archivo temporal
      File(savedPath).delete(); 

    } catch (e) {
      // 8. Manejar error
      print('Fallo el proceso de identificación: $e');
      setState(() {
        _statusMessage = '🚨 Error de Análisis/Conexión.';
        _lastResult = 'Error: ${e.toString().split(':')[0].replaceAll("Exception", "Server Error")}'; 
      });
      
      // Asegurar que el recorder se detiene si falló a mitad
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }

    } finally {
      // 9. Finalizar procesamiento y animación
      setState(() {
        _isProcessing = false;
      });
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  // --- Lógica de Localización ---

  Future<void> _getLocation() async {
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) return;
      }

      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) return;
      }

      final locationData = await _location.getLocation();
      // ACTUALIZAR LOCATION DE DEBUG
      setState(() {
        _debugLocation = 'Lat: ${locationData.latitude?.toStringAsFixed(4)}, Lon: ${locationData.longitude?.toStringAsFixed(4)}';
      });
      print('Ubicación: Lat: ${locationData.latitude}, Lon: ${locationData.longitude}');
    } catch (e) {
      print('Error ubicación: $e');
    }
  }

  Widget _buildDebugPanel() {
    if (_debugFilePath == null && _debugLocation == null && _lastResult == null) {
      return Container();
    }
    
    return Positioned(
      left: 0,
      right: 0,
      bottom: 60, // Encima del BottomNavigationBar
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Colors.blueGrey[900]?.withOpacity(0.85),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.blueAccent),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('--- DEBUG STATUS ---', style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold)),
              if (_debugLocation != null) 
                Text('Ubicación: $_debugLocation', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              if (_debugFilePath != null) 
                Text('Path WAV: ${_debugFilePath!.split('/').last}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              if (_debugFilePath != null) 
                const Text('Path Completo: Check Console', style: TextStyle(color: Colors.white70, fontSize: 12)),
              if (_lastResult != null)
                Text('Último Resultado: $_lastResult', style: TextStyle(color: _lastResult!.startsWith('✅') ? Colors.lightGreenAccent : Colors.redAccent[100], fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widget Build ---

  @override
  Widget build(BuildContext context) {
    final isRecordingOrAnalyzing = _isProcessing;
    
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () { print('Botón de menú apretao >:)'); },
            icon: const Icon(Icons.menu, color: Colors.black),
          ),
          title: const Text('Piopio', style: TextStyle(color: Colors.black)),
          centerTitle: true,
          backgroundColor: Colors.white,
          actions: <Widget>[
            IconButton(
              onPressed: () { print('Botón de configuración apretao >:D'); },
              icon: const Icon(Icons.display_settings, color: Colors.black),
            ),
          ],
        ),
        body: Stack(
          children: <Widget>[
            Positioned.fill(
              child: Image.asset('assets/bg.jpg', fit: BoxFit.cover),
            ),

            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // Contenedor de Texto de Estado y Resultado
                  Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    padding: const EdgeInsets.all(16.0),
                    margin: const EdgeInsets.only(bottom: 32.0),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Text(
                          'Identify Bird Songs',
                          style: TextStyle(
                            fontSize: 30.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Mensaje de estado dinámico
                        Text(
                          _statusMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18.0,
                            fontStyle: FontStyle.italic,
                            color: _pulseController.isAnimating ? Colors.redAccent : Colors.white70,
                          ),
                        ),
                        
                        // Resultado de la identificación
                        if (_lastResult != null) ...[
                          const SizedBox(height: 12),
                          const Divider(color: Colors.white38),
                          Text(
                            _lastResult!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                              // Color según si hubo éxito (verde) o error (rojo)
                              color: _lastResult!.startsWith('✅') ? Colors.lightGreenAccent : Colors.redAccent[100],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Botón Central (Tap to Record)
                  GestureDetector(
                    onTap: isRecordingOrAnalyzing ? null : _startIdentificationProcess, // Deshabilita el tap si está procesando
                    child: ScaleTransition(
                      scale: _pulseController,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isRecordingOrAnalyzing ? Colors.red.withOpacity(0.7) : Colors.white.withOpacity(0.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                            ),
                            child: ClipOval(
                              child: isRecordingOrAnalyzing
                                ? const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 5)) // Indicador de carga
                                : Image.asset(
                                    'assets/logo.png',
                                    fit: BoxFit.cover,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // PANEL DE DEPURACIÓN
            _buildDebugPanel(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: _buildStandardIcon(Icons.auto_stories_outlined, 0),
              label: 'Encyclopedia',
            ),
            BottomNavigationBarItem(
              icon: _buildStandardIcon(Icons.map, 1),
              label: 'Map',
            ),
            BottomNavigationBarItem(
              icon: _buildCustomIcon(2),
              label: 'PioPio',
            ),
            BottomNavigationBarItem(
              icon: _buildStandardIcon(Icons.message, 3),
              label: 'Social',
            ),
            BottomNavigationBarItem(
              icon: _buildStandardIcon(Icons.account_circle, 4),
              label: 'Profile',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: _selectedColor,
          unselectedItemColor: _unselectedColor,
          selectedFontSize: 15,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}