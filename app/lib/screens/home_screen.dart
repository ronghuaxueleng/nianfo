import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'dedication_screen.dart';
import 'chanting_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DedicationScreen(),
    const ChantingScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.orange.shade700,
        unselectedItemColor: Colors.grey.shade600,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: '回向文',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.self_improvement),
            label: '修行记录',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '个人中心',
          ),
        ],
      ),
    );
  }
}