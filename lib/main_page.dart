import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pages/home_page.dart';
import 'providers/home_provider.dart';
import 'pages/user_profile.dart';
import 'pages/calculator_ui.dart';
import 'aiplanpages/body_results_screen.dart';
import 'features/flashfit/presentation/flashfit_home_screen.dart';

class MainPage extends ConsumerStatefulWidget {
  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    HomePage(),
    BodyResultsScreen(),
    const FlashFitHomeScreen(),
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
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              isSelected
                  ? Icon(icon, color: Colors.white, size: 22)
                  : ShaderMask(
                      shaderCallback: (bounds) =>
                          gradient.createShader(bounds),
                      child: Icon(icon, color: Colors.white, size: 22),
                    ),
              const SizedBox(height: 3),
              isSelected
                  ? Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
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
                          fontSize: 11,
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

  // Highlighted Premium Nav Item for FlashFit
  Widget _buildHighlightedNavItem({required int index}) {
    final bool isSelected = _selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onItemTapped(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [
                            Color(0xFF00E5FF),
                            Color(0xFF6366F1),
                          ],
                        )
                      : LinearGradient(
                          colors: [
                            const Color(0xFF00E5FF).withOpacity(0.18),
                            const Color(0xFF6366F1).withOpacity(0.18),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : const Color(0xFF00E5FF).withOpacity(0.6),
                    width: 1.2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF00E5FF).withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.bolt_rounded,
                      size: 16,
                      color: isSelected ? Colors.black : const Color(0xFF00E5FF),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'FlashFit',
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? const Color(0xFF00E5FF)
                      : Colors.transparent,
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
        height: 64, // optimized compact height for 5 items
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A10),
          border: Border(
            top: BorderSide(
              color: Colors.white.withOpacity(0.08),
              width: 0.8,
            ),
          ),
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
            _buildHighlightedNavItem(
              index: 2,
            ),
            _buildNavItem(
              icon: Icons.calculate,
              label: "Calculator",
              index: 3,
            ),
            _buildNavItem(
              icon: Icons.badge_outlined,
              label: "Profile",
              index: 4,
            ),
          ],
        ),
      ),
    );
  }
}
