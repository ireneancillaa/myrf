import 'package:flutter/material.dart';

class FarmInfoCardItem {
  const FarmInfoCardItem({
    required this.label,
    required this.value,
    required this.iconAsset,
    required this.iconBgColor,
    required this.cardBgColor,
  });

  final String label;
  final String value;
  final String iconAsset;
  final Color iconBgColor;
  final Color cardBgColor;
}

class SampleFarmInfo {
  const SampleFarmInfo({
    required this.strain,
    required this.hatchery,
    required this.breedingFarm,
    required this.docInDate,
    required this.numberOfBirds,
    required this.dietReplication,
  });

  final String strain;
  final String hatchery;
  final String breedingFarm;
  final String docInDate;
  final String numberOfBirds;
  final String dietReplication;
}

class QuickActionItem {
  const QuickActionItem({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
}

class BroodingCardItem {
  const BroodingCardItem({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.valueColor,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final Color valueColor;
  final String label;
}
