import 'package:flutter/material.dart';

class DebugPanel extends StatelessWidget {
  final String? debugFilePath;
  final String? debugLocation;
  final String? lastResult;

  const DebugPanel({
    super.key,
    this.debugFilePath,
    this.debugLocation,
    this.lastResult,
  });

  @override
  Widget build(BuildContext context) {
    if (debugFilePath == null &&
        debugLocation == null &&
        lastResult == null) {
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
              const Text(
                '--- DEBUG STATUS ---',
                style:
                    TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold),
              ),
              if (debugLocation != null)
                Text(
                  'Ubicación: $debugLocation',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              if (debugFilePath != null)
                Text(
                  'Path WAV: ${debugFilePath!.split('/').last}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              if (lastResult != null)
                Text(
                  'Último Resultado: $lastResult',
                  style: TextStyle(
                    color: lastResult!.startsWith('✅')
                        ? Colors.lightGreenAccent
                        : Colors.redAccent[100],
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
