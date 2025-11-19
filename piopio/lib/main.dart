import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:confetti/confetti.dart';

// Importación de tu servicio de reconocimiento
import 'services/bird_detail_service.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PioPio(),
    ),
  );
}

class PioPio extends StatefulWidget {
  const PioPio({super.key});

  @override
  State<PioPio> createState() => _PioPioState();
}

class _PioPioState extends State<PioPio> with SingleTickerProviderStateMixin {
  int _selectedIndex = 2;
  static const Color _selectedColor = Colors.black;
  static const Color _unselectedColor = Colors.black45;

  final Location _location = Location();
  final AudioRecorder _recorder = AudioRecorder();
  final BirdRecognitionService _recognitionService = BirdRecognitionService();

  late final AnimationController _pulseController;
  bool _isProcessing = false;
  String _statusMessage = 'Toca para empezar a grabar y identificar un ave.';
  String? _lastResult;

  String? _debugFilePath;
  String? _debugLocation;
  LocationData? _lastLocationData;

  // Confetti controller
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
      lowerBound: 0.95,
      upperBound: 1.05,
    );

    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _recorder.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

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
        _debugFilePath = null; 
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

      // Verificar si tenemos ubicación para enviar
      if (_lastLocationData?.latitude == null || _lastLocationData?.longitude == null) {
        throw Exception("Ubicación no disponible. Necesaria para la API.");
      }

      // Configuración de la ruta WAV
      final dir = await getTemporaryDirectory(); 
      if (dir == null) {
        throw Exception("No se pudo acceder al directorio temporal.");
      }
      
      final filePath = '${dir.path}/record_${DateTime.now().millisecondsSinceEpoch}.wav';

      // 3. Iniciar grabación (WAV)
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav, // Asegúrate de que esté en .wav
          sampleRate: 16000, // Frecuencia de muestreo estándar para reconocimiento
        ),
        path: filePath,
      );
      print('Grabación iniciada en -> $filePath (WAV)');

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
        _statusMessage = 'Enviando audio y GPS al servidor Render...';
      });

      // 6. LLAMADA AL SERVICIO DE RECONOCIMIENTO (Pasando Lat/Lon)
      final result = await _recognitionService.identifyBird(
        savedPath, 
        _lastLocationData!.latitude!, 
        _lastLocationData!.longitude!,
      );

      // 7. Actualizar UI: Resultado exitoso con el nuevo JSON
      setState(() {
        _statusMessage = 'Identificación Completa!';
        
        if (!result.error) {
          _lastResult = 'AVE ENCONTRADA:\n${result.scientificName}\nUbicación: ${result.lat.toStringAsFixed(4)}, ${result.lon.toStringAsFixed(4)}';
        } else {
          _lastResult = 'No se pudo identificar el ave. \nDatos recibidos: ${result.filename}';
        }
      });
      
      // Opcional: Eliminar el archivo temporal
      //File(savedPath).delete(); 

    } catch (e) {
      // 8. Manejar error
      print('Fallo el proceso de identificación: $e');
      setState(() {
        _statusMessage = 'Error de Análisis/Conexión.';
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
      
      // GUARDAR Y ACTUALIZAR LOCATION DE DEBUG
      setState(() {
        _lastLocationData = locationData;
        _debugLocation = 'Lat: ${locationData.latitude?.toStringAsFixed(4)}, Lon: ${locationData.longitude?.toStringAsFixed(4)}';
      });
      print('Ubicación: Lat: ${locationData.latitude}, Lon: ${locationData.longitude}');
    } catch (e) {
      print('Error ubicación: $e');
    }
  }




void _showBirdRecognitionPopup({
    required String imagePath,
    required String commonName,
    required String scientificName,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.45,
          minChildSize: 0.30,
          maxChildSize: 0.90,
          expand: false,
          builder: (_, controller) {
            return SingleChildScrollView(
              controller: controller,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        imagePath,
                        width: 250,
                        height: 250,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(commonName,
                        style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.black)),
                    Text(scientificName,
                        style: const TextStyle(
                            fontSize: 18,
                            fontStyle: FontStyle.italic,
                            color: Colors.black54)),
                    const SizedBox(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            print("Compartir en redes sociales");
                          },
                          icon: const Icon(Icons.share),
                          label: const Text("Compartir"),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            print("Ver detalles del ave");
                          },
                          icon: const Icon(Icons.info_outline),
                          label: const Text("Detalles"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDebugPanel() {
    if (_debugFilePath == null && _debugLocation == null && _lastResult == null) {
      return Container();
    }

    return Positioned(
      left: 0,
      right: 0,
      bottom: 60,
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
              const Text('--- DEBUG STATUS ---',
                  style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold)),
              if (_debugLocation != null)
                Text('Ubicación: $_debugLocation',
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
              if (_debugFilePath != null)
                Text('Path WAV: ${_debugFilePath!.split('/').last}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
              if (_lastResult != null)
                Text('Último Resultado: $_lastResult',
                    style: TextStyle(
                        color: _lastResult!.startsWith('✅')
                            ? Colors.lightGreenAccent
                            : Colors.redAccent[100],
                        fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRecordingOrAnalyzing = _isProcessing;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => print('Botón menú'),
          icon: const Icon(Icons.menu, color: Colors.black),
        ),
        title: const Text('Piopio', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
              onPressed: () => print('Botón configuración'),
              icon: const Icon(Icons.display_settings, color: Colors.black))
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/bg.jpg',
                fit: BoxFit.cover, opacity: const AlwaysStoppedAnimation(0.8)),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                    children: [
                      const Text('Identify Bird Songs',
                          style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(height: 12),
                      Text(_statusMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 18,
                              fontStyle: FontStyle.italic,
                              color: _pulseController.isAnimating
                                  ? Colors.redAccent
                                  : Colors.white70)),
                      if (_lastResult != null) ...[
                        const SizedBox(height: 12),
                        const Divider(color: Colors.white38),
                        Text(_lastResult!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _lastResult!.startsWith('✅')
                                    ? Colors.lightGreenAccent
                                    : Colors.redAccent[100]))
                      ]
                    ],
                  ),
                ),
                GestureDetector(
                  // Tap inicia el proceso de identificación (si no está procesando)
                  onTap: isRecordingOrAnalyzing ? null : _startIdentificationProcess,
                   onLongPress: () {
                     _showBirdRecognitionPopup(
                       imagePath: 'assets/pimpollo.jpg',
                       commonName: 'Pimpollo',
                       scientificName: 'Rollandia rolland',
                     );
                     _confettiController.play();
                   },
                   child: ScaleTransition(
                     scale: _pulseController,
                     child: Container(
                       width: 200,
                       height: 200,
                       decoration: BoxDecoration(
                         shape: BoxShape.circle,
                         color: Colors.white.withOpacity(0.5),
                         boxShadow: [
                           BoxShadow(
                               color: Colors.black.withOpacity(0.2),
                               blurRadius: 15,
                               spreadRadius: 2)
                         ],
                       ),
                       child: Center(
                         child: ClipOval(
                           child:
                               Image.asset('assets/logo.png', fit: BoxFit.cover),
                         ),
                       ),
                     ),
                   ),
                 ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple
              ],
            ),
          ),
          _buildDebugPanel(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: _buildStandardIcon(Icons.auto_stories_outlined, 0),
              label: 'Encyclopedia'),
          BottomNavigationBarItem(
              icon: _buildStandardIcon(Icons.map, 1), label: 'Map'),
          BottomNavigationBarItem(icon: _buildCustomIcon(2), label: 'PioPio'),
          BottomNavigationBarItem(
              icon: _buildStandardIcon(Icons.message, 3), label: 'Social'),
          BottomNavigationBarItem(
              icon: _buildStandardIcon(Icons.account_circle, 4), label: 'Profile')
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: _selectedColor,
        unselectedItemColor: _unselectedColor,
        selectedFontSize: 15,
        onTap: _onItemTapped,
      ),
    );
  }
}