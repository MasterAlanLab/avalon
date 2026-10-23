#!/usr/bin/env python3
"""Run the maintained installer and real helper only in a disposable Linux container."""

import hashlib
import json
import os
from pathlib import Path
import shutil
import socket
import subprocess
import sys
import time
import urllib.request


ROOT = Path('/usr/lib/avalon')
HELPER = ROOT / 'avalon-helper'
INSTALLER = '/fixture/install_linux_helper.sh'
STAGE = Path('/root/avalon-stage')
SOURCE = STAGE / 'avalon-helper'
USER = Path('/home/avalon-test')


def drop_to(uid):
    def apply():
        os.setgroups([])
        os.setgid(uid)
        os.setuid(uid)
    return apply


def run(*args, success=True, uid=None, **kwargs):
    result = subprocess.run(
        args, text=True, capture_output=True, timeout=30,
        preexec_fn=drop_to(uid) if uid is not None else None, **kwargs,
    )
    if success:
        assert result.returncode == 0, f'{args[0]}: {result.stdout} {result.stderr}'
    else:
        assert result.returncode != 0, f'{args[0]} accepted an unsafe installation'
    return result


def install(source=SOURCE, success=True):
    return run(INSTALLER, 'install', str(source), success=success)


def copy_binary(target, uid=0, mode=0o755):
    shutil.copyfile('/fixture/avalon-helper', target)
    os.chown(target, uid, uid)
    os.chmod(target, mode)


def expect_rejected(source):
    install(source, success=False)
    assert not HELPER.exists(), 'a rejected installation left a privileged binary'


def capabilities(pid):
    fields = {}
    for line in Path(f'/proc/{pid}/status').read_text().splitlines():
        key, _, value = line.partition(':')
        fields[key] = value.strip()
    assert fields['Uid'].split() == ['1000'] * 4, fields['Uid']
    return int(fields['CapEff'], 16)


def call(path, command, request=None, uid=1000, success=True):
    result = run(
        sys.executable, __file__, 'client', str(path), uid=uid, success=success,
        input=json.dumps({'command': command, 'request': request or {}}),
    )
    if not success:
        assert not result.stdout.strip(), 'another user received a bridge response'
        return None
    response = json.loads(result.stdout)
    assert 'error' not in response, f'{command}: {response.get("error")}'
    return response.get('result', {})


def start_helper(binary, directory):
    directory.mkdir(mode=0o700)
    os.chown(directory, 1000, 1000)
    process = subprocess.Popen(
        [str(binary), '-state', str(directory / 'state'), '-socket', str(directory / 'run/host.sock')],
        preexec_fn=drop_to(1000), stdout=subprocess.DEVNULL, stderr=subprocess.PIPE,
        env={'PATH': '/usr/bin:/bin', 'HOME': str(USER)}, text=True,
    )
    path = directory / 'run/host.sock'
    for _ in range(150):
        if path.exists():
            return process, path
        if process.poll() is not None:
            raise AssertionError(f'helper failed to start: {process.stderr.read()}')
        time.sleep(0.02)
    process.terminate()
    process.wait(timeout=5)
    raise AssertionError('helper did not open its socket')


def stop_helper(process):
    process.terminate()
    process.wait(timeout=5)
    process.stderr.close()


def test_rejected_installations():
    STAGE.mkdir(mode=0o755)
    copy_binary(SOURCE)
    USER.mkdir(mode=0o700)
    os.chown(USER, 1000, 1000)
    mutable = USER / 'avalon-helper'
    copy_binary(mutable, uid=1000)
    expect_rejected(mutable)

    linked = STAGE / 'linked-helper'
    linked.symlink_to(SOURCE)
    expect_rejected(linked)

    writable = STAGE / 'writable-helper'
    copy_binary(writable, mode=0o775)
    expect_rejected(writable)

    unsafe = STAGE / 'unsafe'
    unsafe.mkdir(mode=0o755)
    copy_binary(unsafe / 'avalon-helper')
    os.chmod(unsafe, 0o777)
    expect_rejected(unsafe / 'avalon-helper')
    os.chmod(unsafe, 0o755)

    linked_directory = STAGE / 'linked-directory'
    linked_directory.symlink_to(unsafe)
    expect_rejected(linked_directory / 'avalon-helper')

    ROOT.symlink_to(STAGE)
    install(success=False)
    assert ROOT.is_symlink()
    assert run('getcap', str(SOURCE)).stdout == ''
    ROOT.unlink()
    ROOT.mkdir(mode=0o755)
    HELPER.symlink_to(SOURCE)
    install(success=False)
    assert HELPER.is_symlink()
    assert run('getcap', str(SOURCE)).stdout == ''
    HELPER.unlink()

    os.chmod(ROOT, 0o777)
    expect_rejected(SOURCE)
    os.chmod(ROOT, 0o755)
    copy_binary(HELPER, uid=1000)
    install(success=False)
    assert HELPER.stat().st_uid == 1000
    HELPER.unlink()
    run(INSTALLER, 'uninstall', uid=1000, success=False)
    print('PASS: user-owned, writable and symbolic-link sources/targets are refused', flush=True)


def test_installed_helper():
    install()
    stat = HELPER.stat()
    assert stat.st_uid == stat.st_gid == 0
    assert stat.st_mode & 0o7777 == 0o755
    assert run('getcap', str(HELPER)).stdout.strip() == f'{HELPER} cap_net_admin=ep'
    assert not list(ROOT.glob('.install.*'))
    initial = hashlib.sha256(HELPER.read_bytes()).digest()
    install()  # stopped upgrades are atomic and retain exactly the one capability.
    assert hashlib.sha256(HELPER.read_bytes()).digest() == initial

    keep = ROOT / 'keep-another-package-file'
    keep.write_text('keep this unrelated file')
    other = Path('/home/other-user')
    other.mkdir(mode=0o700)
    os.chown(other, 1001, 1001)
    sentinel = other / 'keep-config'
    sentinel.write_text('keep another user configuration')
    os.chown(sentinel, 1001, 1001)

    process, path = start_helper(HELPER, USER / 'installed')
    try:
        assert capabilities(process.pid) == (1 << 12), 'helper gained a capability beyond NET_ADMIN'
        assert call(path, 'capabilities')['tun'] is True
        assert path.stat().st_mode & 0o777 == 0o600
        assert path.parent.stat().st_mode & 0o777 == 0o700
        assert install(success=False).stderr.strip().endswith('stop Avalon and its helper first')
        run(INSTALLER, 'uninstall', success=False)
        assert HELPER.exists() and hashlib.sha256(HELPER.read_bytes()).digest() == initial
        assert HELPER.stat().st_mode & 0o7777 == 0o755, 'a refused operation did not restore execute permission'
        assert run('getcap', str(HELPER)).stdout.strip() == f'{HELPER} cap_net_admin=ep'

        # Even if the filesystem gate is opened, SO_PEERCRED still rejects UID 1001.
        os.chmod(USER, 0o711)
        os.chmod(path.parent.parent, 0o711)
        os.chmod(path.parent, 0o711)
        os.chmod(path, 0o666)
        try:
            call(path, 'capabilities', uid=1001, success=False)
        finally:
            os.chmod(path, 0o600)
            os.chmod(path.parent, 0o700)
            os.chmod(path.parent.parent, 0o700)
            os.chmod(USER, 0o700)
        assert call(path, 'capabilities')['tun'] is True

        plan = {
            'log': {'level': 'info'},
            'inbounds': [{
                'type': 'tun', 'tag': 'tun-in', 'interface_name': 'avinstall0',
                'address': ['172.31.255.1/30'], 'mtu': 1500,
                'auto_route': True, 'stack': 'gvisor',
            }],
            'outbounds': [{'type': 'direct', 'tag': 'direct'}],
            'route': {'final': 'direct', 'auto_detect_interface': True},
        }
        started = call(path, 'start', {'requestId': 'install-tun-start', 'plan': plan, 'planHash': 'installed'})
        assert Path('/sys/class/net/avinstall0').exists(), 'the normal-user helper did not create TUN'
        assert call(path, 'snapshot')['tunActive'] is True
        # The requesting Python process has no file capability; its request must
        # enter the helper through TUN rather than an explicitly selected proxy.
        run(sys.executable, __file__, 'http', os.environ['AVALON_TUN_TARGET'], uid=1000)
        logs = call(path, 'logs', {'afterSeq': 0, 'limit': 500})
        assert 'inbound/tun[tun-in]' in json.dumps(logs), 'the test request bypassed TUN'
        call(path, 'stop', {'requestId': 'install-tun-stop', 'sessionId': started['sessionId']})
        for _ in range(100):
            if not Path('/sys/class/net/avinstall0').exists():
                break
            time.sleep(0.02)
        assert not Path('/sys/class/net/avinstall0').exists(), 'TUN survived stop'
        print('PASS: UID 1000 has only NET_ADMIN; Unix IPC and real TUN forwarding/stop work', flush=True)
    finally:
        stop_helper(process)

    local_config = USER / 'installed/state/keep-local-config'
    local_config.write_text('keep local configuration')
    os.chown(local_config, 1000, 1000)
    run(INSTALLER, 'uninstall')
    assert not HELPER.exists()
    assert keep.read_text() == 'keep this unrelated file'
    assert sentinel.read_text() == 'keep another user configuration'
    assert sentinel.stat().st_uid == 1001
    assert local_config.read_text() == 'keep local configuration'
    assert local_config.stat().st_uid == 1000
    keep.unlink()
    run(INSTALLER, 'uninstall')
    assert not ROOT.exists(), 'an empty helper install directory survived uninstall'
    print('PASS: running helper prevents upgrade/uninstall; stopped uninstall preserves other files and users', flush=True)


def test_no_capability():
    binary = USER / 'unprivileged-helper'
    copy_binary(binary, uid=1000)
    assert run('getcap', str(binary)).stdout == ''
    process, path = start_helper(binary, USER / 'unprivileged')
    try:
        assert capabilities(process.pid) == 0
        assert call(path, 'capabilities')['tun'] is False
        print('PASS: an ordinary user-owned helper reports no TUN capability', flush=True)
    finally:
        stop_helper(process)


def client(path):
    try:
        with socket.socket(socket.AF_UNIX) as connection:
            connection.settimeout(10)
            connection.connect(path)
            connection.sendall(sys.stdin.read().encode() + b'\n')
            with connection.makefile('rb') as answer:
                response = answer.readline()
            if not response:
                return 1
            sys.stdout.write(response.decode())
        return 0
    except (OSError, TimeoutError):
        return 1


if __name__ == '__main__':
    if len(sys.argv) > 1 and sys.argv[1] == 'client':
        sys.exit(client(sys.argv[2]))
    if len(sys.argv) > 1 and sys.argv[1] == 'http':
        assert os.getuid() == 1000
        cap = Path('/proc/self/status').read_text().split('CapEff:')[1].splitlines()[0].strip()
        assert int(cap, 16) == 0
        with urllib.request.urlopen(sys.argv[2], timeout=10) as response:
            assert response.status == 200
        sys.exit(0)
    assert os.getuid() == 0 and sys.platform == 'linux', 'run only in the verification container'
    test_rejected_installations()
    test_installed_helper()
    test_no_capability()
