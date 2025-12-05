import 'package:flutter/material.dart';
import '../templates/search_screen_template.dart';
import '../widgets/generic_search_item.dart';

class BirdEncyclopediaScreen extends StatefulWidget {
  const BirdEncyclopediaScreen({super.key});

  @override
  State<BirdEncyclopediaScreen> createState() => _BirdEncyclopediaScreenState();
}

class _BirdEncyclopediaScreenState extends State<BirdEncyclopediaScreen> {
  final TextEditingController _searchController = TextEditingController();

  //Datos de prueba para debuggear. Cambiarlos por datos que recupere de la API.
  final List<String> _allBirds = [
    'Chincol',
    'Loica',
    'Picaflor Chico',
    'Queltehue',
    'Tiuque',
    'Moltres',
    'Pidgey',
  ];
  List<String> _filteredBirds = [];

  @override
  void initState() {
    super.initState();
    _filteredBirds = _allBirds;
  }

  void _handleSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredBirds = _allBirds;
      } else {
        _filteredBirds = _allBirds
            .where((bird) => bird.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SearchScreenTemplate(
      searchHint: 'Search birds...',
      navIndex: 0,
      searchController: _searchController,
      onSearchChanged: _handleSearch,
      onNavTap: (index) {
        print("Navegar al índice $index");
      },
      itemCount: _filteredBirds.length,
      itemBuilder: (context, index) {
        final birdName = _filteredBirds[index];
        return GenericSearchItem(
          leftContent: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Image.asset('assets/logo.png', color: Colors.black),
          ),
          rightContent: Text(
            birdName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          onTap: () {
            print('Tocaste el ave: $birdName');
          },
        );
      },
    );
  }
}
