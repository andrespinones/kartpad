#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
upstream="${repo_root}/ref/upstream/Wiicompiled"

test -d "${upstream}/runtime"
rg -l \
  'windows\.h|_WIN32|WIN32|WinSock|WSA[A-Z]|VirtualAlloc|HANDLE|DWORD|WinUsb|GetModuleFileName|shell32|windowsapp|dbghelp|user32|winmm|ws2_32|iphlpapi|secur32|crypt32|setupapi|winusb|x86-64-v3' \
  "${upstream}/runtime" "${upstream}/aurora-main" \
  -g '*.{c,cc,cpp,cxx,h,hpp,cmake,txt}' \
  | sed "s#${upstream}/##" \
  | LC_ALL=C sort
