import 'package:flutter_test/flutter_test.dart';
import 'package:demo_vehicle_management/main.dart';
import 'package:demo_vehicle_management/screens/auth/login_screen.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(
      const DemoVehicleApp(
        home: LoginScreen(),
      ),
    );

    expect(find.text('Demo Vehicle Management'), findsOneWidget);
  });
}