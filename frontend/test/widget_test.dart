import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:campus_food_delivery/main.dart';
import 'package:campus_food_delivery/services/api_service.dart';
import 'package:campus_food_delivery/state/app_state.dart';

void main() {
  testWidgets('App boots to campus picker', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final api = ApiService();
    final state = AppState(api);
    await state.loadPersisted();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiService>.value(value: api),
          ChangeNotifierProvider<AppState>.value(value: state),
        ],
        child: const CampusFoodApp(),
      ),
    );
    await tester.pump();
    expect(find.textContaining('campus'), findsWidgets);
  });
}
