import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:confetti/confetti.dart';

import '../services/bird_detail_service.dart';
import '../widgets/bird_popup.dart';
import '../widgets/debug_panel.dart';
import '../widgets/nav_bar.dart';
import 'bird_encyclopedia_screen.dart';
import 'user_search_screen.dart';
import 'bird_detail_screen.dart'; 

class PioPio extends StatefulWidget {
  const PioPio({super.key});

  @override
  State<PioPio> createState() => _PioPioState();
}

class _PioPioState extends State<PioPio> with SingleTickerProviderStateMixin {
  // Modo de prueba para desktop/web, hay que borrarlo
  final bool isTestMode = false;
  int _selectedIndex = 2;
  static const Color _selectedColor = Colors.black;
  static const Color _unselectedColor = Colors.black45;

  final Location _location = Location();
  final AudioRecorder _recorder = AudioRecorder();
  final BirdRecognitionService _recognitionService = BirdRecognitionService();

  late final AnimationController _pulseController;
  bool _isProcessing = false;
  String _statusMessage = 'Toca para empezar a grabar e identificar un ave.';
  String? _lastResult;

  String? _debugFilePath;
  String? _debugLocation;
  LocationData? _lastLocationData;

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

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
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

  Future<void> _startIdentificationProcess() async {
    if (_isProcessing) return;

    String? savedPath;

    try {
      setState(() {
        _isProcessing = true;
        _statusMessage = 'Grabando por 5 segundos...';
        _lastResult = null;
        _debugFilePath = null;
      });

      if (!await _recorder.hasPermission()) {
        setState(() {
          _statusMessage = 'Permiso de micrófono denegado.';
        });
        return;
      }

      _pulseController.repeat(reverse: true);

      await _getLocation();

      if (_lastLocationData?.latitude == null ||
          _lastLocationData?.longitude == null) {
        throw Exception("Ubicación no disponible. Necesaria para la API.");
      }

      final dir = await getApplicationDocumentsDirectory();
      if (dir == null) return;

      final filePath =
          '${dir.path}/record_${DateTime.now().millisecondsSinceEpoch}.wav';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 48000,
          numChannels: 2,
        ),
        path: filePath,
      );

      await Future.delayed(const Duration(seconds: 5));

      if (isTestMode) {
        // Usar archivo de audio de prueba en modo test
        savedPath =
            '/home/ccserm/Documents/ws/udec/proyectoInf/PioPio-Project/piopio/assets/test_audio.wav';
      } else {
        savedPath = await _recorder.stop();
        if (savedPath == null) throw Exception('Archivo grabado nulo.');
      }

      setState(() {
        _debugFilePath = savedPath;
      });

      setState(() {
        _statusMessage = 'Enviando audio y GPS al servidor Render...';
      });

      final result = await _recognitionService.identifyBird(
        savedPath,
        _lastLocationData!.latitude!,
        _lastLocationData!.longitude!,
      );

      if (!result.error) {
        _confettiController.play();

        // En lugar de pasar cada dato al popup, pasamos el objeto 'result' completo
        showBirdRecognitionPopup(
          context: context,
          result: result, // Pasamos el objeto entero
        );

        setState(() {
          _statusMessage = 'Identificación Completa!';
          _lastResult =
              'AVE ENCONTRADA:\n${result.scientificName}\nConfianza: ${(result.confidence ?? 0).toStringAsFixed(3)}';
        });
      } else {
        setState(() {
          _statusMessage = 'No se pudo identificar el ave.';
          _lastResult = 'No se pudo identificar. Archivo: ${result.filename}';
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        _statusMessage = 'Error de Análisis/Conexión.';
        _lastResult =
            'Error: ${e.toString().split(':')[0].replaceAll("Exception", "Server Error")}';
      });

      if (await _recorder.isRecording()) await _recorder.stop();
    } finally {
      setState(() => _isProcessing = false);
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  Future<void> _getLocation() async {
    try {
      if (isTestMode) {
        // Mock de ubicación para pruebas
        final locationData = LocationData.fromMap({
          'latitude': -33.4489,
          'longitude': -70.6693,
        });
        setState(() {
          _lastLocationData = locationData;
          _debugLocation =
              'Lat: ${locationData.latitude?.toStringAsFixed(4)}, Lon: ${locationData.longitude?.toStringAsFixed(4)}';
        });
        return;
      }
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return;

      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) return;
      }

      final locationData = await _location.getLocation();

      setState(() {
        _lastLocationData = locationData;
        _debugLocation =
            'Lat: ${locationData.latitude?.toStringAsFixed(4)}, Lon: ${locationData.longitude?.toStringAsFixed(4)}';
      });
    } catch (e) {
      print('Ubicación error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
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
            icon: const Icon(Icons.display_settings, color: Colors.black),
          ),
        ],
      ),
      body: _buildBodyContent(),

      bottomNavigationBar: NavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildBodyContent() {
    switch (_selectedIndex) {
      case 0:
        return const BirdEncyclopediaScreen();
      case 1:
        return const Center(child: Text("Mapa (WIP)"));
      case 2:
        return _buildScannerView();
      case 3:
        return const UserSearchScreen();
      case 4:
        return const Center(child: Text("Perfil (WIP)"));
      default:
        return _buildScannerView();
    }
  }

  Widget _buildScannerView() {
    final isProcessing = _isProcessing;

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/bg.jpg',
            fit: BoxFit.cover,
            opacity: const AlwaysStoppedAnimation(0.8),
          ),
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
                    const Text(
                      'Identify Bird Songs',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontStyle: FontStyle.italic,
                        color: _pulseController.isAnimating
                            ? Colors.redAccent
                            : Colors.white70,
                      ),
                    ),
                    if (_lastResult != null) ...[
                      const SizedBox(height: 12),
                      const Divider(color: Colors.white38),
                      Text(
                        _lastResult!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _lastResult!.startsWith('✅')
                              ? Colors.lightGreenAccent
                              : Colors.redAccent[100],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              GestureDetector(
                onTap: isProcessing ? null : _startIdentificationProcess,
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
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: ClipOval(
                        child: Image.asset(
                          'assets/logo.png',
                          fit: BoxFit.cover,
                        ),
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
              Colors.purple,
            ],
          ),
        ),

        /*
        DebugPanel(
          debugFilePath: _debugFilePath,
          debugLocation: _debugLocation,
          lastResult: _lastResult,
        ),
        */
      ],
    );
  }
}
