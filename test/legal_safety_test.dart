import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:xike_bac_au/app/theme/app_theme.dart';
import 'package:xike_bac_au/core/services/storage_service.dart';
import 'package:xike_bac_au/features/legal/legal_view.dart';
import 'package:xike_bac_au/features/legal/legal_content.dart';
import 'package:xike_bac_au/features/safety/safety_view.dart';

import 'widget_test.dart' show MemoryStorage;

class FailingStorage extends MemoryStorage {
  @override
  Future<void> write(String key, dynamic value) async {
    values[key] = value;
    throw Exception('disk full');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await LegalContent.data;
  });
  late MemoryStorage storage;
  setUp(() {
    Get.testMode = true;
    storage = MemoryStorage();
    Get.put<StorageService>(storage);
  });
  tearDown(() async {
    Get.reset();
  });

  Future<void> mountGate(WidgetTester t) async {
    await t.pumpWidget(
      GetMaterialApp(
        theme: appTheme(),
        initialRoute: '/safety?next=%2Fhold',
        getPages: [
          GetPage(
            name: '/',
            page: () => const Scaffold(body: Text('Home')),
          ),
          GetPage(
            name: '/safety',
            page: () => SafetyView(nextRoute: Get.parameters['next']),
          ),
          GetPage(
            name: '/hold',
            page: () => const Scaffold(body: Text('Training')),
            middlewares: [SafetyMiddleware()],
          ),
        ],
      ),
    );
    await t.pumpAndSettle();
  }

  test(
    'Both training routes require the current acknowledgement version',
    () async {
      final gate = SafetyMiddleware();
      for (final route in ['/hold', '/breathing']) {
        expect(gate.redirect(route)!.name, startsWith('/safety?next='));
      }
      await storage.write(
        SafetyAcknowledgement.key,
        SafetyAcknowledgement.version,
      );
      expect(gate.redirect('/hold'), isNull);
      expect(gate.redirect('/breathing'), isNull);
      await storage.write(SafetyAcknowledgement.key, 0);
      expect(gate.redirect('/hold'), isNotNull);
    },
  );

  testWidgets('Deferring does not accept or start training', (t) async {
    await mountGate(t);
    expect(
      t
          .widget<FilledButton>(find.byKey(const ValueKey('safety-continue')))
          .onPressed,
      isNull,
    );
    await t.tap(find.text('Để sau, về trang chủ'));
    await t.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    expect(SafetyAcknowledgement.accepted, false);
    expect(find.text('Training'), findsNothing);
    Get.toNamed('/hold');
    await t.pumpAndSettle();
    expect(find.text('Tập thở an toàn'), findsOneWidget);
    expect(find.text('Training'), findsNothing);
  });

  testWidgets(
    'Explicit acknowledgement persists and continues intended route',
    (t) async {
      await mountGate(t);
      await t.scrollUntilVisible(
        find.byKey(const ValueKey('safety-check')),
        350,
        scrollable: find.byType(Scrollable).first,
      );
      await t.tap(find.byKey(const ValueKey('safety-check')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('safety-continue')));
      await t.pumpAndSettle();
      expect(SafetyAcknowledgement.accepted, true);
      expect(
        storage.read<int>(SafetyAcknowledgement.key),
        SafetyAcknowledgement.version,
      );
      expect(find.text('Training'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets('Failed persistence keeps training gated and allows retry', (
    t,
  ) async {
    Get.delete<StorageService>(force: true);
    Get.put<StorageService>(FailingStorage());
    await mountGate(t);
    await t.scrollUntilVisible(
      find.byKey(const ValueKey('safety-check')),
      350,
      scrollable: find.byType(Scrollable).first,
    );
    await t.tap(find.byKey(const ValueKey('safety-check')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('safety-continue')));
    await t.pumpAndSettle();
    expect(SafetyAcknowledgement.accepted, false);
    expect(
      find.text('Không lưu được xác nhận. Vui lòng thử lại.'),
      findsOneWidget,
    );
    expect(find.text('Training'), findsNothing);
  });

  testWidgets(
    'Legal documents and safety fit a narrow screen with larger text',
    (t) async {
      t.view.physicalSize = const Size(320, 640);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      for (final document in ['privacy', 'terms', 'support']) {
        await t.pumpWidget(
          GetMaterialApp(
            theme: appTheme(),
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: LegalView(document),
            ),
          ),
        );
        await t.pumpAndSettle();
        expect(find.textContaining('Cập nhật: 25/11/2026'), findsOneWidget);
        expect(t.takeException(), isNull);
      }
      await t.pumpWidget(const SizedBox());
      await t.pumpAndSettle();
      await mountGate(t);
      await t.scrollUntilVisible(
        find.byKey(const ValueKey('safety-check')),
        350,
        scrollable: find.byType(Scrollable).first,
      );
      expect(t.takeException(), isNull);
    },
  );
}
