// Clase detalle de un pájaro (Ajustar según los datos disponibles en la API y los que sean requeridos)
class BirdDetailResult {
  final String commonName;
  final String scientificName;
  final double confidence; 
  // Ajustar según los datos disponibles en la API

  BirdDetailResult({
    required this.commonName,
    required this.scientificName,
    required this.confidence,
    // Ajustar según los datos disponibles en la API,
  });

  factory BirdDetailResult.fromJson(Map<String, dynamic> json) {
    return BirdDetailResult(
      commonName: json['commonName'] as String,
      scientificName: json['scientificName'] as String,
      confidence: (json['confidence'] as num).toDouble(),
    );
  }
}