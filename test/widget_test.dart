import 'package:flutter_test/flutter_test.dart';

import 'package:myportofolio_mobile/main.dart';
import 'package:myportofolio_mobile/screens/menu.dart';
import 'package:myportofolio_mobile/widgets/project_card.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('InfoCard menampilkan NPM, nama, dan kelas', (tester) async {
    await tester.pumpWidget(MyApp(apiClient: fakeApiClient()));

    expect(find.text('2506656412'), findsOneWidget);
    expect(find.text('Alfredo Harsono'), findsOneWidget);
    expect(find.text('PBP C'), findsOneWidget);
  });

  testWidgets('setiap ItemCard punya warna latar berbeda', (tester) async {
    await tester.pumpWidget(MyApp(apiClient: fakeApiClient()));

    final colors = tester
        .widgetList<ItemCard>(find.byType(ItemCard))
        .map((card) => card.item.color)
        .toSet();
    expect(colors.length, MyHomePage.items.length);
  });

  for (final item in MyHomePage.items) {
    testWidgets('menekan ${item.name} memunculkan SnackBar', (tester) async {
      await tester.pumpWidget(MyApp(apiClient: fakeApiClient()));

      await tester.ensureVisible(find.text(item.name));
      await tester.tap(find.text(item.name));
      await tester.pump();

      expect(
        find.text('Kamu telah menekan tombol ${item.name}!'),
        findsOneWidget,
      );
    });
  }
}
