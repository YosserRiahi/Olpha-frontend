import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'tabs/buyer_home_tab.dart';
import 'tabs/buyer_favorites_tab.dart';
import 'tabs/buyer_messages_tab.dart';
import 'tabs/buyer_profile_tab.dart';

class BuyerShellScreen extends StatefulWidget {
  const BuyerShellScreen({super.key});

  @override
  State<BuyerShellScreen> createState() => _BuyerShellScreenState();
}

class _BuyerShellScreenState extends State<BuyerShellScreen> {
  int _index = 0;

  void _switchTo(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: IndexedStack(
        index: _index,
        children: const [
          BuyerHomeTab(),
          BuyerFavoritesTab(),
          BuyerMessagesTab(),
          BuyerProfileTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _switchTo,
        backgroundColor: Colors.white,
        indicatorColor: AppTheme.primary.withValues(alpha: 0.12),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon:
                Icon(Icons.home_rounded, color: AppTheme.primary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: const Icon(Icons.favorite_border_rounded),
            selectedIcon:
                Icon(Icons.favorite_rounded, color: Colors.red.shade600),
            label: 'Favorites',
          ),
          const NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded,
                color: AppTheme.primary),
            label: 'Messages',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon:
                Icon(Icons.person_rounded, color: AppTheme.primary),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
