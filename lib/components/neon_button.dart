import 'package:flutter/material.dart';
import '../theme/theme.dart';

class NeonButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed; // Make nullable to support disabled state
  final bool isPrimary;
  final bool isLoading;

  const NeonButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isPrimary = true,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: isPrimary && !isLoading && onPressed != null
            ? [
                BoxShadow(
                  color: AppTheme.neonGreen.withValues(alpha: 0.4),
                  blurRadius: 10,
                  spreadRadius: 1,
                )
              ]
            : [],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? AppTheme.neonGreen : Colors.transparent,
          foregroundColor: isPrimary ? Colors.black : AppTheme.neonGreen,
          disabledBackgroundColor: isPrimary ? AppTheme.neonGreen.withValues(alpha: 0.5) : Colors.transparent,
          side: isPrimary ? BorderSide.none : const BorderSide(color: AppTheme.neonGreen, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isPrimary ? Colors.black : AppTheme.neonGreen,
                  ),
                ),
              )
            : Text(text),
      ),
    );
  }
}
