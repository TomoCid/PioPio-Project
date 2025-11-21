class BirdDetailResult {
  final String scientificName;
  final String filename;
  final double lat;
  final double lon;
  final String date;
  final bool error;
  final double? confidence;
  final String description;

  BirdDetailResult({
    required this.scientificName,
    required this.filename,
    required this.lat,
    required this.lon,
    required this.date,
    required this.error,
    this.confidence,
    required this.description,
  });

  factory BirdDetailResult.fromJson(Map<String, dynamic> json) {
    return BirdDetailResult(
      // Mapeo de campos
      scientificName: json['scientific_name'] as String? ?? 'N/A',
      filename: json['filename'] as String? ?? 'N/A',
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lon: (json['lon'] as num?)?.toDouble() ?? 0.0,
      date: json['date'] as String? ?? 'N/A',
      error: json['error'] as bool? ?? true,
      confidence: (json['confidence'] as num?)?.toDouble(),
      description: json['description'] as String? ?? 'Sin descripción disponible.',
    );
  }
}