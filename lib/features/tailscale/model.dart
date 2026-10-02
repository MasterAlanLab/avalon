import 'dart:convert';

Map<String, dynamic> tsMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
List<String> tsStrings(Object? value) => value is List
    ? value.whereType<String>().toList(growable: false)
    : const [];

class TailscaleDevice {
  final Map<String, dynamic> json;
  TailscaleDevice(Object? data) : json = Map.unmodifiable(tsMap(data));
  String get id => json['id'] as String? ?? '';
  String get name => json['name'] as String? ?? '';
  String get dnsName => json['dnsName'] as String? ?? '';
  String get os => json['os'] as String? ?? '';
  List<String> get ips => tsStrings(json['ips']);
  List<String> get tags => tsStrings(json['tags']);
  List<String> get routes => tsStrings(json['routes']);
  bool get online => json['online'] == true;
  bool get exit => json['exitNodeOption'] == true;
  String? get lastSeen => json['lastSeen'] as String?;
  String? get keyExpiry => json['keyExpiry'] as String?;
}

class TailscaleSnapshot {
  final Map<String, dynamic> json;
  TailscaleSnapshot(Object? data)
    : json = Map.unmodifiable(tsMap(jsonDecode(jsonEncode(data ?? {}))));
  bool get supported => json['supported'] == true;
  int get generation => json['generation'] as int? ?? 0;
  int get revision => json['revision'] as int? ?? 0;
  int get sequence => json['sequence'] as int? ?? 0;
  String get session => json['session'] as String? ?? 'loading';
  String get control => json['control'] as String? ?? 'unknown';
  String get authUrl => json['authUrl'] as String? ?? '';
  String? get error => json['error'] as String?;
  String get user => json['user'] as String? ?? '';
  String get profileId => json['profileId'] as String? ?? '';
  bool get cached => json['cached'] == true;
  String get split => json['split'] as String? ?? 'inactive';
  String get exitState => json['exitState'] as String? ?? 'off';
  TailscaleDevice? get self =>
      json['self'] == null ? null : TailscaleDevice(json['self']);
  List<TailscaleDevice> get devices =>
      (json['devices'] as List? ?? []).map(TailscaleDevice.new).toList();
  List<Map<String, dynamic>> get routes =>
      (json['routes'] as List? ?? []).map(tsMap).toList();
  List<String> get reasons => tsStrings(json['reasons']);
  List<String> get groups => tsStrings(json['groups']);
  List<String> get capturePrefixes => tsStrings(json['capturePrefixes']);
  Map<String, dynamic> get prefs => tsMap(json['prefs']);
  Map<String, dynamic> get probes => tsMap(json['probes']);
  bool isNewerThan(TailscaleSnapshot other) =>
      generation > other.generation ||
      (generation == other.generation &&
          revision >= other.revision &&
          sequence > other.sequence);
  TailscaleSnapshot disconnected() => TailscaleSnapshot({
    ...json,
    'session': 'backendDisconnected',
    'cached': true,
    'service': false,
    'split': 'inactive',
    'exitState': 'pending',
    'authUrl': '',
  });
}

class TailscaleViewState {
  final TailscaleSnapshot snapshot;
  final bool busy;
  final bool loading;
  final String? error;
  TailscaleViewState({
    TailscaleSnapshot? snapshot,
    this.busy = false,
    this.loading = true,
    this.error,
  }) : snapshot = snapshot ?? TailscaleSnapshot(null);
  TailscaleViewState copy({
    TailscaleSnapshot? snapshot,
    bool? busy,
    bool? loading,
    String? error,
  }) => TailscaleViewState(
    snapshot: snapshot ?? this.snapshot,
    busy: busy ?? this.busy,
    loading: loading ?? this.loading,
    error: error,
  );
}
