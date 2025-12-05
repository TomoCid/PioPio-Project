import 'package:flutter/material.dart';
import '../models/bird_detail_model.dart'; 
import '../screens/bird_detail_screen.dart'; 

void showBirdRecognitionPopup({
  required BuildContext context,
  required BirdDetailResult result, 
}) {
  final commonName = result.commonName ?? result.scientificName;
  final scientificName = result.scientificName;
  final imagePath = result.speciesImg ?? 'assets/logo.png';
  final description = result.speciesData ?? 'Descripción no disponible.';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
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
                  Text(
                    '¡Felicidades! Has encontrado a $commonName',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: imagePath.startsWith('http')
                        ? Image.network(
                            imagePath,
                            width: 250,
                            height: 250,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox(
                              width: 250,
                              height: 250,
                              child: Center(child: Text('Imagen no disponible')),
                            ),
                          )
                        : Image.asset(
                            imagePath,
                            width: 250,
                            height: 250,
                            fit: BoxFit.cover,
                          ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    commonName,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    scientificName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.share),
                        label: const Text("Compartir"),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context); 
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BirdDetailScreen(bird: result),
                            ),
                          );
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
