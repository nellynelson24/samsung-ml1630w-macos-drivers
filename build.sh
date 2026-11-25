#!/bin/bash
# Rebuilds filter/ and ppd/ on an Apple Silicon Mac from the sources in source/.
# Needs only Xcode Command Line Tools (xcode-select --install).
#
# source/splix-macos-941fe7b-src.tar.gz  SpliX macOS port, commit 941fe7b of
#                                         https://github.com/photovirus/splix-macos
# source/jbigkit-2.1.tar.gz               JBIG-KIT 2.1 by Markus Kuhn,
#                                         https://www.cl.cam.ac.uk/~mgk25/jbigkit/
set -euo pipefail
cd "$(dirname "$0")"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# The ML-1630 needs JBIG compression (SpliX links -ljbig85). Building only
# the static libraries links jbigkit into the filters, so nothing extra is
# needed at runtime.
tar xzf source/jbigkit-2.1.tar.gz -C "$WORK"
make -C "$WORK/jbigkit-2.1/libjbig" libjbig.a libjbig85.a CC=clang
JBIG="$WORK/jbigkit-2.1/libjbig"

# The SpliX makefile adds -L$(brew --prefix)/lib on its own. Putting our
# -I/-L into CXX makes the bundled jbigkit win over any Homebrew copy.
tar xzf source/splix-macos-941fe7b-src.tar.gz -C "$WORK"
make -C "$WORK/splix-macos-941fe7b" \
  CXX="clang++ -I$JBIG -L$JBIG -Wno-unused-command-line-argument"

mkdir -p filter ppd
for f in rastertoqpdl pstoqpdl; do
  install -m 755 "$WORK/splix-macos-941fe7b/optimized/$f" filter/
  strip -S "filter/$f"                  # drop debug map with local build paths
  codesign --force --sign - "filter/$f" # arm64 binaries must be signed (ad-hoc)
done
cp "$WORK/splix-macos-941fe7b/ppd/"ml1630{,fr,pt}.ppd ppd/

file filter/*
