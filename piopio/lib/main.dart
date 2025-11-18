import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const PioPio());
}

class PioPio extends StatefulWidget {
  const PioPio({super.key});

  @override
  State<PioPio> createState() => _PioPioState();
}

class _PioPioState extends State<PioPio> {
  int _selectedIndex = 2;
  static const Color _selectedColor = Colors.black;
  static const Color _unselectedColor = Colors.black45;

  final Location _location = Location();
  
  final AudioRecorder _recorder = AudioRecorder();

  @override
  void dispose() {
    _recorder.dispose();
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

  // Graba 5 segundos y guarda el archivo WAV.
  Future<void> _recordForFiveSeconds() async {
    try {
      if (!await _recorder.hasPermission()) {
        print('Permiso de micrófono denegado');
        return;
      }

      final dir = await getExternalStorageDirectory();
      if (dir == null) {
        print('No se pudo acceder al directorio de almacenamiento.');
        return;
      }
      
      final filePath = '${dir.path}/record_${DateTime.now().millisecondsSinceEpoch}.wav';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits, // Ojito que graba en formato WAV!!
          bitRate: 128000,
        ),
        path: filePath,
      );
      print('Recording started -> $filePath');

      await Future.delayed(const Duration(seconds: 5));

      final savedPath = await _recorder.stop();
      
      if (savedPath != null) {
        print('¡ÉXITO! El archivo WAV se guardó correctamente en: $savedPath');
      }

    } catch (e) {
      print('Recording error: $e');
    }
  }

  Future<void> _getLocation() async {
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          print('Servicio de ubicación deshabilitado');
          return;
        }
      }

      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          print('Permiso denegado');
          return;
        }
      }

      final locationData = await _location.getLocation();
      print('Ubicación: Lat: ${locationData.latitude}, Lon: ${locationData.longitude}');
    } catch (e) {
      print('Error ubicación: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () {
              print('Botón de menú apretao >:)');
            },
            icon: const Icon(Icons.menu, color: Colors.black),
          ),
          title: const Text('Piopio', style: TextStyle(color: Colors.black)),
          centerTitle: true,
          backgroundColor: Colors.white,
          actions: <Widget>[
            IconButton(
              onPressed: () {
                print('Botón de configuración apretao >:D');
              },
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
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    margin: const EdgeInsets.only(bottom: 32.0),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          'Identify Bird Songs',
                          style: TextStyle(
                            fontSize: 30.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),

                        Text(
                          'Tap the button below to start recording.',
                          style: TextStyle(
                            fontSize: 15.0,
                            fontStyle: FontStyle.italic,
                            color: Colors.white70,
                          ),
                        ),
                        SizedBox(height: 4),

                        Text(
                          'The app will identify bird songs for you!',
                          style: TextStyle(
                            fontSize: 15.0,
                            fontStyle: FontStyle.italic,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),

                  GestureDetector(
                    onTap: () {
                      _getLocation();
                      _recordForFiveSeconds();
                      print('Escuchando pajaritos :D');
                    },
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
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
