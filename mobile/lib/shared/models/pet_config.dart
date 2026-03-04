import 'package:flutter/material.dart';

class PetConfig {
  final String id;
  final String emoji;
  final String name;
  final String description;
  final Color color;

  const PetConfig({
    required this.id,
    required this.emoji,
    required this.name,
    required this.description,
    required this.color,
  });
}

const List<PetConfig> kPets = [
  PetConfig(
    id: 'llama',
    emoji: '🦙',
    name: 'Llama',
    description: 'Tranquila y resiliente',
    color: Color(0xFFF5D5C0),
  ),
  PetConfig(
    id: 'cat',
    emoji: '🐱',
    name: 'Gatita',
    description: 'Independiente y cariñosa',
    color: Color(0xFFD4E8FF),
  ),
  PetConfig(
    id: 'bunny',
    emoji: '🐰',
    name: 'Conejita',
    description: 'Dulce y curiosa',
    color: Color(0xFFFFE5E5),
  ),
  PetConfig(
    id: 'fox',
    emoji: '🦊',
    name: 'Zorra',
    description: 'Astuta y vivaz',
    color: Color(0xFFFFE5C8),
  ),
  PetConfig(
    id: 'panda',
    emoji: '🐼',
    name: 'Panda',
    description: 'Calmada y adorable',
    color: Color(0xFFE8F5E9),
  ),
  PetConfig(
    id: 'hedgehog',
    emoji: '🦔',
    name: 'Erizo',
    description: 'Pequeña y valiente',
    color: Color(0xFFF0E8D0),
  ),
  PetConfig(
    id: 'deer',
    emoji: '🦌',
    name: 'Cervatilla',
    description: 'Elegante y sensible',
    color: Color(0xFFE8F0E5),
  ),
  PetConfig(
    id: 'bear',
    emoji: '🐻',
    name: 'Osita',
    description: 'Protectora y amorosa',
    color: Color(0xFFD5C8B8),
  ),
];

PetConfig petById(String id) =>
    kPets.firstWhere((p) => p.id == id, orElse: () => kPets.first);
