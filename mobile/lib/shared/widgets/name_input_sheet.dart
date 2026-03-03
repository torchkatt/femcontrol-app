import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// BottomSheet que solicita el nombre de la usuaria.
/// Devuelve el nombre ingresado o null si se omite.
class NameInputSheet extends StatefulWidget {
  final void Function(String? name) onConfirm;
  const NameInputSheet({super.key, required this.onConfirm});

  @override
  State<NameInputSheet> createState() => _NameInputSheetState();
}

class _NameInputSheetState extends State<NameInputSheet> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 28,
        right: 28,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 36,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Ícono decorativo
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.terracotta, AppColors.terracottaLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.terracotta.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.waving_hand_rounded, color: Colors.white, size: 34),
          ),
          const SizedBox(height: 20),

          // Título
          const Text(
            '¿Cómo te llamas?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Te saludaremos por tu nombre cada vez que abras la app.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),

          // Campo de nombre
          TextField(
            controller: _controller,
            focusNode: _focus,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Tu nombre',
              hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.5)),
              prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.terracotta),
              filled: true,
              fillColor: AppColors.inputFill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.terracotta, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            ),
            onSubmitted: (v) => widget.onConfirm(v.trim().isEmpty ? null : v.trim()),
          ),
          const SizedBox(height: 16),

          // Botón confirmar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final name = _controller.text.trim();
                widget.onConfirm(name.isEmpty ? null : name);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.terracotta,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              child: const Text('Continuar'),
            ),
          ),
          const SizedBox(height: 10),

          // Omitir
          TextButton(
            onPressed: () => widget.onConfirm(null),
            child: Text(
              'Omitir',
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper para mostrar el NameInputSheet desde cualquier pantalla.
Future<String?> showNameInputSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => NameInputSheet(
      onConfirm: (name) => Navigator.pop(ctx, name),
    ),
  );
}
