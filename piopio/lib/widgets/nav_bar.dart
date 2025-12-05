import 'package:flutter/material.dart';

class NavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  static const Color _selectedColor = Colors.black;
  static const Color _unselectedColor = Colors.black45;

  const NavBar({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      selectedItemColor: _selectedColor,
      unselectedItemColor: _unselectedColor,
      selectedFontSize: 15,
      onTap: onTap,
      items: <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: _buildStandardIcon(Icons.auto_stories_outlined, 0),
          label: 'Encyclopedia',
        ),
        BottomNavigationBarItem(
          icon: _buildStandardIcon(Icons.map, 1),
          label: 'Map',
        ),
        BottomNavigationBarItem(
          icon: _buildCustomIcon(2), // El ícono del logo
          label: 'PioPio',
        ),
        BottomNavigationBarItem(
          icon: _buildStandardIcon(Icons.message, 3),
          label: 'Social',
        ),
        BottomNavigationBarItem(
          icon: _buildStandardIcon(Icons.account_circle, 4),
          label: 'Profile',
        ),
      ],
    );
  }

  Widget _buildCustomIcon(int index) {
    final color = currentIndex == index ? _selectedColor : _unselectedColor;
    return Image.asset(
      'assets/logo.png',
      width: 50,
      height: 50,
      color: color,
      colorBlendMode: BlendMode.srcIn,
    );
  }

  Widget _buildStandardIcon(IconData iconData, int index) {
    return Icon(
      iconData,
      color: currentIndex == index ? _selectedColor : _unselectedColor,
    );
  }
}
