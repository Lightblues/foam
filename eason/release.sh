#!/usr/bin/env bash
# Build foam-vscode and publish it as a GitHub release of the fork (run on devcloud_cpu, in a checkout of branch `eason`).
#
#   eason/release.sh              # build + release as v<version>-eason.<n>
#   eason/release.sh --dry-run    # build only
#
# Needs: node, npx, gh (logged in as the owner of the fork).
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

REPO="Lightblues/foam"
DRY=0; [ "${1:-}" = "--dry-run" ] && DRY=1
YARN="npx --yes yarn@1.22.22"

[ -z "$(git status --porcelain --untracked-files=no)" ] || { echo "working tree has uncommitted changes" >&2; exit 1; }

$YARN install --frozen-lockfile --ignore-scripts
(cd packages/foam-core && $YARN build)

# Upstream raises engines.vscode to its newest test version; the extension itself runs on older
# editors. Lower the floor only for the packaged build (restored afterwards, so merges stay clean).
# vsce also requires @types/vscode <= engines, so that field is lowered in the same temporary edit.
# Override with ENGINE_MIN=^1.136.0 to keep the upstream value.
ENGINE_MIN="${ENGINE_MIN:-^1.110.0}"
PKG=packages/foam-vscode/package.json
trap 'git checkout -q -- "$PKG"' EXIT
node -e "const f=\"$PKG\",fs=require(\"fs\"),p=JSON.parse(fs.readFileSync(f));p.engines.vscode=\"$ENGINE_MIN\";p.devDependencies[\"@types/vscode\"]=\"$ENGINE_MIN\";fs.writeFileSync(f,JSON.stringify(p,null,2)+\"\\n\")"
(cd packages/foam-vscode && $YARN build && $YARN package)
git checkout -q -- "$PKG"

ver="$(node -p "require('./packages/foam-vscode/package.json').version")"
vsix="packages/foam-vscode/foam-vscode-$ver.vsix"
[ -f "$vsix" ] || { echo "missing $vsix" >&2; exit 1; }
echo "built $vsix"
[ "$DRY" = 1 ] && exit 0

git push origin HEAD
n=1
while gh release view "v$ver-eason.$n" --repo "$REPO" >/dev/null 2>&1; do n=$((n+1)); done
tag="v$ver-eason.$n"
up="$(git rev-parse --short upstream/main 2>/dev/null || echo unknown)"
gh release create "$tag" "$vsix" --repo "$REPO" --target "$(git rev-parse HEAD)" --latest \
  --title "foam-vscode $ver (eason fork #$n)" \
  --notes "Built from $(git rev-parse --short HEAD) on branch $(git rev-parse --abbrev-ref HEAD); upstream main at $up. Install: curl -fsSL https://raw.githubusercontent.com/$REPO/eason/eason/install.sh | bash"
echo "released $tag"
