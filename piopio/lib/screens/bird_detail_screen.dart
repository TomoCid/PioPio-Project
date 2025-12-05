import 'package:flutter/material.dart';
import '../models/bird_detail_model.dart'; 

class BirdDetailScreen extends StatelessWidget {
  final BirdDetailResult bird;

  const BirdDetailScreen({
    super.key,
    required this.bird,
  });

  @override
  Widget build(BuildContext context) {
    final displayCommonName = bird.commonName ?? 'Nombre no disponible';
    final displayScientificName = bird.scientificName;
    final displayImageUrl = bird.speciesImg ?? 'assets/logo.png'; 
    final displayDescription = bird.speciesData ?? 'Descripción no disponible.';

    return Scaffold(
      backgroundColor: Colors.white,  
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                  ),
                  const Text(
                    'Detalles del ave',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      print('Compartir ave');
                    },
                    icon: const Icon(Icons.share, color: Colors.black),
                  ),
                ],
              ),
            ),

            //Contenido scrolleable
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //Imagen del bicho
                    Container(
                      width: double.infinity,
                      height: 250,
                      color: Colors.grey[200],
                      child: displayImageUrl.startsWith('http')
                          ? Image.network(
                              displayImageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.image_not_supported,
                                        size: 64, color: Colors.grey[400]),
                                    const SizedBox(height: 8),
                                    Text('Imagen no disponible',
                                        style: TextStyle(color: Colors.grey[600])),
                                  ],
                                ),
                              ),
                            )
                          : Image.asset(
                              displayImageUrl,
                              fit: BoxFit.cover,
                            ),
                    ),

                    //Nombres y botón de play
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayCommonName,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  displayScientificName,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: () {
                                print('Reproducir audio del ave');
                              },
                              icon: Icon(
                                Icons.play_arrow,
                                color: Colors.green[700],
                                size: 32,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    //Descripción del pollo
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Descripción',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            displayDescription,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.5,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.justify,
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}