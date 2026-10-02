# rust_api

Avalon's Rust-backed desktop IPC server. Dart bindings use **flutter_rust_bridge 2.12.0**; Cargo builds `cdylib` and `staticlib` libraries through the bundled [cargokit](cargokit/README) integration.

## API and transport

The public entry point is [lib/rust_api.dart](lib/rust_api.dart). Initialize `RustLib` before calling the API:

- `restartIpcServer(name: ...)` stops the previous server and returns a stream of IPC events.
- `sendIpcMessage(data: ...)` queues a message for the connected Go core.
- `stopIpcServer()` stops and joins the server thread; stop it before disposing the bridge.

Unix hosts use local sockets; Windows uses named pipes. Wire messages carry a four-byte little-endian length followed by a payload, with a 64 MiB frame limit. Dart stream events have a one-byte event type followed by the event payload: ready, connected, disconnected, data, or error. The writer queue is bounded by message count and bytes, with timeout/error reporting rather than silent message loss.

Implementation: [rust/src/api/ipc.rs](rust/src/api/ipc.rs). Avalon uses this transport on desktop; Android's core bridge is JNI/FFI. Plugin metadata also registers an iOS FFI target, but Avalon has no iOS application target.

## Build and test

Flutter platform builds invoke cargokit automatically. This package registers macOS, Linux, Windows, and iOS native builds; Android is not registered here.

From the repository root:

```bash
cargo fmt --manifest-path plugins/rust_api/rust/Cargo.toml -- --check
cargo test --manifest-path plugins/rust_api/rust/Cargo.toml
```

The tests cover framing, partial reads/writes, queue pressure, disconnects, and lifecycle behavior. Windows-specific behavior also requires Windows execution. Application/core build commands are maintained in [development.md](../../docs/development.md).

## Generate bindings

After changing the public Rust API, run from this plugin directory:

```bash
cargo install flutter_rust_bridge_codegen --version 2.12.0 --locked
flutter_rust_bridge_codegen generate
```

[flutter_rust_bridge.yaml](flutter_rust_bridge.yaml) reads `crate::api` from `rust/` and writes Dart bindings to `lib/src/rust/`. Register new API modules in [rust/src/api/mod.rs](rust/src/api/mod.rs), then export the generated module from `lib/rust_api.dart` when needed. Regenerate `rust/src/frb_generated.rs` and Dart bindings together instead of editing them manually; keep the Cargo, Dart runtime, and generator versions aligned.

Copyright and licensing follow the repository [NOTICE](../../NOTICE); cargokit retains its own [license](cargokit/LICENSE).
