class BirdDetailResult {
  final String filename;
  final String? commonName;     
  final String scientificName;   
  final String? speciesCode;     
  final String? speciesImg;      
  final String? speciesData;     
  final double? confidence;
  final double lat;
  final double lon;
  final String? date;
  final bool error;

  BirdDetailResult({
    required this.filename,
    required this.commonName,
    required this.scientificName,
    required this.speciesCode,
    required this.speciesImg,
    required this.speciesData,
    required this.confidence,
    required this.lat,
    required this.lon,
    required this.date,
    required this.error,
  });

  factory BirdDetailResult.fromJson(Map<String, dynamic> json) {
    return BirdDetailResult(
      filename: json['filename'] ?? '',
      commonName: json['common_name'],
      scientificName: json['scientific_name'] ?? '',
      speciesCode: json['species_code'],
      speciesImg: json['species_img'],
      speciesData: json['species_data'],
      confidence: (json['confidence'] is num) ? (json['confidence'] as num).toDouble() : null,
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      date: json['date'],
      error: json['error'] ?? false,
    );
  }
}