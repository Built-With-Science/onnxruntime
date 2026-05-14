#!/usr/bin/env bash
# Transforms a pristine onnxruntime checkout into the @Built-With-Science
# scoped variant for publishing to GitHub Packages.
#
# Usage:
#   scripts/bws-rename-js-packages.sh <path-to-onnxruntime-checkout>
#
# Run by the publish-js-packages workflow after checking out a release tag
# (e.g. v1.25.0) of microsoft/onnxruntime. Idempotent.
set -euo pipefail

REPO="${1:?usage: bws-rename-js-packages.sh <onnxruntime-checkout-path>}"
SCOPE="@Built-With-Science"

cd "$REPO"

if [[ ! -f js/common/package.json || ! -f js/react_native/package.json ]]; then
  echo "ERROR: $REPO does not look like an onnxruntime checkout (missing js/common or js/react_native)" >&2
  exit 1
fi

node <<NODE
const fs = require('fs');
const path = require('path');

const FORK_URL = 'git+https://github.com/Built-With-Science/onnxruntime.git';
const GH_REGISTRY = 'https://npm.pkg.github.com';

function patchPackageJson(file, mutator) {
  const pkg = JSON.parse(fs.readFileSync(file, 'utf8'));
  mutator(pkg);
  fs.writeFileSync(file, JSON.stringify(pkg, null, 2) + '\n');
}

patchPackageJson('js/common/package.json', (p) => {
  p.name = '${SCOPE}/onnxruntime-common';
  p.repository = { type: 'git', url: FORK_URL };
  p.publishConfig = { registry: GH_REGISTRY };
});

patchPackageJson('js/react_native/package.json', (p) => {
  p.name = '${SCOPE}/onnxruntime-react-native';
  p.repository = { type: 'git', url: FORK_URL };
  p.publishConfig = { registry: GH_REGISTRY };
  if (p.dependencies && p.dependencies['onnxruntime-common']) {
    const v = p.dependencies['onnxruntime-common'];
    delete p.dependencies['onnxruntime-common'];
    p.dependencies['${SCOPE}/onnxruntime-common'] = v;
  }
});
NODE

for f in js/react_native/lib/index.ts js/react_native/lib/backend.ts js/react_native/lib/api.ts; do
  if [[ -f "$f" ]]; then
    sed -i "s|'onnxruntime-common'|'${SCOPE}/onnxruntime-common'|g" "$f"
  fi
done

PREPACK=js/react_native/scripts/prepack.ts
if [[ -f "$PREPACK" ]]; then
  sed -i "s|packageSelf.dependencies\['onnxruntime-common'\]|packageSelf.dependencies['${SCOPE}/onnxruntime-common']|g" "$PREPACK"
fi

echo "Applied BWS overlay at $REPO"
