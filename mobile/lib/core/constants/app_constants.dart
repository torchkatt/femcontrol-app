class AppConstants {
  static const String appName = 'FemControl';
  static const String baseUrl = 'http://localhost:4000/api';
  static const String tunnelUrl = 'http://localhost:8081';

  // Moods
  static const List<String> moods = [
    'Feliz 😊', 'Tranquila 😌', 'Ansiosa 😰', 'Irritable 😤',
    'Triste 😢', 'Enérgica ⚡', 'Cansada 😴', 'Sensible 💙',
  ];

  // Symptoms
  static const List<String> symptoms = [
    'Calambres', 'Hinchazón', 'Dolor de cabeza', 'Acné',
    'Náuseas', 'Senos sensibles', 'Antojo de dulces', 'Insomnio',
  ];

  // Phase names
  static const Map<String, String> phaseNames = {
    'menstrual': 'Menstrual',
    'folicular': 'Folicular',
    'ovulacion': 'Ovulación',
    'lutea': 'Lútea',
  };

  static const Map<String, String> phaseDescriptions = {
    'menstrual': 'Tu cuerpo se renueva. Descansa y cuídate.',
    'folicular': 'Energía en aumento. ¡Es tu momento!',
    'ovulacion': 'Máxima fertilidad y vitalidad.',
    'lutea': 'Tiempo de introspección y calma.',
  };
}
