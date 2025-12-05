import 'package:flutter/material.dart';
import '../templates/search_screen_template.dart';
import '../widgets/generic_search_item.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  //Lo mismo que con el display de la avedex, esto está hardcodeado para propositos del debug, pero hay que reemplazar con datos fetcheados de la base.
  final List<String> _users = [
    'John Pork',
    'Kasane Teto',
    'Paula Parra',
    'George Santis',
    'Barack Obama',
    'Adodo Adodes',
    'Balatro Argomedo',
    'Mirro 500',
  ];

  List<String> _filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _filteredUsers = _users;
  }

  void _handleSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = _users;
      } else {
        _filteredUsers = _users
            .where((user) => user.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SearchScreenTemplate(
      searchHint: 'Search users...',
      searchController: _searchController,
      onSearchChanged: _handleSearch,
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) {
        final userName = _filteredUsers[index];

        return GenericSearchItem(
          leftContent: const Icon(
            Icons.person_outline,
            size: 40,
            color: Colors.black87,
          ),
          rightContent: Text(userName, style: const TextStyle(fontSize: 18)),
          onTap: () {
            print('Ver perfil de: $userName');
          },
        );
      },
    );
  }
}
