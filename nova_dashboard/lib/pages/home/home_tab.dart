// lib/pages/home/home_tab.dart
// Pasa onNavigateToPlaces a StatsDashboardPage para que los chips
// de tipo abran Lugares con el filtro correcto
import 'package:flutter/material.dart';
import '../stats_dashboard_page.dart';

class HomeTab extends StatelessWidget {
  final void Function(int index)?    onNavigate;
  final void Function(String tipo)?  onNavigateToPlaces;
  final int placesIndex;
  final int rewardsIndex;
  final int reportsIndex;

  const HomeTab({
    Key? key,
    this.onNavigate,
    this.onNavigateToPlaces,
    this.placesIndex  = 1,
    this.rewardsIndex = 3,
    this.reportsIndex = 4,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StatsDashboardPage(
      onNavigate:         onNavigate,
      onNavigateToPlaces: onNavigateToPlaces,
      placesIndex:        placesIndex,
      rewardsIndex:       rewardsIndex,
      reportsIndex:       reportsIndex,
    );
  }
}