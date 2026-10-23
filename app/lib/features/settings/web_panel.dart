import '../../runtime/host_protocol.dart';

/// Why the advanced settings action could not open the panel.
enum WebPanelProblem {
  unavailable,
  notRunning,
  disabled,
  unknown,
  browserFailed,
}

/// Uses the host's accepted plan, including when a rejected reload left
/// the previous controller running. Never includes the controller secret.
({Uri? url, WebPanelProblem? problem}) webPanelTarget(HostSnapshot snapshot) {
  if (snapshot.state != HostState.running) {
    return (url: null, problem: WebPanelProblem.notRunning);
  }
  final listen = snapshot.clashApiListen;
  if (listen == null) return (url: null, problem: WebPanelProblem.unknown);
  if (listen.isEmpty) return (url: null, problem: WebPanelProblem.disabled);

  // A wildcard is a bind address. Browsers reach that listener through
  // loopback. Construct the URI from host and port so IPv6 stays bracketed.
  final separator = listen.lastIndexOf(':');
  if (separator <= 0) return (url: null, problem: WebPanelProblem.unknown);
  var host = listen.substring(0, separator);
  final port = int.tryParse(listen.substring(separator + 1));
  if (host.startsWith('[') && host.endsWith(']')) {
    host = host.substring(1, host.length - 1);
  }
  if (host.isEmpty || port == null || port < 1 || port > 65535) {
    return (url: null, problem: WebPanelProblem.unknown);
  }
  host = switch (host) {
    '0.0.0.0' => '127.0.0.1',
    '::' => '::1',
    _ => host,
  };
  try {
    return (
      url: Uri(scheme: 'http', host: host, port: port, path: '/ui'),
      problem: null,
    );
  } on FormatException {
    return (url: null, problem: WebPanelProblem.unknown);
  }
}
