import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pages/home_page.dart';
import 'providers/home_provider.dart';
import 'pages/user_profile.dart';
import 'pages/calculator_ui.dart';
import 'aiplanpages/body_results_screen.dart';

class MainPage extends ConsumerStatefulWidget {
  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    HomePage(),
    BodyResultsScreen(),
    CalculatorHome(),
    UserProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);

    if (index == 0) {
      ref.read(homeProvider.notifier).loadWater();
    }
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final bool isSelected = _selectedIndex == index;

    final gradient = const LinearGradient(
      colors: [Colors.orange, Colors.yellow, Colors.red],
    );

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onItemTapped(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              isSelected
                  ? Icon(icon, color: Colors.white)
                  : ShaderMask(
                shaderCallback: (bounds) =>
                    gradient.createShader(bounds),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(height: 4),
              isSelected
                  ? const SizedBox() // white text below
                  : const SizedBox(),
              isSelected
                  ? Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              )
                  : ShaderMask(
                shaderCallback: (bounds) =>
                    gradient.createShader(bounds),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        height: 60, // compact height
        decoration: const BoxDecoration(
          color: Colors.black,
        ),
        child: Row(
          children: [
            _buildNavItem(
              icon: Icons.home,
              label: "Home",
              index: 0,
            ),
            _buildNavItem(
              icon: Icons.queue_play_next_sharp,
              label: "AI Plan",
              index: 1,
            ),
            _buildNavItem(
              icon: Icons.calculate,
              label: "Calculator",
              index: 2,
            ),
            _buildNavItem(
              icon: Icons.badge_outlined,
              label: "Profile",
              index: 3,
            ),
          ],
        ),
      ),
    );
  }
}