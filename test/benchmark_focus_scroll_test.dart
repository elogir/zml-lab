import 'dart:async';

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart' show DefaultMaterialLocalizations;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zml_lab/core/execution/native_io.dart';
import 'package:zml_lab/core/theme/app_theme.dart';
import 'package:zml_lab/features/benchmark/application/benchmark_chat_controller.dart';
import 'package:zml_lab/features/benchmark/presentation/benchmark_focus.dart';
import 'package:zml_lab/models/benchmark_chat.dart';

/// A chat whose reply the test streams by hand.
class _FakeChat extends BenchmarkChatController {
  @override
  BenchmarkChat build(String jobId, int index, ChatEndpoint endpoint) =>
      const BenchmarkChat(
        turns: [
          ChatTurn(fromUser: true, text: 'tell me a long story'),
          ChatTurn(fromUser: false, streaming: true),
        ],
      );

  /// The streaming reply grows by [lines] lines.
  void grow(int lines) {
    final reply = state.turns.last;
    final more = [
      for (var i = 0; i < lines; i++) 'line ${reply.text.length}-$i',
    ].join('\n\n');
    state = state.copyWith(
      turns: [
        ...state.turns.take(state.turns.length - 1),
        reply.copyWith(text: '${reply.text}$more\n\n'),
      ],
    );
  }
}

/// A chat whose long reply has finished.
class _FinishedChat extends BenchmarkChatController {
  @override
  BenchmarkChat build(String jobId, int index, ChatEndpoint endpoint) =>
      BenchmarkChat(
        turns: [
          const ChatTurn(fromUser: true, text: 'tell me a long story'),
          ChatTurn(
            fromUser: false,
            text: [for (var i = 0; i < 120; i++) 'line $i'].join('\n\n'),
          ),
        ],
      );
}

void main() {
  final endpoint = ChatEndpoint.hostPort('127.0.0.1', 8000);
  final provider = benchmarkChatControllerProvider('j', 1, endpoint);

  /// Opens the chat popup on [chat].
  Future<ProviderContainer> open(
    WidgetTester tester,
    BenchmarkChatController Function() chat,
  ) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final home = GlobalKey();
    final container = ProviderContainer(
      overrides: [provider.overrideWith(chat)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: WidgetsApp(
          color: const Color(0xFF000000),
          localizationsDelegates: const [
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
          builder: (context, child) =>
              AppTheme(colors: AppColors.dark, child: child!),
          pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
            settings: settings,
            pageBuilder: (context, _, _) => builder(context),
          ),
          home: SizedBox.expand(key: home),
        ),
      ),
    );
    unawaited(showBenchmarkFocus(home.currentContext!, 'j', 1, endpoint));
    await tester.pumpAndSettle();
    return container;
  }

  ScrollPosition position(WidgetTester tester) =>
      tester.state<ScrollableState>(find.byType(Scrollable).first).position;

  testWidgets('a finished chat opens at its end', (tester) async {
    await open(tester, _FinishedChat.new);
    final p = position(tester);
    expect(p.maxScrollExtent, greaterThan(0));
    expect(p.pixels, closeTo(p.maxScrollExtent, 1));
    expect(find.text('Scroll to bottom'), findsNothing);
  });

  testWidgets('scroll while it streams; the button goes back and follows', (
    tester,
  ) async {
    final container = await open(tester, _FakeChat.new);
    final chat = container.read(provider.notifier) as _FakeChat;
    ScrollPosition position() =>
        tester.state<ScrollableState>(find.byType(Scrollable).first).position;
    bool atBottom() => position().pixels >= position().maxScrollExtent - 1;

    // Streaming: it follows the tail.
    chat.grow(80);
    await tester.pumpAndSettle();
    expect(position().maxScrollExtent, greaterThan(0));
    expect(atBottom(), isTrue);
    expect(find.text('Scroll to bottom'), findsNothing);

    // The slightest scroll up — one small wheel notch — is enough: the next
    // token doesn't pull it back.
    final list = tester.getCenter(find.byType(Scrollable).first);
    final bottom = position().pixels;
    final mouse = TestPointer(1, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(mouse.hover(list));
    await tester.sendEventToBinding(mouse.scroll(const Offset(0, -8)));
    await tester.pump();
    expect(position().pixels, bottom - 8);
    chat.grow(5);
    await tester.pumpAndSettle();
    expect(position().pixels, bottom - 8);
    expect(find.text('Scroll to bottom'), findsOneWidget);
    await tester.tap(find.text('Scroll to bottom'));
    await tester.pumpAndSettle();
    expect(atBottom(), isTrue);

    // A light drag with tokens arriving between its moves — touch, and a
    // trackpad's two-finger scroll: the jump that follows a token mustn't
    // cancel it.
    for (final kind in [PointerDeviceKind.touch, PointerDeviceKind.trackpad]) {
      final drag = await tester.startGesture(list, kind: kind);
      for (var k = 0; k < 8; k++) {
        await drag.moveBy(const Offset(0, 5));
        chat.grow(1);
        await tester.pump();
      }
      await drag.up();
      await tester.pumpAndSettle();
      expect(atBottom(), isFalse, reason: '$kind');
      expect(find.text('Scroll to bottom'), findsOneWidget, reason: '$kind');
      await tester.tap(find.text('Scroll to bottom'));
      await tester.pumpAndSettle();
      expect(atBottom(), isTrue, reason: '$kind');
    }

    // The user scrolls up mid-stream: it stays put as text keeps arriving.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 300));
    await tester.pumpAndSettle();
    final readingAt = position().pixels;
    chat.grow(20);
    await tester.pumpAndSettle();
    expect(position().pixels, readingAt);
    expect(atBottom(), isFalse);
    expect(find.text('Scroll to bottom'), findsOneWidget);

    // The button: back to the bottom, and following again.
    await tester.tap(find.text('Scroll to bottom'));
    await tester.pumpAndSettle();
    expect(atBottom(), isTrue);
    expect(find.text('Scroll to bottom'), findsNothing);
    chat.grow(20);
    await tester.pumpAndSettle();
    expect(atBottom(), isTrue);

    // Scrolling back down by hand resumes following too.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 200));
    await tester.pumpAndSettle();
    expect(find.text('Scroll to bottom'), findsOneWidget);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(find.text('Scroll to bottom'), findsNothing);
    chat.grow(20);
    await tester.pumpAndSettle();
    expect(atBottom(), isTrue);
    expect(tester.takeException(), isNull);
  });
}
