import 'package:flutter/material.dart';

class SearchScreenTemplate extends StatelessWidget {
  final String searchHint;

  final Widget Function(BuildContext context, int index) itemBuilder;
  final int itemCount;
  final TextEditingController searchController;
  final Function(String)? onSearchChanged;

  const SearchScreenTemplate({
    super.key,
    required this.searchHint,
    required this.itemBuilder,
    required this.itemCount,
    required this.searchController,
    this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/bg.jpg',
            fit: BoxFit.cover,
            color: Colors.black.withOpacity(0.4),
            colorBlendMode: BlendMode.darken,
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextField(
                    controller: searchController,
                    onChanged: onSearchChanged,
                    style: const TextStyle(color: Colors.black87),
                    decoration: InputDecoration(
                      hintText: searchHint,
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.9),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: const Icon(Icons.mic, color: Colors.grey),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10.0,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: itemCount,
                    itemBuilder: itemBuilder,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
