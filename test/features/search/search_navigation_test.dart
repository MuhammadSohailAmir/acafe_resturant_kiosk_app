import 'package:acafe_customer/features/kiosk/widgets/kiosk_tap.dart';
import 'package:acafe_customer/features/search/search_flow_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('navigateBack pops when navigator can pop', (tester) async {
    late GoRouter router;

    router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: KioskTap(
              onTap: () => context.push('/child'),
              child: const Text('open'),
            ),
          ),
        ),
        GoRoute(
          path: '/child',
          builder: (context, state) => Scaffold(
            body: KioskTap(
              onTap: () => SearchFlowHelper.navigateBack(context),
              child: const Text('back'),
            ),
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('back'), findsOneWidget);

    await tester.tap(find.text('back'));
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('navigateBack closes modal sheet before page route', (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: Builder(
          builder: (context) => Scaffold(
            body: KioskTap(
              onTap: () {
                showModalBottomSheet<void>(
                  context: context,
                  useRootNavigator: false,
                  builder: (_) => const Text('filter sheet'),
                );
              },
              child: const Text('open sheet'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open sheet'));
    await tester.pumpAndSettle();
    expect(find.text('filter sheet'), findsOneWidget);

    SearchFlowHelper.navigateBack(navigatorKey.currentContext!);
    await tester.pumpAndSettle();
    expect(find.text('filter sheet'), findsNothing);
    expect(find.text('open sheet'), findsOneWidget);
  });
}
