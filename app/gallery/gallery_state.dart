// DEVELOPMENT ONLY. Demo data copied from the V3 prototype so screens can be
// compared against the design. Never used by the production app.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

class DemoNode {
  const DemoNode(
    this.name,
    this.proto, {
    this.chain = false,
    this.groups = const [],
  });
  final String name;
  final String proto;
  final bool chain;
  final List<String> groups;
}

class DemoGroup {
  const DemoGroup(this.name, this.type, this.members);
  final String name;
  final String type;
  final List<int> members;
}

class DemoProfile {
  DemoProfile(
    this.id,
    this.name,
    this.src,
    this.nodes,
    this.updated, {
    this.used,
    this.total,
    this.expire,
    this.local = false,
  });
  final String id;
  final String name;
  final String src;
  final int nodes;
  String updated;
  final double? used;
  final double? total;
  final String? expire;
  final bool local;
}

class DemoConn {
  const DemoConn(
    this.host,
    this.app,
    this.rule,
    this.chain,
    this.up,
    this.down,
  );
  final String host, app, rule, chain, up, down;
}

const demoNodes = [
  DemoNode('香港 01', 'Hysteria2'),
  DemoNode('香港 02', 'VLESS Reality'),
  DemoNode('日本 东京', 'Trojan'),
  DemoNode('日本 大阪', 'TUIC v5'),
  DemoNode('新加坡 01', 'Shadowsocks'),
  DemoNode('台湾 01', 'VMess'),
  DemoNode('美国 洛杉矶', 'Hysteria2'),
  DemoNode('英国 伦敦', 'VLESS Reality'),
];

const demoGroups = [
  DemoGroup('节点选择', 'Selector', [0, 1, 2, 3, 4, 5, 6, 7]),
  DemoGroup('自动选择', 'URLTest', [0, 1, 2, 4]),
  DemoGroup('流媒体', 'Selector', [0, 2, 5, 6]),
  DemoGroup('AI 服务', 'Selector', [2, 4, 6, 7]),
  DemoGroup('漏网之鱼', 'Fallback', [0, 1, 2]),
];

const demoConns = [
  DemoConn(
    'api.openai.com:443',
    'ChatGPT',
    'GEOSITE,openai',
    'AI 服务 → 美国 洛杉矶',
    '12.4 KB',
    '318 KB',
  ),
  DemoConn(
    'rr3---sn.googlevideo.com:443',
    'YouTube',
    'GEOSITE,youtube',
    '流媒体 → 日本 东京',
    '48 KB',
    '92.6 MB',
  ),
  DemoConn(
    'github.com:443',
    'Safari',
    'DOMAIN-SUFFIX,github.com',
    '节点选择 → 香港 01',
    '6.1 KB',
    '1.2 MB',
  ),
  DemoConn(
    '149.154.167.51:443',
    'Telegram',
    'IP-CIDR,149.154.160.0/20',
    '节点选择 → 香港 01',
    '22 KB',
    '640 KB',
  ),
  DemoConn(
    'www.baidu.com:443',
    'Safari',
    'GEOSITE,cn',
    'DIRECT',
    '3.2 KB',
    '88 KB',
  ),
  DemoConn(
    'api.x.com:443',
    'X',
    'GEOSITE,twitter',
    '节点选择 → 香港 01',
    '9.8 KB',
    '2.4 MB',
  ),
  DemoConn(
    'open.spotify.com:443',
    'Spotify',
    'GEOSITE,spotify',
    '流媒体 → 日本 东京',
    '4 KB',
    '14.8 MB',
  ),
  DemoConn(
    'dns.google:853',
    'sing-box',
    'DNS',
    'dns-remote',
    '1.1 KB',
    '2.0 KB',
  ),
];

const demoLogs = [
  ['21:04:12', 'INFO', 'sing-box started (1.12.4)'],
  ['21:04:12', 'INFO', 'inbound/tun[tun-in]: started at utun4'],
  ['21:04:13', 'DEBUG', 'dns: exchanged github.com A 140.82.112.4'],
  [
    '21:04:13',
    'INFO',
    'outbound/hysteria2[香港 01]: connection to github.com:443',
  ],
  ['21:04:15', 'WARN', 'outbound/vmess[台湾 01]: dial timeout after 5s'],
  ['21:04:18', 'INFO', 'router: match GEOSITE,openai => AI 服务'],
  [
    '21:04:20',
    'ERROR',
    'outbound/vmess[台湾 01]: health check failed: i/o timeout',
  ],
  ['21:04:22', 'DEBUG', 'router: match GEOSITE,cn => DIRECT'],
  ['21:04:31', 'INFO', 'profile: Nebula Cloud updated, 24 nodes'],
  ['21:04:32', 'INFO', 'cloud: synced 3 profiles, 2 rule sets'],
  ['21:04:40', 'WARN', 'dns: fakeip pool 80% used'],
];

/// Mutable demo state mirroring the V3 prototype component.
class GalleryState extends ChangeNotifier {
  /// [live] runs the one-second clock (timer, speeds); golden tests turn it
  /// off and seed [random] so every frame is reproducible.
  GalleryState({this.live = true, math.Random? random})
    : _rnd = random ?? math.Random() {
    final r = math.Random(7);
    // Same shape as the V3 capture: a bounded random walk.
    var d = 2400.0;
    hist = List.generate(
      30,
      (_) => d = (d + (r.nextDouble() - .5) * 1600).clamp(1800, 4200),
    );
    up = 20 + r.nextDouble() * 160;
    if (live) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    }
  }

  final bool live;
  Timer? _timer;
  final math.Random _rnd;

  bool dark = false;
  bool connected = true;
  int seconds = 4521;
  String mode = '规则';
  late List<double> hist;
  late double up;
  double totU = 182.4, totD = 2316.8;

  final toggles = <String, bool>{
    'tun': true,
    'sys': false,
    'lan': false,
    'ipv6': false,
    'fakeip': true,
    'autostart': true,
    'tray': true,
    'autoConnect': false,
    'silentStart': false,
    'speedNotif': true,
    'strictRoute': true,
    'autoRoute': true,
    'sniff': true,
    'sniffOverride': false,
    'bypassLan': true,
    'findProc': true,
    'clashApi': true,
    'addAuto': true,
    'geoAuto': true,
  };
  String stack = 'Mixed',
      dnsStrat = '优先 IPv4',
      coreLog = 'info',
      logLevel = '全部';

  int group = 0;
  final sel = <int>[0, 8, 0, 2, 6, 0];
  bool testing = false;
  final lat = <String, int>{
    '香港 01': 42,
    '香港 02': 58,
    '日本 东京': 86,
    '日本 大阪': 104,
    '新加坡 01': 73,
    '台湾 01': 0,
    '美国 洛杉矶': 168,
    '英国 伦敦': 312,
    '东京 VPS': 64,
    '家宽中转': 23,
    '香港 01 → 东京 VPS': 118,
  };
  final custom = <DemoNode>[
    const DemoNode('东京 VPS', 'VLESS Reality', groups: ['节点选择']),
    const DemoNode('家宽中转', 'Shadowsocks'),
    const DemoNode(
      '香港 01 → 东京 VPS',
      '代理链 · 2 跳',
      chain: true,
      groups: ['节点选择', 'AI 服务'],
    ),
  ];

  String active = 'p1';
  final profiles = [
    DemoProfile(
      'p1',
      'Nebula Cloud',
      '订阅',
      24,
      '2 小时前',
      used: 128.4,
      total: 500,
      expire: '2026-12-31',
    ),
    DemoProfile('p2', '自建节点', '本地', 3, '3 天前', local: true),
    DemoProfile(
      'p3',
      '备用机场',
      '订阅',
      12,
      '昨天',
      used: 86.1,
      total: 100,
      expire: '2026-10-20',
    ),
  ];

  List<DemoConn> conns = List.of(demoConns);

  // 3k 分应用
  String appMode = '白名单';
  final apps = <String, bool>{
    'Telegram': true,
    'Safari': true,
    'YouTube': true,
    'X': true,
    'ChatGPT': true,
    'GitHub': true,
    'Spotify': true,
    'Google Chrome': true,
    'Visual Studio Code': true,
    'chrome.exe': true,
    'Telegram.exe': true,
    'Code.exe': true,
    'firefox': true,
    'telegram-desktop': true,
    'code': true,
  };

  // 3t GEO
  final geo = <DemoRuleSet>[
    DemoRuleSet('geosite-cn', 'GeoSite', '1.2 MB', '2 天前'),
    DemoRuleSet('geosite-geolocation-!cn', 'GeoSite', '864 KB', '2 天前'),
    DemoRuleSet('geoip-cn', 'GeoIP', '186 KB', '2 天前'),
    DemoRuleSet('geosite-openai', 'GeoSite', '2 KB', '5 天前'),
    DemoRuleSet('geosite-youtube', 'GeoSite', '6 KB', '5 天前'),
    DemoRuleSet('geoip-telegram', 'GeoIP', '3 KB', '5 天前'),
  ];
  final geoBusy = <String>{};
  String geoInt = '每天', geoVia = '经代理';

  void updateGeo(Iterable<String> names) {
    set(() => geoBusy.addAll(names));
    for (final n in names.toList()) {
      Timer(Duration(milliseconds: 900 + _rnd.nextInt(900)), () {
        set(() {
          geoBusy.remove(n);
          for (final g in geo) {
            if (g.name == n) g.when = '刚刚';
          }
        });
      });
    }
  }

  // 3s Tailscale
  bool tsOn = true, tsRoutes = true, tsDns = true, tsAdvertise = false;
  String? tsExit;

  // 3l/3m Cloud: 'paid' | 'free' | 'loggedOut'
  String account = 'paid';
  String lastSync = '2 分钟前';
  bool syncing = false;
  String plan = 'year';
  final devices = <DemoDevice>[
    const DemoDevice('iPhone 16 Pro', 'iOS 18', '此设备', 'smartphone', me: true),
    const DemoDevice('MacBook Pro', 'macOS 15', '5 分钟前', 'laptop_mac'),
    const DemoDevice('工作站', 'Windows 11', '昨天', 'desktop_windows'),
    const DemoDevice('Pixel 8', 'Android 15', '3 天前', 'phone_android'),
  ];

  void syncNow() {
    if (syncing) return;
    set(() => syncing = true);
    Timer(
      const Duration(milliseconds: 1400),
      () => set(() {
        syncing = false;
        lastSync = '刚刚';
      }),
    );
  }

  // Add-node form
  String nodeProto = 'VLESS';
  String transport = 'TCP';
  String security = 'Reality';

  // Add-chain form
  final hops = <String>['家宽中转', '香港 01', '东京 VPS'];
  bool picker = false;
  final chainGroups = <String>{'节点选择'};

  void _tick() {
    if (!connected) return;
    final last = hist.last;
    final d = (last + (_rnd.nextDouble() - .5) * 1600)
        .clamp(80, 6000)
        .toDouble();
    up = (up + (_rnd.nextDouble() - .5) * 100).clamp(8, 400).toDouble();
    hist = [...hist.skip(1), d];
    seconds++;
    totU += up / 1024;
    totD += d / 1024;
    notifyListeners();
  }

  void set(VoidCallback f) {
    f();
    notifyListeners();
  }

  List<DemoNode> get allNodes => [...demoNodes, ...custom];

  List<DemoGroup> get groups {
    final n = demoNodes.length;
    final gs = [
      for (final g in demoGroups)
        DemoGroup(g.name, g.type, [
          ...g.members,
          for (var j = 0; j < custom.length; j++)
            if (custom[j].groups.contains(g.name)) n + j,
        ]),
    ];
    gs.insert(
      1,
      DemoGroup('自定义', 'Selector', [
        for (var j = 0; j < custom.length; j++) n + j,
      ]),
    );
    return gs;
  }

  void testAll() {
    if (testing) return;
    set(() => testing = true);
    Timer(const Duration(milliseconds: 1200), () {
      final g = groups[group];
      for (final i in g.members) {
        final name = allNodes[i].name;
        lat[name] = name == '台湾 01' ? 0 : 30 + _rnd.nextInt(330);
      }
      set(() => testing = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class DemoRuleSet {
  DemoRuleSet(this.name, this.type, this.size, this.when);
  final String name, type, size;
  String when;
}

class DemoDevice {
  const DemoDevice(this.name, this.os, this.last, this.icon, {this.me = false});
  final String name, os, last, icon;
  final bool me;
}

class DemoTailnetPeer {
  const DemoTailnetPeer(
    this.name,
    this.ip,
    this.os, {
    this.exit = false,
    this.online = true,
  });
  final String name, ip, os;
  final bool exit, online;
}

const demoApps = [
  ('Telegram', 'org.telegram.messenger', 0xFF2AABEE),
  ('Safari', 'com.apple.mobilesafari', 0xFF007AFF),
  ('YouTube', 'com.google.ios.youtube', 0xFFFF3B30),
  ('X', 'com.atebits.Tweetie2', 0xFF1C1C1E),
  ('ChatGPT', 'com.openai.chat', 0xFF10A37F),
  ('GitHub', 'com.github.stormbreaker.prod', 0xFF24292F),
  ('Spotify', 'com.spotify.client', 0xFF1DB954),
  ('微信', 'com.tencent.xin', 0xFF07C160),
  ('支付宝', 'com.alipay.iphoneclient', 0xFF1677FF),
  ('哔哩哔哩', 'tv.danmaku.bilianime', 0xFFFB7299),
];

const demoPeers = [
  DemoTailnetPeer('home-nas', '100.101.12.4', 'Linux', exit: true),
  DemoTailnetPeer('macbook-pro', '100.88.3.21', 'macOS'),
  DemoTailnetPeer(
    'office-pc',
    '100.72.40.9',
    'Windows',
    exit: true,
    online: false,
  ),
  DemoTailnetPeer('tokyo-vps', '100.64.8.17', 'Linux', exit: true),
  DemoTailnetPeer('pixel-8', '100.110.2.33', 'Android'),
];

class GalleryScope extends InheritedNotifier<GalleryState> {
  const GalleryScope({
    super.key,
    required GalleryState state,
    required super.child,
  }) : super(notifier: state);

  static GalleryState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GalleryScope>()!.notifier!;
}

String fmtSpeed(double kb) => kb >= 1024
    ? '${(kb / 1024).toStringAsFixed(1)} MB/s'
    : '${kb.round()} KB/s';
String fmtBytes(double mb) => mb >= 1024
    ? '${(mb / 1024).toStringAsFixed(2)} GB'
    : '${mb.toStringAsFixed(1)} MB';
String two(int n) => n.toString().padLeft(2, '0');
