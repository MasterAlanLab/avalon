package app.getavalon.avalon.host;

// The Core Bridge across the process boundary: the interface runs in the
// app's main process, the bridge in the `:vpn` process. Commands and
// answers are the bridge's JSON (docs/RUNTIME_HOST.md §2), unchanged.
interface IAvalonHost {
    String call(String command, String request);
}
