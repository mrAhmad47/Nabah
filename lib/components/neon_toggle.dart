import 'package:flutter/material.dart';
import '../theme/theme.dart';

class NeonToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const NeonToggle({
    Key? key,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppTheme.neonGreen,
      activeTrackColor: AppTheme.neonGreen.withValues(alpha: 0.3),
      inactiveThumbColor: Colors.grey,
      inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
    );
  }
}
