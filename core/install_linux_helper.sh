#!/bin/sh
# Install only the Linux core helper; the application stays unprivileged.
# A package manager/root must first stage its trusted binary in a root-owned,
# non-writable directory, then run:
#   install_linux_helper.sh install /usr/local/lib/avalon-stage/avalon-helper
#   install_linux_helper.sh uninstall
# libcap tools are required. Stop Avalon and its helper before either action.
set -eu
PATH=/usr/sbin:/usr/bin:/sbin:/bin
export PATH
LC_ALL=C
export LC_ALL
umask 077

helper_dir=/usr/lib/avalon
helper=$helper_dir/avalon-helper
temporary=
staging=
guarded_inode=
guarded_mode=

fail() {
  printf 'avalon-helper installation: %s\n' "$1" >&2
  exit 1
}

cleanup() {
  if [ -n "$temporary" ]; then rm -f -- "$temporary"; fi
  if [ -n "$staging" ]; then rmdir -- "$staging" 2>/dev/null || true; fi
  if [ -n "$guarded_inode" ] && [ -f "$helper" ] && [ ! -L "$helper" ]; then
    current_inode=$(stat -c '%d:%i' -- "$helper")
    if [ "$current_inode" = "$guarded_inode" ]; then
      chmod "$guarded_mode" -- "$helper"
    fi
  fi
  command exec 8>&-
}
trap cleanup EXIT
trap 'cleanup; exit 1' HUP INT TERM

[ "$(uname -s)" = Linux ] || fail 'Linux is required'
[ "$(id -u)" = 0 ] || fail 'root is required; never grant capabilities to the application'

# Do not canonicalize through links: every component must already be trusted.
check_path_syntax() {
  case "$1" in
    /*) ;;
    *) fail 'the staged helper path must be absolute' ;;
  esac
  case "$1/" in
    *'//'*|*'/./'*|*'/../'*) fail 'the helper path must not contain empty, dot or parent components' ;;
  esac
}

check_directory_tree() {
  checked=$1
  while :; do
    [ ! -L "$checked" ] || fail 'a helper directory is a symbolic link'
    [ -d "$checked" ] || fail 'a helper directory is missing or is not a directory'
    [ "$(stat -c '%u:%g' -- "$checked")" = 0:0 ] || fail 'helper directories must be root:root'
    permissions=$(stat -c '%a' -- "$checked")
    [ "$((0$permissions & 0022))" = 0 ] || fail 'a helper directory is writable by a group or another user'
    [ "$checked" != / ] || break
    checked=$(dirname -- "$checked")
  done
}

check_binary() {
  [ ! -L "$1" ] || fail 'the helper binary is a symbolic link'
  [ -f "$1" ] && [ -x "$1" ] || fail 'the helper binary must be a regular executable file'
  [ "$(stat -c '%u:%g' -- "$1")" = 0:0 ] || fail 'the helper binary must be root:root'
  permissions=$(stat -c '%a' -- "$1")
  [ "$((0$permissions & 06022))" = 0 ] || fail 'the helper binary is writable by another user or has set-ID permissions'
  magic=$(od -An -tx1 -N4 -- "$1" | tr -d ' \n')
  [ "$magic" = 7f454c46 ] || fail 'the helper binary must be a Linux ELF executable'
}

check_stopped() {
  [ -d /proc ] || fail '/proc is required to check whether the helper has stopped'
  for entry in /proc/[0-9]*/exe; do
    [ -L "$entry" ] || continue
    if executable=$(readlink -- "$entry" 2>/dev/null); then
      case "$executable" in
        "$helper"|"$helper (deleted)") fail 'the installed helper is running; stop Avalon and its helper first' ;;
      esac
    else
      # Capability-bearing processes may hide their executable in restricted
      # root environments. Do not skip a possibly running installed helper.
      process_dir=$(dirname -- "$entry")
      if [ -r "$process_dir/comm" ] && [ "$(cat "$process_dir/comm")" = avalon-helper ]; then
        fail 'cannot verify a running helper; stop it or use an unrestricted root installer'
      fi
    fi
  done
  if [ -n "$guarded_inode" ]; then
    # Linux refuses a write-open (without truncation) of an executing ELF,
    # including an exec already in flight. Holding this descriptor also stops
    # an old inode being executed between the check and rename/unlink.
    if { command exec 8<>"$helper"; } 2>/dev/null; then
      :
    else
      fail 'the installed helper is executing; stop Avalon and its helper first'
    fi
  fi
}

# Stop new ordinary-user execs before inspecting processes. A failed/refused
# operation restores permissions only on the original inode in cleanup.
hold_installed_binary() {
  if [ -e "$helper" ] || [ -L "$helper" ]; then
    check_binary "$helper"
    guarded_inode=$(stat -c '%d:%i' -- "$helper")
    guarded_mode=$(stat -c '%a' -- "$helper")
    chmod 0600 -- "$helper"
  fi
}

case "${1:-}" in
  install)
    [ "$#" = 2 ] || fail 'usage: install_linux_helper.sh install /absolute/root-staged/avalon-helper'
    command -v setcap >/dev/null || fail 'setcap is missing; install the libcap utilities'
    command -v getcap >/dev/null || fail 'getcap is missing; install the libcap utilities'
    source_helper=$2
    check_path_syntax "$source_helper"
    check_directory_tree "$(dirname -- "$source_helper")"
    check_binary "$source_helper"
    check_directory_tree /usr/lib
    if [ -e "$helper_dir" ] || [ -L "$helper_dir" ]; then
      check_directory_tree "$helper_dir"
    else
      install -d -o 0 -g 0 -m 0755 -- "$helper_dir"
    fi
    hold_installed_binary
    check_stopped
    # Do not expose an executable capability-bearing staging file, even under
    # an unpredictable name. The directory stays root-only until the rename.
    staging=$(mktemp -d "$helper_dir/.install.XXXXXXXX")
    temporary=$staging/avalon-helper
    install -o 0 -g 0 -m 0755 -- "$source_helper" "$temporary"
    setcap cap_net_admin=ep "$temporary" || fail 'cannot grant CAP_NET_ADMIN on this filesystem'
    capabilities=$(getcap -- "$temporary")
    [ "$capabilities" = "$temporary cap_net_admin=ep" ] || fail 'the installed helper capability could not be verified'
    # A rename in this root-owned directory keeps the verified capability and
    # never exposes a writable privileged binary, even during an upgrade.
    mv -f -- "$temporary" "$helper"
    temporary=
    guarded_inode=
    printf 'Installed %s (root:root 0755, cap_net_admin=ep).\n' "$helper"
    ;;
  uninstall)
    [ "$#" = 1 ] || fail 'usage: install_linux_helper.sh uninstall'
    check_directory_tree /usr/lib
    if [ -e "$helper_dir" ] || [ -L "$helper_dir" ]; then
      check_directory_tree "$helper_dir"
    fi
    hold_installed_binary
    check_stopped
    if [ -e "$helper" ] || [ -L "$helper" ]; then
      rm -f -- "$helper"
    fi
    guarded_inode=
    # Leave unrelated files and all per-user configuration/state in place.
    if [ -d "$helper_dir" ]; then rmdir -- "$helper_dir" 2>/dev/null || true; fi
    printf 'Removed %s; user configuration and other files were preserved.\n' "$helper"
    ;;
  *) fail 'usage: install_linux_helper.sh install /absolute/root-staged/avalon-helper | uninstall' ;;
esac
