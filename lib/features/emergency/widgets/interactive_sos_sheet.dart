import 'package:flutter/material.dart';
import '../../../screens/emergency/categorized_sos_dialog.dart';
import '../../../services/sos_service.dart';

class InteractiveSosSheet {
  static Future<void> show(BuildContext context) {
    return CategorizedSosDialog.show(
      context,
      sosService: SosService(),
    );
  }
}
