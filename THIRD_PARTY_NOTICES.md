# Third-party notices for Avalon

The app shows bundled licences under About → Licences and Notices: Flutter pub-package licences and the licence texts in `app/assets/licenses/` for Avalon (AGPL-3.0-only), zxing-cpp (Apache-2.0), zint (BSD-3-Clause), go-winio (MIT), and Wintun (official precompiled binary licence). Licensing and release responsibilities are maintained in [LICENSING](docs/LICENSING.md).

Avalon independently authored code is licensed under AGPL-3.0-only; see [LICENSE](LICENSE), [COPYRIGHT](COPYRIGHT) and [licensing policy](docs/LICENSING.md). This does not replace any third-party license. The original notices below are retained as design/audit evidence, not as a declaration of current bundled dependencies.

## sing-box — sole runtime engine

- Official upstream: https://github.com/SagerNet/sing-box
- Tag: v1.14.2
- Commit: `af6e64c3b69e6132ebaee0e1a3d24e93903f6709`
- License: GPL-3.0-or-later
- Copyright (C) 2022 by nekohasekai <contact-sagernet@sekai.icu>
- [Immutable upstream LICENSE](https://github.com/SagerNet/sing-box/blob/af6e64c3b69e6132ebaee0e1a3d24e93903f6709/LICENSE)
- [Unmodified license text](docs/licenses/sing-box-LICENSE.txt)
- Upstream also prohibits derivative use of its name or implication of association without prior consent; the original statement is retained verbatim in the audit copy.

Avalon Core Bridge links the pinned sing-box into generated host artifacts; build output is not committed. The integration contract is [RUNTIME_HOST](docs/RUNTIME_HOST.md); distribution obligations are in the licensing policy.

## mihomo — license evidence, not a runtime engine

- Official upstream: https://github.com/MetaCubeX/mihomo
- Branch: Meta
- Commit: `88dcbf7f1614a67c3b36b848ee3592dfa92ada36`
- License: GPL-3.0, not MIT
- [Immutable upstream LICENSE](https://github.com/MetaCubeX/mihomo/blob/88dcbf7f1614a67c3b36b848ee3592dfa92ada36/LICENSE)
- [Unmodified license text](docs/licenses/mihomo-LICENSE.txt)

Upstream authors retain their individual source-file copyright notices. Copyright (C) 2007 Free Software Foundation, Inc. in the license text identifies ownership of that text, not ownership of the mihomo implementation. No mihomo implementation is included; mihomo is not a runtime target.

## Release inventory

Dependency versions are locked in `pubspec.lock` and `core/go.mod` / `core/go.sum`. Before release, generate and review the inventory for the actual build tags and platform as required by [LICENSING](docs/LICENSING.md). The retained audit licence texts do not themselves introduce dependencies or relicense third-party work.
