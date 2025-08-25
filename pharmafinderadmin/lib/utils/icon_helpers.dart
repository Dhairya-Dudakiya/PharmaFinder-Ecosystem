import 'package:flutter/material.dart';

IconData getMedicineIcon(String iconName) {
  switch (iconName.toLowerCase()) {
    case 'pill':
      return Icons.medication;
    case 'syrup':
      return Icons.local_drink;
    case 'ointment':
      return Icons.healing;
    case 'injection':
      return Icons.vaccines;
    case 'capsule':
      return Icons.medication_liquid;
    case 'vitamin':
      return Icons.local_pharmacy;
    case 'eye':
      return Icons.remove_red_eye;
    case 'firstaid':
      return Icons.emergency;
    case 'pain':
      return Icons.healing;
    case 'cold':
      return Icons.ac_unit;
    case 'allergy':
      return Icons.air;
    case 'digestive':
      return Icons.restaurant;
    case 'antibiotic':
      return Icons.biotech;
    case 'skincare':
      return Icons.spa;
    case 'diabetes':
      return Icons.bloodtype;
    case 'bp':
    case 'bloodpressure':
      return Icons.favorite;
    case 'mental':
      return Icons.psychology;
    case 'women':
      return Icons.female;
    case 'heart':
      return Icons.monitor_heart;
    case 'fever':
      return Icons.thermostat;
    case 'cough':
      return Icons.sick;
    case 'baby':
      return Icons.child_care;
    default:
      return Icons.medical_services;
  }
}
