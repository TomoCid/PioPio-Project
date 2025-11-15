import 'package:flutter/material.dart';
import 'package:location/location.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: LocationPage());
  }
}

class LocationPage extends StatefulWidget {
  const LocationPage({super.key});
  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  final Location location = Location();
  String _status = 'Ubicación: desconocida';

  Future<void> _getLocation() async {
    try {
      bool serviceEnabled;
      PermissionStatus permissionGranted;
      LocationData locationData;

      serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          setState(() => _status = 'Servicio de ubicación deshabilitado');
          return;
        }
      }

      permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          setState(() => _status = 'Permiso denegado');
          return;
        }
      }

      locationData = await location.getLocation();
      setState(() => _status =
          'Lat: ${locationData.latitude}, Lon: ${locationData.longitude}');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Demo Location')),
      body: Center(child: Text(_status)),
      floatingActionButton: FloatingActionButton(
        onPressed: _getLocation,
        child: const Icon(Icons.my_location),
      ),
    );
  }
}