import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/pet_config.dart';
import '../../../shared/services/local_db_service.dart';
import '../../../core/theme/app_theme.dart';

class PetSelectionScreen extends ConsumerStatefulWidget {
  const PetSelectionScreen({super.key});

  @override
  ConsumerState<PetSelectionScreen> createState() => _PetSelectionScreenState();
}

class _PetSelectionScreenState extends ConsumerState<PetSelectionScreen> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = ref.read(localDbServiceProvider).getSelectedPet();
  }

  Future<void> _save(String petId) async {
    await ref.read(localDbServiceProvider).setSelectedPet(petId);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgCream,
      appBar: AppBar(
        backgroundColor: AppColors.bgCream,
        elevation: 0,
        title: const Text(
          'Elige tu mascota',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Preview de la mascota seleccionada
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Column(
              children: [
                Text(
                  petById(_selected).emoji,
                  style: const TextStyle(fontSize: 90),
                ),
                const SizedBox(height: 8),
                Text(
                  petById(_selected).name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  petById(_selected).description,
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.divider, height: 1),
          // Grid de mascotas
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemCount: kPets.length,
              itemBuilder: (_, i) {
                final pet = kPets[i];
                final isSelected = pet.id == _selected;
                return GestureDetector(
                  onTap: () => setState(() => _selected = pet.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? pet.color
                          : AppColors.bgCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppColors.terracotta : AppColors.divider,
                        width: isSelected ? 2.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.terracotta.withOpacity(0.18),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              )
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(pet.emoji, style: const TextStyle(fontSize: 32)),
                        const SizedBox(height: 4),
                        Text(
                          pet.name,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? AppColors.terracottaDark : AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle_rounded,
                              size: 14, color: AppColors.terracotta),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Botón confirmar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _save(_selected),
                child: const Text('Confirmar mascota'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
