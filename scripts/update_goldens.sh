#!/usr/bin/env bash
set -euo pipefail

# Render the golden screenshot tests (test/goldens) in the Linux x64 container
# that matches the CI Unit Tests job, and write the images back into the tree.
#
#   scripts/update_goldens.sh            regenerate every golden image
#   scripts/update_goldens.sh --check    compare only; diffs land in test/goldens/failures/
#   scripts/update_goldens.sh [--check] test/goldens/shell_golden_test.dart ...
#
# Needs Docker. The Flutter version is read from FLUTTER_VERSION in
# .github/workflows/ci.yml, so the images always come from the CI toolchain.
# On Apple silicon the container runs under amd64 emulation; the first run
# builds the image and takes a while.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

mode=update
if [ "${1:-}" = "--check" ]; then
  mode=check
  shift
fi

flutter_version="$(sed -n 's/^  FLUTTER_VERSION: "\(.*\)"$/\1/p' "$ROOT/.github/workflows/ci.yml")"
if [ -z "$flutter_version" ]; then
  echo "Could not read FLUTTER_VERSION from .github/workflows/ci.yml" >&2
  exit 1
fi

image="plezy-goldens:$flutter_version"
docker build --platform linux/amd64 --build-arg "FLUTTER_VERSION=$flutter_version" -t "$image" - <<'DOCKERFILE'
# Platforms: linux/amd64
FROM ubuntu:24.04@sha256:24737cef17f4e22b1977df7d9a05e77c4e28b7da5b8911f8d8ccda136bf3573c
ARG FLUTTER_VERSION
RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates curl git unzip xz-utils zip \
  && rm -rf /var/lib/apt/lists/*
RUN git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git /opt/flutter
ENV PATH=/opt/flutter/bin:$PATH
RUN git config --global --add safe.directory '*' \
  && flutter config --no-analytics \
  && flutter precache --universal \
  && flutter --version
DOCKERFILE

goldens_dir="$ROOT/test/goldens/goldens"
failures_dir="$ROOT/test/goldens/failures"
mkdir -p "$goldens_dir"
rm -rf "$failures_dir"

# The tree is copied inside the container so the host's .dart_tool and build
# output (macOS paths) are neither used nor overwritten.
docker run --rm --platform linux/amd64 \
  -e MODE="$mode" \
  -e HOST_UID="$(id -u)" \
  -e HOST_GID="$(id -g)" \
  -v "$ROOT:/src:ro" \
  -v "$goldens_dir:/out/goldens" \
  -v "$ROOT/test/goldens:/out/test-goldens" \
  -v plezy-goldens-pub-cache:/root/.pub-cache \
  "$image" bash -euo pipefail -c '
    mkdir /work
    tar -C /src --exclude=./.dart_tool --exclude=./build --exclude=./test/goldens/failures -cf - . | tar -C /work -xf -
    cd /work
    flutter pub get >/dev/null
    targets=("$@")
    [ "${#targets[@]}" -gt 0 ] || targets=(test/goldens)
    status=0
    if [ "$MODE" = update ]; then
      # A full run starts from an empty directory so images of removed tests go away.
      [ "$#" -gt 0 ] || rm -rf test/goldens/goldens
      flutter test --tags golden --update-goldens "${targets[@]}" || status=$?
      if [ "$#" -gt 0 ]; then
        cp -a test/goldens/goldens/. /out/goldens/
      else
        find /out/goldens -mindepth 1 -delete
        cp -a test/goldens/goldens/. /out/goldens/
      fi
      chown -R "$HOST_UID:$HOST_GID" /out/goldens
    else
      flutter test --tags golden "${targets[@]}" || status=$?
      if [ -d test/goldens/failures ]; then
        cp -a test/goldens/failures /out/test-goldens/
        chown -R "$HOST_UID:$HOST_GID" /out/test-goldens/failures
      fi
    fi
    exit "$status"
  ' bash "$@"
