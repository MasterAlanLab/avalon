import 'dart:async';
import 'package:avalon/common/common.dart';
import 'package:avalon/core/method.dart';
import 'package:avalon/features/tailscale/model.dart';
import 'package:avalon/features/tailscale/provider.dart';
import 'package:avalon/l10n/l10n.dart';
import 'package:avalon/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

String tailscaleText(AppLocalizations l, String code) => switch (code) {
  'loading' => l.tsLoading,
  'loggedOut' => l.tsLoggedOut,
  'authorizing' => l.tsAuthorizing,
  'waitingApproval' => l.tsWaitingApproval,
  'starting' => l.tsConnecting,
  'running' => l.tsLoggedIn,
  'paused' => l.tsPaused,
  'stopping' => l.tsStopping,
  'needsLogin' || 'needs_login' => l.tsNeedsLogin,
  'backendDisconnected' || 'backend_disconnected' => l.tsBackendDisconnected,
  'service_stopped' => l.tsServiceStopped,
  'no_profile' => l.tsNoProfile,
  'rule_mode_required' => l.tsRuleRequired,
  'proxy_apps_only' => l.tsProxyOnly,
  'ipv6_not_captured' => l.tsIPv6Missing,
  'subnet_conflict' => l.tsSubnetConflict,
  'exit_unbound' => l.tsNoBinding,
  'missing_exit_groups' => l.tsMissingBinding,
  'capture_pending' || 'capture_missing_prefix' => l.tsCapturePending,
  'capture_apply_failed' => l.tsCaptureFailed,
  'invalid_auth_url' => l.tsInvalidAuthURL,
  'error' ||
  'backend_error' ||
  'backend_start_failed' ||
  'backend_close_failed' ||
  'identity_storage_failed' => l.tsBackendError,
  'active' => l.tsActive,
  'inactive' => l.tsInactive,
  'partial' => l.tsPartial,
  'pending' => l.tsPending,
  'off' => l.tsOff,
  'blocked' => l.tsBlocked,
  'fallback' => l.tsFallback,
  'testing' => l.tsTesting,
  'success' => l.tsProbeSuccess,
  'failed' => l.tsProbeFailed,
  'cancelled' => l.tsCancelled,
  'expired' => l.tsProbeExpired,
  'direct' => l.tsDirectPath,
  'derp' => l.tsDerpPath,
  'peerRelay' => l.tsPeerRelay,
  'unapproved_exit' => l.tsUnapprovedExit,
  'unsupported' => l.tsUnsupported,
  'config_apply_failed' => l.tsApplyFailed,
  'control_health_warning' => l.tsControlWarning,
  'auth_invalid' => l.tsAuthInvalid,
  'auth_expired' => l.tsAuthExpired,
  'auth_used' => l.tsAuthUsed,
  'auth_rejected' => l.tsAuthRejected,
  'server_unreachable' => l.tsServerUnreachable,
  'logout_failed' || 'identity_cleanup_failed' => l.tsLogoutFailed,
  'invalid_control_url' || 'control_requires_https' => l.tsInvalidServer,
  _ => l.tsUnknown,
};

class TailscalePage extends ConsumerStatefulWidget {
  const TailscalePage({super.key});
  @override
  ConsumerState<TailscalePage> createState() => _TailscalePageState();
}

class _TailscalePageState extends ConsumerState<TailscalePage> {
  late final TailscaleRequest _request;
  @override
  void initState() {
    super.initState();
    _request = ref.read(tailscaleRequestProvider);
  }

  final _server = TextEditingController();
  final _key = TextEditingController();
  String _search = '';
  String _filter = 'all';
  String? _selected;
  bool _custom = false;
  TailscaleController get controller => ref.read(tailscaleProvider.notifier);
  @override
  void dispose() {
    _key.clear();
    _key.dispose();
    _server.dispose();
    // Stop only explicit UI probes; the app-owned status watcher stays alive.
    unawaited(
      _request(
        CoreMethod.tailscaleCancelProbes,
      ).catchError((_) => <String, dynamic>{}),
    );
    super.dispose();
  }

  Future<bool> _confirm(String text) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.appLocalizations.tailscale),
          content: Text(text),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.appLocalizations.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.appLocalizations.confirm),
            ),
          ],
        ),
      ) ??
      false;
  Future<void> _login(bool key) async {
    if (key && _key.text.trim().isEmpty) return;
    final arguments = {
      'kind': key ? 'key' : 'browser',
      'control': _custom ? _server.text.trim() : '',
      'authKey': key ? _key.text.trim() : '',
    };
    _key.clear();
    await controller.command(CoreMethod.tailscaleLogin, arguments);
    arguments['authKey'] = '';
  }

  Future<void> _copy(String text) =>
      Clipboard.setData(ClipboardData(text: text));
  Future<void> _qr(String text) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.appLocalizations.tsQRCode),
        content: SizedBox(
          width: 280,
          height: 280,
          child: ColoredBox(
            color: Colors.white,
            child: QrImageView(data: text, padding: const EdgeInsets.all(16)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.appLocalizations.cancel),
          ),
        ],
      ),
    );
  }

  Widget _panel(Widget child, {Key? key}) => Card(
    key: key,
    child: Padding(padding: const EdgeInsets.all(16), child: child),
  );
  Widget _addresses(List<String> addresses) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final ip in addresses)
        InkWell(
          onTap: () => _copy(ip),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: SelectableText(
                    ip,
                    style: const TextStyle(fontFamily: 'JetBrainsMono'),
                  ),
                ),
                IconButton(
                  onPressed: () => _copy(ip),
                  tooltip: context.appLocalizations.copy,
                  icon: const Icon(Icons.copy, size: 18),
                ),
              ],
            ),
          ),
        ),
    ],
  );
  Widget _status(TailscaleViewState view) {
    final l = context.appLocalizations;
    final s = view.snapshot;
    final error =
        view.error ??
        (s.error == 'config_apply_failed' || s.error == 'control_health_warning'
            ? null
            : s.error);
    return _panel(
      key: const ValueKey('tailscale-session-header'),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                s.session == 'running'
                    ? Icons.check_circle_outline
                    : Icons.hub_outlined,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  tailscaleText(l, s.session),
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (s.session != 'loggedOut' && s.session != 'loading')
                PopupMenuButton<CoreMethod>(
                  key: const ValueKey('tailscale-session-actions'),
                  tooltip: l.more,
                  enabled: !view.busy,
                  onSelected: (method) async {
                    if (method == CoreMethod.tailscaleLogout &&
                        !await _confirm(l.tsLogoutConfirm))
                      return;
                    if (!mounted) return;
                    await controller.command(method);
                  },
                  itemBuilder: (_) => [
                    if (s.session == 'running' || s.session == 'paused')
                      PopupMenuItem(
                        value: s.session == 'paused'
                            ? CoreMethod.tailscaleResume
                            : CoreMethod.tailscalePause,
                        child: Text(
                          s.session == 'paused' ? l.tsResume : l.tsPause,
                        ),
                      ),
                    PopupMenuItem(
                      value: CoreMethod.tailscaleLogout,
                      child: Text(l.tsLogout),
                    ),
                  ],
                ),
            ],
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      tailscaleText(l, error),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                  if (view.error != null)
                    TextButton(
                      onPressed: view.busy ? null : controller.refresh,
                      child: Text(l.tsRetry),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Capture conditions belong to the routing controls, not the account header.
  Widget _routingStatus(
    TailscaleSnapshot s, {
    bool exit = false,
    String? description,
  }) {
    final l = context.appLocalizations;
    final enabled = exit
        ? (s.prefs['exitId'] as String? ?? '').isNotEmpty
        : s.prefs['autoRoute'] == true || s.prefs['acceptRoutes'] == true;
    final reasons = enabled
        ? [
            if (s.error == 'config_apply_failed') s.error!,
            ...s.reasons.where(
              (reason) => exit
                  ? reason != 'subnet_conflict'
                  : reason != 'exit_unbound' && reason != 'missing_exit_groups',
            ),
          ]
        : <String>[];
    final title = Text(
      '${exit ? l.tsExit : l.tsSplit}: ${tailscaleText(l, exit ? s.exitState : s.split)}',
    );
    final detail = reasons.isEmpty
        ? description
        : tailscaleText(l, reasons.first);
    final subtitle = detail == null
        ? null
        : Text(detail, maxLines: 2, overflow: TextOverflow.ellipsis);
    if (reasons.length < 2) return ListTile(title: title, subtitle: subtitle);
    return ExpansionTile(
      title: title,
      subtitle: subtitle,
      children: [
        for (final reason in reasons)
          ListTile(dense: true, title: Text(tailscaleText(l, reason))),
      ],
    );
  }

  Widget _loginPanel(TailscaleViewState view) {
    final l = context.appLocalizations;
    final s = view.snapshot;
    return _panel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.tsIntro,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.tsCustomServer),
            value: _custom,
            onChanged: view.busy ? null : (v) => setState(() => _custom = v),
          ),
          if (_custom)
            TextField(
              controller: _server,
              decoration: InputDecoration(
                labelText: l.tsControlServer,
                hintText: 'https://HOST',
              ),
              keyboardType: TextInputType.url,
              autocorrect: false,
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _key,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            decoration: InputDecoration(labelText: l.tsAuthKey),
            onSubmitted: (_) => _login(true),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: view.busy ? null : () => _login(false),
                child: Text(l.tsBrowserLogin),
              ),
              OutlinedButton(
                onPressed: view.busy ? null : () => _login(true),
                child: Text(l.tsKeyLogin),
              ),
            ],
          ),
          if (s.authUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            SelectableText(s.authUrl),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton.icon(
                  onPressed: () async {
                    final url = Uri.tryParse(s.authUrl);
                    if (url != null)
                      await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      );
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: Text(l.tsOpenBrowser),
                ),
                TextButton.icon(
                  onPressed: () => _copy(s.authUrl),
                  icon: const Icon(Icons.copy),
                  label: Text(l.copy),
                ),
                TextButton.icon(
                  onPressed: () => _qr(s.authUrl),
                  icon: const Icon(Icons.qr_code),
                  label: Text(l.tsQRCode),
                ),
              ],
            ),
          ],
          if ([
            'authorizing',
            'waitingApproval',
            'starting',
          ].contains(s.session))
            TextButton(
              onPressed: view.busy
                  ? null
                  : () => controller.command(CoreMethod.tailscaleCancel),
              child: Text(l.tsCancelLogin),
            ),
        ],
      ),
    );
  }

  String _probeLabel(TailscaleSnapshot s, TailscaleDevice d) {
    final p = tsMap(s.probes[d.id]);
    final l = context.appLocalizations;
    if (p.isEmpty) return l.tsNotTested;
    final label = tailscaleText(l, p['state'] as String? ?? 'unknown');
    return p['state'] == 'success'
        ? '$label · ${(p['latencyMs'] as num? ?? 0).toStringAsFixed(1)} ms · ${tailscaleText(l, p['path'] as String? ?? 'unknown')}'
        : label;
  }

  Widget _deviceDetails(
    TailscaleSnapshot s,
    TailscaleDevice d,
    bool busy, {
    bool isSelf = false,
  }) {
    final l = context.appLocalizations;
    final expiry = DateTime.tryParse(d.keyExpiry ?? '');
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isSelf ? l.tsThisDevice : (d.name.isEmpty ? l.tsUnknown : d.name),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          if (isSelf && d.name.isNotEmpty) Text(d.name),
          if (isSelf && s.user.isNotEmpty) Text(s.user),
          if (d.tags.isNotEmpty) Text(d.tags.join(', ')),
          if (d.dnsName.isEmpty)
            Text(l.tsNotProvided)
          else
            _addresses([d.dnsName]),
          Text('${l.tsOS}: ${d.os.isEmpty ? l.tsUnknown : d.os}'),
          if (!isSelf) ...[
            Text(d.online ? l.tsOnline : l.tsOffline),
            Text('${l.tsLastSeen}: ${d.lastSeen ?? l.tsNotProvided}'),
          ],
          _addresses(d.ips),
          if (isSelf) ...[
            Text(
              '${l.tsKeyExpiry}: ${expiry == null ? l.tsNotProvided : MaterialLocalizations.of(context).formatCompactDate(expiry.toLocal())}',
            ),
            Text(
              l.tsEmbeddedNote,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ] else ...[
            Text(_probeLabel(s, d)),
            Text(
              l.tsProbeExplanation,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (d.routes.isNotEmpty) ...[
            Text(l.tsApprovedRoutes),
            for (final r in d.routes) SelectableText(r),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (!isSelf)
                FilledButton.icon(
                  onPressed: busy || s.session != 'running'
                      ? null
                      : () => controller.probe([d.id]),
                  icon: const Icon(Icons.speed),
                  label: Text(l.tsTest),
                ),
              if (!isSelf && d.exit)
                OutlinedButton(
                  onPressed: busy
                      ? null
                      : () => controller.preferences({'exitId': d.id}),
                  child: Text(l.tsUseExit),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showDeviceDetails(
    TailscaleSnapshot s,
    TailscaleDevice d,
    bool busy, {
    bool isSelf = false,
  }) => showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: SingleChildScrollView(
          child: _deviceDetails(s, d, busy, isSelf: isSelf),
        ),
      ),
    ),
  );

  Widget _devices(TailscaleViewState view, bool wide) {
    final l = context.appLocalizations;
    final s = view.snapshot;
    final devices = s.devices
        .where(
          (d) =>
              (_filter != 'online' || d.online) &&
              (_filter != 'exit' || d.exit) &&
              '${d.name} ${d.dnsName} ${d.ips.join(' ')}'
                  .toLowerCase()
                  .contains(_search.toLowerCase()),
        )
        .toList();
    final selected = s.devices.where((d) => d.id == _selected).firstOrNull;
    final self = s.self;
    final address = self?.ips.firstOrNull;
    final list = ListView(
      children: [
        if (self != null)
          Card(
            child: ListTile(
              key: const ValueKey('tailscale-self'),
              leading: const Icon(Icons.devices_outlined),
              title: Text(l.tsThisDevice),
              subtitle: address == null
                  ? null
                  : Text(
                      address,
                      style: const TextStyle(fontFamily: 'JetBrainsMono'),
                    ),
              trailing: address == null
                  ? const Icon(Icons.chevron_right)
                  : IconButton(
                      onPressed: () => _copy(address),
                      tooltip: l.copy,
                      icon: const Icon(Icons.copy, size: 18),
                    ),
              onTap: () => _showDeviceDetails(s, self, view.busy, isSelf: true),
            ),
          ),
        if (s.cached ||
            s.control == 'degraded' ||
            s.error == 'control_health_warning')
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              s.control == 'degraded' || s.error == 'control_health_warning'
                  ? l.tsControlWarning
                  : l.tsCachedWarning,
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: InputDecoration(
              labelText: l.tsSearch,
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final item in {
                'all': l.tsAll,
                'online': l.tsOnline,
                'exit': l.tsExit,
              }.entries)
                FilterChip(
                  label: Text(item.value),
                  selected: _filter == item.key,
                  onSelected: (_) => setState(() => _filter = item.key),
                ),
              if (devices.isNotEmpty)
                IconButton(
                  onPressed: view.busy || s.session != 'running'
                      ? null
                      : () =>
                            controller.probe(devices.map((d) => d.id).toList()),
                  tooltip: l.tsTestAll,
                  icon: const Icon(Icons.speed),
                ),
              if (s.probes.values.any((p) => tsMap(p)['state'] == 'testing'))
                IconButton(
                  onPressed: view.busy ? null : controller.cancelProbes,
                  tooltip: l.tsStopTests,
                  icon: const Icon(Icons.stop_circle_outlined),
                ),
              IconButton(
                onPressed: view.busy
                    ? null
                    : () => controller.command(CoreMethod.tailscaleRefresh),
                tooltip: l.tsRefreshDevices,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        if (devices.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              s.devices.isEmpty ? l.tsNoDevices : l.tsNoSearchResults,
            ),
          ),
        for (final d in devices)
          ListTile(
            selected: d.id == _selected,
            leading: Icon(d.exit ? Icons.exit_to_app : Icons.devices_outlined),
            title: Text(
              d.name.isEmpty ? d.id : d.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${d.ips.join(' · ')}\n${d.online ? l.tsOnline : l.tsOffline} · ${_probeLabel(s, d)}',
            ),
            isThreeLine: true,
            onTap: () {
              setState(() => _selected = d.id);
              if (!wide) _showDeviceDetails(s, d, view.busy);
            },
          ),
      ],
    );
    if (!wide) return list;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 3, child: list),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            child: selected == null
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(l.tsSelectDevice),
                  )
                : _deviceDetails(s, selected, view.busy),
          ),
        ),
      ],
    );
  }

  Widget _routing(TailscaleViewState view) {
    final l = context.appLocalizations;
    final s = view.snapshot;
    final p = s.prefs;
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        _routingStatus(s),
        SwitchListTile(
          title: Text(l.tsAutoRoute),
          subtitle: Text(l.tsAutoRouteDesc),
          value: p['autoRoute'] == true,
          onChanged: view.busy
              ? null
              : (v) => controller.preferences({'autoRoute': v}),
        ),
        SwitchListTile(
          title: Text(l.tsAcceptRoutes),
          subtitle: Text(l.tsAcceptRoutesDesc),
          value: p['acceptRoutes'] == true,
          onChanged: view.busy
              ? null
              : (v) => controller.preferences({'acceptRoutes': v}),
        ),
        for (final r in s.routes)
          ListTile(
            title: Text(r['prefix'] as String),
            subtitle: Text(
              '${r['accepted'] == true ? (r['captured'] == true ? l.tsAccepted : l.tsCapturePending) : l.tsAvailable}${r['conflict'] == true ? ' · ${l.tsSubnetConflict}' : ''}\n${(r['publishers'] as List? ?? []).join(', ')}',
            ),
            trailing: r['conflict'] == true
                ? DropdownButton<String>(
                    value: r['choice'] as String? ?? 'local',
                    items: [
                      DropdownMenuItem(
                        value: 'local',
                        child: Text(l.tsKeepLocal),
                      ),
                      DropdownMenuItem(
                        value: 'remote',
                        child: Text(l.tsUseRemote),
                      ),
                    ],
                    onChanged: view.busy
                        ? null
                        : (choice) async {
                            if (choice == 'remote' &&
                                !await _confirm(l.tsRemoteWarning))
                              return;
                            await controller.preferences({
                              'routeChoices': {
                                ...tsMap(p['routeChoices']),
                                r['prefix'] as String: choice,
                              },
                            });
                          },
                  )
                : null,
          ),
      ],
    );
  }

  Widget _exit(TailscaleViewState view) {
    final l = context.appLocalizations;
    final s = view.snapshot;
    final p = s.prefs;
    final exits = s.devices.where((d) => d.exit).toList();
    final exitId = p['exitId'] as String? ?? '';
    final bindings = tsMap(p['bindings']);
    final bound = tsStrings(bindings[s.profileId]);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _routingStatus(s, exit: true, description: l.tsExitDesc),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          key: ValueKey(exitId),
          initialValue: exitId,
          decoration: InputDecoration(labelText: l.tsExitDevice),
          isExpanded: true,
          items: [
            DropdownMenuItem(value: '', child: Text(l.tsOff)),
            if (exitId.isNotEmpty && !exits.any((d) => d.id == exitId))
              DropdownMenuItem(value: exitId, child: Text(l.tsMissingExit)),
            for (final d in exits)
              DropdownMenuItem(
                value: d.id,
                child: Text(
                  '${d.name} · ${d.online ? l.tsOnline : l.tsOffline}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: view.busy
              ? null
              : (id) => controller.preferences({'exitId': id ?? ''}),
        ),
        const SizedBox(height: 16),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'groups', label: Text(l.tsSelectedGroups)),
            ButtonSegment(value: 'all', label: Text(l.tsAllPublic)),
          ],
          selected: {p['exitScope'] as String? ?? 'groups'},
          onSelectionChanged: view.busy
              ? null
              : (v) => controller.preferences({'exitScope': v.first}),
        ),
        const SizedBox(height: 12),
        if (p['exitScope'] != 'all') ...[
          Text(
            l.tsGroupSemantics,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          if (s.groups.isEmpty) Text(l.tsNoGroups),
          for (final group in {...s.groups, ...bound})
            CheckboxListTile(
              title: Text(group),
              subtitle: s.groups.contains(group)
                  ? null
                  : Text(l.tsMissingGroup),
              value: bound.contains(group),
              onChanged:
                  view.busy ||
                      (!s.groups.contains(group) && !bound.contains(group))
                  ? null
                  : (v) {
                      final next = [...bound];
                      if (v == true) {
                        next.add(group);
                      } else {
                        next.remove(group);
                      }
                      controller.preferences({
                        'bindings': {...bindings, s.profileId: next},
                      });
                    },
            ),
        ],
        ListHeader(
          title: l.tsWhenUnavailable,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        RadioGroup<String>(
          groupValue: p['failurePolicy'] as String? ?? 'stop',
          onChanged: (v) {
            if (!view.busy) controller.preferences({'failurePolicy': v});
          },
          child: Column(
            children: [
              RadioListTile(value: 'stop', title: Text(l.tsStopConnections)),
              RadioListTile(
                value: 'fallback',
                title: Text(l.tsReturnOriginal),
                subtitle: Text(l.tsOriginalRouting),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final view = ref.watch(tailscaleProvider);
    final s = view.snapshot;
    final l = context.appLocalizations;
    return CommonScaffold(
      title: l.tailscale,
      body: LayoutBuilder(
        builder: (context, size) {
          if (view.loading)
            return const Center(child: CircularProgressIndicator());
          if (!s.supported && view.error == null)
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l.tsUnsupported),
              ),
            );
          final login = [
            'loggedOut',
            'needsLogin',
            'authorizing',
            'waitingApproval',
            'starting',
            'error',
            'backendDisconnected',
          ].contains(s.session);
          return DefaultTabController(
            length: 3,
            child: Column(
              children: [
                if (view.busy) const LinearProgressIndicator(),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: size.maxHeight * (login ? .68 : .42),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _status(view),
                        if (login && s.supported) _loginPanel(view),
                      ],
                    ),
                  ),
                ),
                TabBar(
                  isScrollable: size.maxWidth < 500,
                  tabs: [
                    Tab(text: l.tsDevices),
                    Tab(text: l.tsRouting),
                    Tab(text: l.tsExit),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _devices(view, size.maxWidth >= 1000),
                      _routing(view),
                      _exit(view),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
