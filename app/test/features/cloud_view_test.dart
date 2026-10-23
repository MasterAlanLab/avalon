import 'package:av_core/av_core.dart';
import 'package:av_design/av_design.dart';
import 'package:avalon/app/app_error.dart';
import 'package:avalon/app/avalon_app.dart';
import 'package:avalon/cloud/cloud_models.dart';
import 'package:avalon/cloud/sync_lifecycle_models.dart';
import 'package:avalon/features/cloud/cloud_state.dart';
import 'package:avalon/features/cloud/cloud_view.dart';
import 'package:avalon/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

AccountResponse _account({bool paid = false}) => AccountResponse(
  account: const CloudAccount(
    id: 'account-a',
    email: 'fixture@example.invalid',
    displayName: null,
  ),
  entitlement: paid
      ? CloudEntitlement(
          plan: EntitlementPlan.monthly,
          source: PurchaseSource.web,
          status: 'active',
          expiresAt: DateTime.utc(2027),
        )
      : null,
  devices: [
    CloudDevice(
      id: 'current',
      name: 'This Mac',
      os: DeviceOs.macos,
      syncActive: false,
      lastSeenAt: DateTime.utc(2026, 10, 11),
    ),
    CloudDevice(
      id: 'other',
      name: 'Other Phone',
      os: DeviceOs.ios,
      syncActive: false,
      lastSeenAt: DateTime.utc(2026, 10, 10),
    ),
  ],
  currentDeviceId: 'current',
  deviceLimit: 10,
  syncActiveDeviceCount: 0,
);

CloudState _signedIn() => CloudState(
  initialized: true,
  signedIn: true,
  sessionGeneration: 1,
  currentDeviceId: 'current',
  email: 'fixture@example.invalid',
  account: _account(),
);

SyncLifecycleStatus _lifecycle({
  String backupState = 'rebuildRequired',
  String spaceState = 'active',
  String owner = 'other',
  String attempt = '11111111-1111-4111-8111-111111111111',
  bool cleanupPending = false,
  String? cleanupKeyState,
}) => SyncLifecycleStatus.fromJson({
  'accountId': 'account-a',
  'deviceId': 'current',
  'syncGeneration': '22222222-2222-4222-8222-222222222222',
  'spaceOrigin': 'rebuilt',
  'headRevision': 0,
  'spaceState': spaceState,
  'backupState': backupState,
  'entitlementExpiresAt': '2026-10-13T08:00:00Z',
  'retentionUntil': '2026-11-12T08:00:00Z',
  'rebuild': backupState == 'rebuilding'
      ? {
          'syncGeneration': '22222222-2222-4222-8222-222222222222',
          'attemptId': attempt,
          'ownerDeviceId': owner,
          'manifestId': '33333333-3333-4333-8333-333333333333',
          'phase': 'staging',
          'recordCount': 5,
          'stagedRecordCount': 2,
          'publishedCursor': null,
          'startedAt': '2026-10-13T08:10:00Z',
          'finishedAt': null,
          'serverTime': '2026-10-13T08:15:00Z',
        }
      : null,
  'cleanup': {
    'pendingGenerationCount': cleanupPending ? 1 : 0,
    'latestRetiredGeneration': cleanupPending || cleanupKeyState != null
        ? '44444444-4444-4444-8444-444444444444'
        : null,
    'latestRetiredAt': cleanupPending || cleanupKeyState != null
        ? '2026-10-13T07:00:00Z'
        : null,
    'onlineState': cleanupPending || cleanupKeyState != null
        ? 'complete'
        : 'none',
    'keyState': cleanupKeyState ?? (cleanupPending ? 'waiting' : 'none'),
  },
  'serverTime': '2026-10-13T08:15:00Z',
});

void main() {
  final calls = <String>[];
  late ValueNotifier<CloudState> state;

  setUp(calls.clear);

  Future<void> pump(
    WidgetTester tester,
    CloudState initial, {
    bool desktop = false,
    Locale locale = const Locale('zh', 'CN'),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = desktop
        ? const Size(1100, 1000)
        : const Size(390, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    state = ValueNotifier(initial);
    addTearDown(state.dispose);
    await tester.pumpWidget(
      CupertinoApp(
        locale: locale,
        supportedLocales: supportedAppLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: AvAppFrame(colors: AvColors.light, child: child!),
        ),
        home: ValueListenableBuilder<CloudState>(
          valueListenable: state,
          builder: (context, state, _) {
            final view = CloudView(
              state: state,
              onStartEmail: (email) => calls.add('send:$email'),
              onVerify: (code) => calls.add('verify:$code'),
              onChangeEmail: () => calls.add('change'),
              onReload: () => calls.add('reload'),
              onLogout: () => calls.add('logout'),
              onRemoveDevice: (id) => calls.add('remove:$id'),
              onDeleteAccount: () => calls.add('delete'),
              onRetryRevocations: () => calls.add('retry'),
              onSync: () => calls.add('sync'),
              onRebuildFromDevice: (takeOver) =>
                  calls.add(takeOver ? 'claim' : 'rebuild'),
              onCancelRebuild: () => calls.add('cancel-rebuild'),
            );
            return desktop ? AvDensity.desktop(child: view) : view;
          },
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> tapKey(
    WidgetTester tester,
    String key, {
    bool settle = true,
  }) async {
    final finder = find.byKey(ValueKey(key));
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  Finder input(String key) => find.descendant(
    of: find.byKey(ValueKey(key)),
    matching: find.byType(CupertinoTextField),
  );

  testWidgets('email flow keeps leading code zeros and uses real expiry', (
    tester,
  ) async {
    await pump(tester, const CloudState(initialized: true));
    await tapKey(tester, 'cloud-send');
    expect(calls, isEmpty);
    await tester.enterText(input('cloud-email'), '  user@example.invalid  ');
    await tester.pump();
    await tapKey(tester, 'cloud-send');
    expect(calls, ['send:user@example.invalid']);

    state.value = state.value.copyWith(
      challengeId: 'never-shown-challenge',
      challengeExpiresAt: DateTime.utc(2026, 10, 11, 7, 10),
    );
    await tester.pump();
    expect(find.text('never-shown-challenge'), findsNothing);
    expect(find.textContaining('验证码有效至'), findsOneWidget);
    expect(find.text('重新发送'), findsOneWidget);
    await tester.enterText(input('cloud-code'), '012345');
    await tester.pump();
    await tapKey(tester, 'cloud-verify');
    expect(calls.last, 'verify:012345');
    await tapKey(tester, 'cloud-send');
    expect(calls.last, 'send:user@example.invalid');
    // A successful send has no fabricated 60-second cooldown.
    expect(find.textContaining('秒后可重新发送'), findsNothing);
    expect(find.text('通过 Apple 登录'), findsNothing);
    expect(find.text('恢复购买'), findsNothing);
  });

  testWidgets('recreated challenge page can resend and change its email', (
    tester,
  ) async {
    await pump(tester, const CloudState(initialized: true));
    await tester.enterText(input('cloud-email'), 'user@example.invalid');
    await tester.pump();
    await tapKey(tester, 'cloud-send');
    state.value = state.value.copyWith(
      challengeId: 'never-shown-challenge',
      challengeEmail: 'user@example.invalid',
      challengeExpiresAt: DateTime.utc(2026, 10, 11, 7, 10),
    );
    await tester.pump();

    final challenge = state.value;
    await tester.pumpWidget(const SizedBox.shrink());
    await pump(tester, challenge);
    expect(input('cloud-email'), findsNothing);
    expect(find.text('never-shown-challenge'), findsNothing);
    await tapKey(tester, 'cloud-send');
    expect(calls, ['send:user@example.invalid', 'send:user@example.invalid']);

    await tester.ensureVisible(find.text('更换邮箱'));
    await tester.tap(find.text('更换邮箱'));
    await tester.pumpAndSettle();
    expect(calls.last, 'change');
    state.value = state.value.copyWith(clearChallenge: true);
    await tester.pump();
    expect(
      tester.widget<CupertinoTextField>(input('cloud-email')).controller!.text,
      'user@example.invalid',
    );
    await tester.enterText(input('cloud-email'), ' other@example.invalid ');
    await tester.pump();
    await tapKey(tester, 'cloud-send');
    expect(calls.last, 'send:other@example.invalid');
  });

  testWidgets(
    'code entry supports whole-code fill and explicit keyboard login',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await pump(tester, const CloudState(initialized: true));
      await tester.enterText(input('cloud-email'), 'user@example.invalid');
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.next);
      expect(calls, ['send:user@example.invalid']);

      state.value = state.value.copyWith(
        challengeId: 'challenge',
        challengeEmail: 'user@example.invalid',
        challengeExpiresAt: DateTime.utc(2027),
      );
      await tester.pump();
      await tester.pump();
      final field = tester.widget<CupertinoTextField>(input('cloud-code'));
      expect(field.autofillHints, contains(AutofillHints.oneTimeCode));
      expect(
        find.bySemanticsLabel(RegExp(RegExp.escape('user@example.invalid'))),
        findsOneWidget,
      );
      final editable = tester.widget<EditableText>(
        find.descendant(
          of: find.byKey(const ValueKey('cloud-code')),
          matching: find.byType(EditableText),
        ),
      );
      expect(editable.focusNode.hasFocus, isTrue);
      // A whole-code fill follows the same path as paste or OS AutoFill.
      await tester.enterText(input('cloud-code'), '01 23a45');
      await tester.pump();
      expect(field.controller!.text, '012345');
      expect(calls, ['send:user@example.invalid']);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      expect(calls.last, 'verify:012345');

      state.value = state.value.copyWith(busy: true);
      await tester.pump();
      final before = calls.length;
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tapKey(tester, 'cloud-verify', settle: false);
      expect(calls.length, before);
      semantics.dispose();
    },
  );

  testWidgets('busy and retry feedback keep the email and form position', (
    tester,
  ) async {
    await pump(tester, const CloudState(initialized: true));
    await tester.enterText(input('cloud-email'), 'user@example.invalid');
    await tester.pump();
    final fieldTop = tester.getTopLeft(input('cloud-email')).dy;
    state.value = state.value.copyWith(busy: true);
    await tester.pump();
    expect(tester.getTopLeft(input('cloud-email')).dy, fieldTop);
    await tapKey(tester, 'cloud-send', settle: false);
    expect(calls, isEmpty);

    state.value = state.value.copyWith(
      busy: false,
      error: CloudUiError.offline,
    );
    await tester.pump();
    expect(tester.getTopLeft(input('cloud-email')).dy, fieldTop);
    expect(
      tester.widget<CupertinoTextField>(input('cloud-email')).controller!.text,
      'user@example.invalid',
    );
    final l = AppLocalizations.of(tester.element(find.byType(CloudView)));
    expect(find.text(l.cloudErrorOffline), findsOneWidget);
    await tapKey(tester, 'cloud-send');
    expect(calls, ['send:user@example.invalid']);
  });

  testWidgets(
    'large text and keyboard keep narrow verification actions usable',
    (tester) async {
      await pump(
        tester,
        CloudState(
          initialized: true,
          challengeId: 'challenge',
          challengeEmail: 'long.email.address@example.invalid',
          challengeExpiresAt: DateTime.utc(2027),
        ),
        locale: const Locale('en'),
        textScale: 2,
      );
      tester.view.physicalSize = const Size(320, 640);
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      await tester.pump();
      await tester.ensureVisible(input('cloud-code'));
      await tester.enterText(input('cloud-code'), '012345');
      await tester.pump();
      await tapKey(tester, 'cloud-verify');
      expect(calls, ['verify:012345']);
      await tapKey(tester, 'cloud-send');
      expect(calls.last, 'send:long.email.address@example.invalid');
      final l = AppLocalizations.of(tester.element(find.byType(CloudView)));
      await tester.ensureVisible(find.text(l.cloudChangeEmail));
      await tester.tap(find.text(l.cloudChangeEmail));
      await tester.pump();
      expect(calls.last, 'change');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('free account shows real zero slots and preserves device rows', (
    tester,
  ) async {
    await pump(tester, _signedIn(), desktop: true);
    expect(find.text('免费账户'), findsOneWidget);
    expect(find.text('设备 · 0 / 10'), findsOneWidget);
    expect(find.byType(Dismissible), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('cloud-device-current')),
        matching: find.byType(AvPressable),
      ),
      findsNothing,
    );
    expect(find.text('立即同步'), findsNothing);
    expect(find.text('升级到 Cloud'), findsNothing);
    await tapKey(tester, 'cloud-reload');
    expect(calls, ['reload']);

    await tester.longPress(find.byKey(const ValueKey('cloud-device-other')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('移除'));
    await tester.pumpAndSettle();
    expect(find.text('移除「Other Phone」？'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(calls, ['reload']);

    await tester.longPress(find.byKey(const ValueKey('cloud-device-other')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('移除'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('移除'));
    await tester.pumpAndSettle();
    expect(calls.last, 'remove:other');
    // Server confirmation, rather than an optimistic dismissal, owns removal.
    expect(find.byKey(const ValueKey('cloud-device-other')), findsOneWidget);
  });

  testWidgets('paid sync shows real progress, blockers and last completion', (
    tester,
  ) async {
    await pump(
      tester,
      _signedIn().copyWith(
        account: _account(paid: true),
        syncAvailable: true,
        syncBlockedReason: 'DEVICE_LIMIT',
      ),
      desktop: true,
    );
    expect(find.text('云同步'), findsOneWidget);
    expect(find.text('从未同步'), findsOneWidget);
    expect(find.text('同步设备名额已满，请先移除其他设备后重试。'), findsOneWidget);
    await tapKey(tester, 'cloud-sync');
    expect(calls, ['sync']);

    state.value = state.value.copyWith(syncing: true, clearSyncBlock: true);
    await tester.pump();
    expect(find.text('正在同步…'), findsOneWidget);
    await tapKey(tester, 'cloud-sync');
    expect(calls, ['sync']);
    state.value = state.value.copyWith(
      syncing: false,
      lastSyncAt: DateTime.utc(2026, 10, 13, 8, 30),
      syncBlockedReason: 'OFFLINE',
    );
    await tester.pump();
    expect(find.text('从未同步'), findsNothing);
    expect(find.textContaining('2026-10-13'), findsWidgets);
    expect(find.textContaining('无法连接 Cloud'), findsOneWidget);
    await tapKey(tester, 'cloud-sync');
    expect(calls, ['sync', 'sync']);
    expect(find.text('升级到 Cloud'), findsNothing);
  });

  testWidgets('cloud native resource refusal has a safe actionable message', (
    tester,
  ) async {
    await pump(tester, const CloudState(initialized: true));
    final l = AppLocalizations.of(tester.element(find.byType(CloudView)));
    const error = CompileException(
      CompileErrorCode.invalidSetting,
      subject: 'cloud.networkGuard',
      detail: 'synthetic-private-node-details',
    );
    final mapped = AppError.from(error);
    expect(mapped.code, 'cloud.networkGuard');
    expect(mapped.message(l), l.cloudNetworkGuard);
    expect(compileErrorText(l, error), mapped.message(l));
    expect(mapped.message(l).contains(error.detail), isFalse);
  });

  testWidgets(
    'rebuild needs confirmation and stale lifecycle approval is ignored',
    (tester) async {
      await pump(
        tester,
        _signedIn().copyWith(syncAvailable: true, lifecycle: _lifecycle()),
        desktop: true,
      );
      expect(find.byKey(const ValueKey('cloud-sync')), findsNothing);
      await tapKey(tester, 'cloud-rebuild-start');
      expect(find.text('从此设备重建云端备份？'), findsOneWidget);
      expect(find.textContaining('完整备份仅包含此设备上该账号的当前可同步内容'), findsOneWidget);
      expect(find.textContaining('请先核对其他设备上的待上传修改'), findsOneWidget);
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(calls, isEmpty);

      await tapKey(tester, 'cloud-rebuild-start');
      state.value = state.value.copyWith(
        lifecycle: _lifecycle(backupState: 'rebuilding'),
      );
      await tester.pump();
      await tester.tap(find.text('从此设备重建').last);
      await tester.pumpAndSettle();
      expect(calls, isEmpty);

      state.value = state.value.copyWith(lifecycle: _lifecycle());
      await tester.pump();
      await tapKey(tester, 'cloud-rebuild-start');
      await tester.tap(find.text('从此设备重建').last);
      await tester.pumpAndSettle();
      expect(calls, ['rebuild']);
    },
  );

  testWidgets(
    'rebuild owner sees staged progress and must confirm cancellation',
    (tester) async {
      await pump(
        tester,
        _signedIn().copyWith(
          syncAvailable: true,
          lifecycle: _lifecycle(backupState: 'rebuilding', owner: 'current'),
          pendingMergeCount: 2,
        ),
        desktop: true,
      );
      expect(find.text('已上传 2 / 5 条'), findsOneWidget);
      expect(find.text('保留 2 项待合并的本机修改'), findsOneWidget);
      expect(find.textContaining('完整备份发布后完成同步'), findsOneWidget);
      expect(find.byKey(const ValueKey('cloud-rebuild-claim')), findsNothing);
      expect(find.text('从未同步'), findsNothing);
      await tapKey(tester, 'cloud-rebuild-resume');
      expect(calls, ['sync']);
      await tapKey(tester, 'cloud-rebuild-cancel');
      expect(find.text('取消本次重建？'), findsOneWidget);
      await tester.tap(find.text('取消重建').last);
      await tester.pumpAndSettle();
      expect(calls, ['sync', 'cancel-rebuild']);
    },
  );

  testWidgets('taking over requires approval of the same attempt and session', (
    tester,
  ) async {
    await pump(
      tester,
      _signedIn().copyWith(
        syncAvailable: true,
        lifecycle: _lifecycle(backupState: 'rebuilding'),
      ),
      desktop: true,
    );
    expect(find.byKey(const ValueKey('cloud-rebuild-cancel')), findsNothing);
    expect(find.byKey(const ValueKey('cloud-rebuild-resume')), findsNothing);
    await tapKey(tester, 'cloud-rebuild-claim');
    expect(find.textContaining('原尝试中尚未发布的内容将舍弃'), findsOneWidget);
    state.value = state.value.copyWith(
      lifecycle: _lifecycle(
        backupState: 'rebuilding',
        attempt: '55555555-5555-4555-8555-555555555555',
      ),
    );
    await tester.pump();
    await tester.tap(find.text('由此设备接管重建').last);
    await tester.pumpAndSettle();
    expect(calls, isEmpty);

    await tapKey(tester, 'cloud-rebuild-claim');
    state.value = state.value.copyWith(sessionGeneration: 2);
    await tester.pump();
    await tester.tap(find.text('由此设备接管重建').last);
    await tester.pumpAndSettle();
    expect(calls, isEmpty);

    await tapKey(tester, 'cloud-rebuild-claim');
    await tester.tap(find.text('由此设备接管重建').last);
    await tester.pumpAndSettle();
    expect(calls, ['claim']);
  });

  testWidgets('sync engine keeps a free account local without a sync action', (
    tester,
  ) async {
    await pump(
      tester,
      _signedIn().copyWith(syncAvailable: true),
      desktop: true,
    );
    expect(find.text('配置保存在本机。有效订阅可启用云同步。'), findsOneWidget);
    expect(find.byKey(const ValueKey('cloud-sync')), findsNothing);
    expect(find.textContaining('同步尚未开放'), findsNothing);
  });

  testWidgets('logout requires confirmation and busy actions stay disabled', (
    tester,
  ) async {
    await pump(tester, _signedIn(), desktop: true);
    await tapKey(tester, 'cloud-logout');
    expect(find.text('退出 Avalon 账号？'), findsOneWidget);
    expect(find.textContaining('本机的配置、节点和代理凭据全部保留'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(calls, isEmpty);
    await tapKey(tester, 'cloud-logout');
    await tester.tap(find.text('退出登录').last);
    await tester.pumpAndSettle();
    expect(calls, ['logout']);
    state.value = state.value.copyWith(busy: true);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('cloud-reload')));
    await tester.pump();
    expect(calls, ['logout']);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('deletion requires both confirmations and cancellation is safe', (
    tester,
  ) async {
    await pump(tester, _signedIn(), desktop: true);
    await tapKey(tester, 'cloud-delete');
    expect(find.text('删除 Avalon 账号？'), findsOneWidget);
    await tester.tap(find.text('继续'));
    await tester.pumpAndSettle();
    expect(find.text('确认永久删除账号？'), findsOneWidget);
    expect(find.textContaining('账号将永久删除'), findsOneWidget);
    expect(find.textContaining('订阅及自动续费请前往原购买渠道另行取消'), findsOneWidget);
    expect(calls, isEmpty);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(calls, isEmpty);
    await tapKey(tester, 'cloud-delete');
    await tester.tap(find.text('继续'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除账号').last);
    await tester.pumpAndSettle();
    expect(calls, ['delete']);
  });

  testWidgets('a confirmation from an old sign-in cannot delete the new one', (
    tester,
  ) async {
    await pump(tester, _signedIn(), desktop: true);
    await tapKey(tester, 'cloud-delete');
    await tester.tap(find.text('继续'));
    await tester.pumpAndSettle();
    state.value = state.value.copyWith(sessionGeneration: 2);
    await tester.pump();
    await tester.tap(find.text('删除账号').last);
    await tester.pumpAndSettle();
    expect(calls, isEmpty);
  });

  testWidgets('revocation and deletion notices are localized and truthful', (
    tester,
  ) async {
    await pump(
      tester,
      CloudState(
        initialized: true,
        pendingRevocationCount: 1,
        revocationUnconfirmed: true,
        accountDeleted: true,
        deletionNotice: CancelSubscriptionNotice(
          required: true,
          sources: [PurchaseSource.apple, PurchaseSource.google],
        ),
      ),
      desktop: true,
      locale: const Locale('en'),
    );
    expect(
      find.text('1 original sessions waiting for revocation'),
      findsOneWidget,
    );
    expect(
      find.textContaining('remote revocation could not be confirmed'),
      findsOneWidget,
    );
    expect(find.textContaining('App Store / Google Play'), findsOneWidget);
    await tester.tap(find.text('Retry revocation now'));
    await tester.pump();
    expect(calls, ['retry']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('only a server rate-limit deadline disables resend', (
    tester,
  ) async {
    await pump(tester, const CloudState(initialized: true));
    await tester.enterText(input('cloud-email'), 'user@example.invalid');
    state.value = state.value.copyWith(
      challengeId: 'challenge',
      challengeExpiresAt: DateTime.utc(2026, 10, 11),
      resendAvailableAt: DateTime.now().add(const Duration(seconds: 30)),
      error: CloudUiError.rateLimited,
      retryAfterSeconds: 30,
    );
    await tester.pump();
    expect(find.textContaining('秒后可重新发送'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('cloud-send')));
    await tester.tap(find.byKey(const ValueKey('cloud-send')));
    await tester.pump();
    expect(calls, isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
