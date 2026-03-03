import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'primary_button.dart';

class CycleBottomSheet extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback onLogAction;

  const CycleBottomSheet({
    super.key,
    required this.title,
    required this.description,
    required this.onLogAction,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required String description,
    required VoidCallback onLogAction,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => CycleBottomSheet(
        title: title,
        description: description,
        onLogAction: onLogAction,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: AppColors.sage.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          
          Text(
            description,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 32),
          
          PrimaryButton(
            text: 'Registrar Ahora',
            onPressed: () {
              Navigator.of(context).pop();
              onLogAction();
            },
            isSecondary: false, // Usará color Terracotta
          ),
          
          const SizedBox(height: 12),
          PrimaryButton(
            text: 'Cerrar',
            onPressed: () => Navigator.of(context).pop(),
            isSecondary: true, // Usará color Verde Salvia
          ),
        ],
      ),
    );
  }
}
