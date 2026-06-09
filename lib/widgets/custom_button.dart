import 'package:flutter/material.dart';
import '../theme.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isSecondary;
  final bool isLoading;
  final double? width;

  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isSecondary = false,
    this.isLoading = false,
    this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: isSecondary ? Colors.white : AppTheme.primaryColor,
      foregroundColor: isSecondary ? AppTheme.primaryColor : Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isSecondary 
            ? const BorderSide(color: AppTheme.primaryColor, width: 1.5)
            : BorderSide.none,
      ),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
    );

    return SizedBox(
      width: width ?? double.infinity,
      child: ElevatedButton(
        style: buttonStyle,
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                text,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: isSecondary ? AppTheme.primaryColor : Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
