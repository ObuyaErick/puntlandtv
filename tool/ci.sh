#!/usr/bin/env bash
# Everything CI must run. Keep this the single source of truth so a green
# local run means a green pipeline.
set -euo pipefail

FLUTTER="${FLUTTER:-fvm flutter}"
DART="${DART:-fvm dart}"

echo "==> format"
$DART format --set-exit-if-changed lib test tool

echo "==> codegen (must be committed and up to date)"
$DART run build_runner build
if ! git diff --quiet -- '*.g.dart'; then
  echo "Generated files are stale. Run build_runner and commit the result." >&2
  exit 1
fi

echo "==> l10n"
$FLUTTER gen-l10n
# Full Somali parity is a release criterion, so an untranslated key fails the
# build rather than waiting to be noticed in week 9. gen-l10n writes `{}` when
# everything is translated, so test the content, not the file size.
if [ -f build/untranslated_messages.json ] \
   && ! grep -qx '{}' build/untranslated_messages.json; then
  echo "Untranslated messages — every key must exist in app_so.arb:" >&2
  cat build/untranslated_messages.json >&2
  exit 1
fi

echo "==> hardcoded user-facing strings"
# Cheap guard against a literal sneaking into a widget. Deliberately limited:
# it matches the single-line `Text('Some words'` form only, so a multi-line
# `Text(\n  'Some words',` slips past. It is a tripwire, not a proof — the
# real guarantee is the untranslated-messages gate above.
if grep -rnE "Text\('[A-Za-z]{3,}" lib --include='*.dart' \
     | grep -v '/l10n/' | grep -v '\.g\.dart'; then
  echo "Hardcoded string in a Text() widget — move it to app_en.arb." >&2
  exit 1
fi

echo "==> analyze"
$FLUTTER analyze

echo "==> layer boundaries"
$DART run tool/check_layers.dart

echo "==> test"
$FLUTTER test

echo "All checks passed."
