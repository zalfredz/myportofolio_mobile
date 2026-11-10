import 'package:flutter_test/flutter_test.dart';

import 'package:myportofolio_mobile/main.dart';
import 'package:myportofolio_mobile/menu.dart';

void main() {
  testWidgets('InfoCard menampilkan NPM, nama, dan kelas', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('2506656412'), findsOneWidget);
    expect(find.text('Alfredo Harsono'), findsOneWidget);
    expect(find.text('PBP C'), findsOneWidget);
  });

  testWidgets('setiap ItemCard punya warna latar berbeda', (tester) async {
    await tester.pumpWidget(const MyApp());

    final colors = tester
        .widgetList<ItemCard>(find.byType(ItemCard))
        .map((card) => card.item.color)
        .toSet();
    expect(colors.length, MyHomePage.items.length);
  });

  for (final item in MyHomePage.items) {
    testWidgets('menekan ${item.name} memunculkan SnackBar', (tester) async {
      await tester.pumpWidget(const MyApp());

      await tester.tap(find.text(item.name));
      await tester.pump();

      expect(
        find.text('Kamu telah menekan tombol ${item.name}!'),
        findsOneWidget,
      );
    });
  }
}
