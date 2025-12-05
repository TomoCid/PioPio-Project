import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';

import '../models/bird_detail_model.dart';
import '../templates/search_screen_template.dart';
import '../widgets/generic_search_item.dart';
import 'bird_detail_screen.dart';

class BirdEncyclopediaScreen extends StatefulWidget {
  const BirdEncyclopediaScreen({super.key});

  @override
  State<BirdEncyclopediaScreen> createState() => _BirdEncyclopediaScreenState();
}

class _BirdEncyclopediaScreenState extends State<BirdEncyclopediaScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  bool _isLoading = true;
  List<BirdDetailResult> _allBirds = [];
  List<BirdDetailResult> _filteredBirds = [];

  @override
  void initState() {
    super.initState();
    _loadBirdsFromCsv();
  }

  Future<void> _loadBirdsFromCsv() async {
    try {
      final rawCsvData = await rootBundle.loadString('lib/Birds/reduced_taxonomy.csv');
      
      List<List<dynamic>> csvTable = const CsvToListConverter().convert(rawCsvData);

      final csvRows = csvTable.sublist(1);

      final birds = csvRows.map((row) {
        return BirdDetailResult(
          scientificName: row[0].toString(),
          commonName: row[1].toString(),
          speciesCode: row[2].toString(),
          speciesImg: row[6].toString(),
          speciesData: row[7].toString(), 
          filename: '',
          confidence: null,
          lat: 0.0,
          lon: 0.0,
          date: null,
          error: false,
        );
      }).toList();

      setState(() {
        _allBirds = birds;
        _filteredBirds = birds;
        _isLoading = false;
      });
    } catch (e) {
      print("/ff Error al cargar el CSV: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredBirds = _allBirds;
      } else {
        _filteredBirds = _allBirds
            .where((bird) =>
                (bird.commonName ?? '').toLowerCase().contains(query.toLowerCase()) ||
                bird.scientificName.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_allBirds.isEmpty) {
      return const Center(child: Text('No se pudieron cargar las aves desde el archivo local. ggs'));
    }

    return SearchScreenTemplate(
      searchHint: 'Buscar en la enciclopedia...',
      searchController: _searchController,
      onSearchChanged: _handleSearch,
      itemCount: _filteredBirds.length,
      itemBuilder: (context, index) {
        final bird = _filteredBirds[index];
        return GenericSearchItem(
          leftContent: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                bird.speciesImg ?? 'assets/logo.png',
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Image.asset('assets/logo.png', width: 60),
              ),
            ),
          ),
          rightContent: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                bird.commonName ?? bird.scientificName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                bird.scientificName,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BirdDetailScreen(bird: bird),
              ),
            );
          },
        );
      },
    );
  }
}
