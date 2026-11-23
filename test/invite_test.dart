import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:xike_bac_au/app/theme/app_theme.dart';
import 'package:xike_bac_au/features/invite/invite_access.dart';
import 'package:xike_bac_au/features/invite/invite_gate.dart';

import 'widget_test.dart' show MemoryStorage;

class FailingInviteStorage extends MemoryStorage {
  bool fail = true;
  @override
  Future<void> write(String key, dynamic value) async {
    await super.write(key, value);
    if (fail) throw StateError('disk full');
  }
}

void main() {
  test(
    'Both codes activate and persist; invalid or removed codes stay locked',
    () async {
      for (final code in ['max', 'chuotbu', ' MAX ']) {
        final storage = MemoryStorage();
        expect(InviteAccess.isActivated(storage), false);
        expect(await InviteAccess.activate(storage, code), true);
        expect(InviteAccess.isActivated(storage), true);
      }
      for (final code in ['', 'wrong', 'max123', 'old-code']) {
        final storage = MemoryStorage();
        expect(await InviteAccess.activate(storage, code), false);
        await storage.write(InviteAccess.storageKey, code);
        expect(InviteAccess.isActivated(storage), false);
      }
    },
  );

  Future<void> mount(WidgetTester tester, MemoryStorage storage) async {
    await tester.pumpWidget(
      GetMaterialApp(
        theme: appTheme(),
        builder: (context, child) =>
            InviteGate(storage: storage, child: child!),
        home: const Scaffold(body: Text('Private training')),
      ),
    );
    await tester.pumpAndSettle();
  }

  tearDown(() => Get.reset());

  testWidgets(
    'Gate blocks all private content, rejects wrong code, then opens once',
    (tester) async {
      final storage = MemoryStorage();
      await mount(tester, storage);
      expect(find.text('Private training'), findsNothing);
      await tester.enterText(
        find.byKey(const ValueKey('invite-code')),
        'wrong',
      );
      await tester.tap(find.byKey(const ValueKey('invite-submit')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Mã mời không đúng'), findsOneWidget);
      expect(find.text('Private training'), findsNothing);
      await tester.enterText(
        find.byKey(const ValueKey('invite-code')),
        'chuotbu',
      );
      await tester.tap(find.byKey(const ValueKey('invite-submit')));
      await tester.pumpAndSettle();
      expect(find.text('Private training'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await mount(tester, storage);
      expect(find.byKey(const ValueKey('invite-code')), findsNothing);
      expect(find.text('Private training'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Persistence failure remains locked, rolls back and supports retry',
    (tester) async {
      final storage = FailingInviteStorage();
      await mount(tester, storage);
      await tester.enterText(find.byKey(const ValueKey('invite-code')), 'max');
      await tester.tap(find.byKey(const ValueKey('invite-submit')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Không lưu được mã mời'), findsOneWidget);
      expect(find.text('Private training'), findsNothing);
      expect(InviteAccess.isActivated(storage), false);
      storage.fail = false;
      await tester.tap(find.byKey(const ValueKey('invite-submit')));
      await tester.pumpAndSettle();
      expect(find.text('Private training'), findsOneWidget);
    },
  );

  testWidgets('Invite form fits narrow screens with larger text and keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(1.5),
            viewInsets: const EdgeInsets.only(bottom: 250),
          ),
          child: child!,
        ),
        home: InviteGate(
          storage: MemoryStorage(),
          child: const Text('Private training'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('invite-submit')),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.takeException(), isNull);
  });
}
