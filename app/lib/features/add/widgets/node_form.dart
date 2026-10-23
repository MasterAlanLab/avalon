import 'package:av_core/av_core.dart';
import 'package:av_design/av_design.dart';
import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../add_state.dart';

/// What each protocol runs on, shown in the protocol menu (PRODUCT_SPEC
/// §3.6). Technical names, not translated.
const _protocolNotes = {
  Protocol.hysteria2: 'QUIC',
  Protocol.tuic: 'QUIC v5',
  Protocol.vless: 'Reality / TLS',
  Protocol.vmess: 'TCP / WS',
  Protocol.trojan: 'TLS',
  Protocol.shadowsocks: 'AEAD / 2022',
  Protocol.socks5: 'SOCKS',
  Protocol.anytls: 'TLS',
  Protocol.http: 'HTTP / HTTPS',
};

const _monoFields = {
  NodeField.uuid,
  NodeField.password,
  NodeField.obfsPassword,
  NodeField.flow,
  NodeField.method,
  NodeField.wsPath,
  NodeField.wsHost,
  NodeField.grpcService,
  NodeField.h2Path,
  NodeField.sni,
  NodeField.publicKey,
  NodeField.shortId,
};

String nodeFieldLabel(AppLocalizations l, NodeField field) => switch (field) {
  NodeField.name => l.name,
  NodeField.server => l.fieldServer,
  NodeField.port => l.fieldPort,
  NodeField.uuid => 'UUID',
  NodeField.password => l.fieldPassword,
  NodeField.obfsPassword => l.fieldObfsPassword,
  NodeField.username => l.fieldUsername,
  NodeField.upMbps => l.fieldUpMbps,
  NodeField.downMbps => l.fieldDownMbps,
  NodeField.congestion => l.fieldCongestion,
  NodeField.flow => 'Flow',
  NodeField.alterId => 'Alter ID',
  NodeField.method => l.fieldMethod,
  NodeField.idleCheck => l.fieldIdleCheck,
  NodeField.wsPath || NodeField.h2Path => l.fieldPath,
  NodeField.wsHost => 'Host',
  NodeField.grpcService => 'Service',
  NodeField.sni => 'SNI',
  NodeField.publicKey => l.fieldPublicKey,
  NodeField.shortId => 'Short ID',
};

String nodeErrorText(AppLocalizations l, NodeDraftException e) {
  final field = nodeFieldLabel(l, e.field);
  return switch (e.error) {
    NodeDraftError.required => l.fieldRequired(field),
    NodeDraftError.invalid => l.fieldInvalid(field),
    NodeDraftError.unsupported => l.fieldUnsupported(field),
  };
}

/// V3 3e: share link box, protocol menu, server fields, then transport and
/// security with the fields they bring.
class NodeForm extends StatelessWidget {
  const NodeForm({
    super.key,
    required this.state,
    required this.linkController,
    required this.controllerOf,
    required this.onParseLink,
    required this.onProtocol,
    required this.onTransport,
    required this.onSecurity,
  });

  final AddState state;
  final TextEditingController linkController;
  final TextEditingController Function(NodeField field) controllerOf;
  final VoidCallback onParseLink;
  final ValueChanged<Protocol> onProtocol;
  final ValueChanged<TransportKind> onTransport;
  final ValueChanged<NodeSecurity> onSecurity;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.av;
    final desktop = AvDensity.isDesktop(context);
    final draft = state.node;
    final security = draft.effectiveSecurity;
    final extra = draft.extraFields;
    final failed = state.nodeError;
    final editing = state.editing != null;
    final inset = EdgeInsets.symmetric(horizontal: desktop ? 0 : 16);

    AvFieldRow field(NodeField f) => AvFieldRow(
      key: ValueKey(f),
      label: nodeFieldLabel(l, f),
      placeholder: f == NodeField.name
          ? l.nodeNameHint
          : state.savedSecrets.contains(f)
          ? l.savedSecretHint
          : draft.sample(f) ??
                (draft.isRequired(f)
                    ? l.fieldRequiredHint
                    : l.fieldOptionalHint),
      mono: _monoFields.contains(f),
      inputSize: desktop ? 14 : 17,
      controller: controllerOf(f),
    );

    Widget? errorFor(Iterable<NodeField> fields) =>
        failed != null && fields.contains(failed.field)
        ? AvFormNote(nodeErrorText(l, failed), color: c.bad)
        : null;

    // Desktop: a caption beside the control; phones: a section header above.
    Widget labeled(String label, Widget control, {double? top}) => desktop
        ? Row(
            children: [
              SizedBox(
                width: 84,
                child: Text(label, style: AvType.caption.copyWith(color: c.l2)),
              ),
              const SizedBox(width: 12),
              Expanded(child: control),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AvSectionHeader(label, top: top),
              Padding(padding: inset, child: control),
            ],
          );

    final linkBox = Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      decoration: BoxDecoration(
        color: c.cell,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          AvIcon(
            Symbols.content_paste_rounded,
            size: desktop ? 18 : 20,
            color: c.l2,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AvInput(
              controller: linkController,
              placeholder: desktop ? l.pasteLinkHintDesktop : l.pasteLinkHint,
              style: desktop ? AvType.s(14) : AvType.input,
              keyboardType: TextInputType.url,
            ),
          ),
          const SizedBox(width: 10),
          if (desktop)
            AvDesktopButton(
              label: l.parse,
              tinted: true,
              height: 28,
              radius: 7,
              onTap: onParseLink,
            )
          else
            AvPillButton(
              label: l.parse,
              tinted: true,
              height: 32,
              pressScale: 0.92,
              onTap: onParseLink,
            ),
        ],
      ),
    );

    final menuItems = [
      for (final p in Protocol.values)
        AvMenuItem(p, p.label, subtitle: _protocolNotes[p]),
    ];
    final protocolMenu = desktop
        ? labeled(
            l.protocol,
            Align(
              alignment: Alignment.centerLeft,
              child: AvPullDownMenu<Protocol>(
                items: menuItems,
                selected: draft.protocol,
                width: 280,
                alignRight: false,
                itemHeight: 32,
                labelSize: 13,
                onSelected: onProtocol,
                builder: (context, toggle) => AvPressable(
                  onTap: toggle,
                  pressedOpacity: 0.7,
                  child: Container(
                    height: 28,
                    constraints: const BoxConstraints(minWidth: 200),
                    padding: const EdgeInsets.fromLTRB(12, 0, 6, 0),
                    decoration: BoxDecoration(
                      color: c.cell,
                      borderRadius: BorderRadius.circular(7),
                      boxShadow: [
                        BoxShadow(color: c.sep, spreadRadius: 0.5),
                        const BoxShadow(
                          color: Color(0x14000000),
                          offset: Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          draft.protocol.label,
                          style: AvType.footnoteStrong.copyWith(color: c.l1),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _protocolNotes[draft.protocol]!,
                          style: AvType.caption.copyWith(color: c.l2),
                        ),
                        const SizedBox(width: 6),
                        AvIcon(
                          Symbols.unfold_more_rounded,
                          size: 16,
                          color: c.l2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
        : Padding(
            padding: inset,
            child: AvPullDownMenu<Protocol>(
              items: menuItems,
              selected: draft.protocol,
              onSelected: onProtocol,
              builder: (context, toggle) => ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ColoredBox(
                  color: c.cell,
                  child: AvPressable(
                    highlight: true,
                    onTap: toggle,
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 44),
                      padding: const EdgeInsets.fromLTRB(16, 0, 10, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              l.protocol,
                              style: AvType.body.copyWith(color: c.l1),
                            ),
                          ),
                          Text(
                            draft.protocol.label,
                            style: AvType.body.copyWith(color: c.l2),
                          ),
                          const SizedBox(width: 6),
                          AvIcon(
                            Symbols.unfold_more_rounded,
                            size: 20,
                            color: c.l2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );

    final serverFields = [NodeField.name, ...draft.serverFields];
    final linkError = state.linkError;
    final saveError = state.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Editing starts from the saved node, not from a link.
        if (!editing) ...[
          Padding(padding: inset, child: linkBox),
          if (linkError != null) AvFormNote(linkError.message(l), color: c.bad),
          SizedBox(height: desktop ? 16 : 24),
        ],
        protocolMenu,
        if (desktop)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 18, 4, 6),
            child: Text(
              l.sectionServer,
              style: AvType.caption.copyWith(color: c.l2),
            ),
          )
        else
          AvSectionHeader(l.sectionServer),
        AvGroup(children: [for (final f in serverFields) field(f)]),
        ?errorFor(serverFields),
        if (draft.hasTransport) ...[
          if (desktop) const SizedBox(height: 14),
          labeled(
            l.sectionTransport,
            AvSegmented<TransportKind>(
              values: TransportKind.values,
              labelOf: (t) => switch (t) {
                TransportKind.tcp => 'TCP',
                TransportKind.ws => 'WebSocket',
                TransportKind.grpc => 'gRPC',
                TransportKind.http2 => 'HTTP/2',
              },
              selected: draft.transport,
              height: desktop ? 32 : null,
              onChanged: onTransport,
            ),
          ),
        ],
        if (security != null) ...[
          if (desktop) const SizedBox(height: 10),
          labeled(
            l.sectionSecurity,
            AvSegmented<NodeSecurity>(
              values: draft.securityOptions,
              labelOf: (s) => switch (s) {
                NodeSecurity.none => l.securityNone,
                NodeSecurity.tls => 'TLS',
                NodeSecurity.reality => 'Reality',
              },
              selected: security,
              height: desktop ? 32 : null,
              onChanged: onSecurity,
            ),
            top: 20,
          ),
        ],
        if (extra.isNotEmpty)
          AvDropIn(
            key: ValueKey(
              'extra-${draft.protocol.name}-${draft.transport.name}-$security',
            ),
            child: Padding(
              padding: EdgeInsets.only(top: desktop ? 14 : 20),
              child: AvGroup(children: [for (final f in extra) field(f)]),
            ),
          ),
        ?errorFor(extra),
        if (saveError != null) AvFormNote(saveError.message(l), color: c.bad),
        if (!desktop) const SizedBox(height: 16),
        AvFormNote(
          editing ? l.localOnlyNote : '${l.nodeSavedNote}${l.localOnlyNote}',
        ),
      ],
    );
  }
}
