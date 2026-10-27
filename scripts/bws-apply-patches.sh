#!/usr/bin/env bash
# Applies the BWS source patches in patches/react-native/ to a pristine
# onnxruntime checkout, in sorted order.
#
# Usage:
#   scripts/bws-apply-patches.sh <path-to-onnxruntime-checkout>
#
# Run by the publish-js-packages workflow after the BWS overlay has been
# applied to a release tag (e.g. v1.25.0) of microsoft/onnxruntime. Each patch
# is checked before it is applied; the script stops at the first failure.
set -euo pipefail

CHECKOUT="${1:?usage: bws-apply-patches.sh <onnxruntime-checkout-path>}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATCH_DIR="$SCRIPT_DIR/../patches/react-native"

if [[ ! -f "$CHECKOUT/js/react_native/package.json" ]]; then
  echo "ERROR: $CHECKOUT does not look like an onnxruntime checkout (missing js/react_native)" >&2
  exit 1
fi

export LC_ALL=C
shopt -s nullglob
# Glob expansion is sorted.
patches=("$PATCH_DIR"/*.patch)
shopt -u nullglob

if [[ ${#patches[@]} -eq 0 ]]; then
  echo "ERROR: no patches found in $PATCH_DIR" >&2
  exit 1
fi

for p in "${patches[@]}"; do
  name="$(basename "$p")"
  echo "Applying $name"
  if ! git -C "$CHECKOUT" apply --check "$p"; then
    echo "ERROR: $name does not apply to $CHECKOUT" >&2
    exit 1
  fi
  if ! git -C "$CHECKOUT" apply "$p"; then
    echo "ERROR: applying $name to $CHECKOUT failed" >&2
    exit 1
  fi
done

echo "Applied ${#patches[@]} BWS patch(es) at $CHECKOUT"
