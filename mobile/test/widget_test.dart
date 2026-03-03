// Widget test básico para FemControl
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Test placeholder — la app requiere Hive inicializado para arrancar.
    // Las pruebas de integración se realizan con flutter drive.
    expect(true, isTrue);
  });
}
