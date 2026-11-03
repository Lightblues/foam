#!/usr/bin/env bash
# Install the latest foam-vscode build from the Lightblues/foam fork.
#
#   curl -fsSL https://raw.githubusercontent.com/Lightblues/foam/eason/eason/install.sh | bash
#   ... | bash -s -- --cursor          # only Cursor
#   ... | bash -s -- --tag v0.47.0-eason.1
#
# Options: --code | --cursor | --all (default: every CLI found), --tag <tag>, --dry-run (download only)
set -euo pipefail

REPO="Lightblues/foam"
TAG=""
WANT=""
DRY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --code) WANT="$WANT code" ;;
    --cursor) WANT="$WANT cursor" ;;
    --all) WANT="code cursor" ;;
    --tag) TAG="$2"; shift ;;
    --dry-run) DRY=1 ;;
    -h|--help) sed -n '2,9p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done
[ -n "$WANT" ] || WANT="code cursor"

# Resolve the tag without the REST API (it is rate limited to 60 requests/hour per IP):
# /releases/latest redirects to /releases/tag/<tag>, and the asset is foam-vscode-<version>.vsix.
if [ -z "$TAG" ]; then
  loc="$(curl -fsSI -o /dev/null -w '%{url_effective}' -L "https://github.com/$REPO/releases/latest")"
  TAG="${loc##*/}"
fi
case "$TAG" in v[0-9]*) ;; *) echo "cannot resolve a release tag of $REPO (got '$TAG')" >&2; exit 1 ;; esac
tag="$TAG"
ver="${tag#v}"; ver="${ver%%-eason*}"
url="https://github.com/$REPO/releases/download/$tag/foam-vscode-$ver.vsix"

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
vsix="$tmp/$(basename "$url")"
echo "downloading $tag: $url"
curl -fsSL -o "$vsix" "$url"
[ -s "$vsix" ] || { echo "empty download" >&2; exit 1; }
[ "$DRY" = 1 ] && { echo "dry run: downloaded $(wc -c <"$vsix" | tr -d ' ') bytes, not installing"; exit 0; }

find_cli() {
  if command -v "$1" >/dev/null 2>&1; then command -v "$1"; return; fi
  case "$1" in
    code) p="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" ;;
    cursor) p="/Applications/Cursor.app/Contents/Resources/app/bin/cursor" ;;
  esac
  [ -x "${p:-}" ] && printf '%s' "$p"
  return 0
}

done_any=0
for c in $WANT; do
  cli="$(find_cli "$c")"
  if [ -z "$cli" ]; then echo "skip $c: CLI not found"; continue; fi
  echo "installing into $c"
  "$cli" --install-extension "$vsix" --force && done_any=1
done
[ "$done_any" = 1 ] || { echo "no editor CLI found (code/cursor)" >&2; exit 1; }
echo "done ($tag). Reload the editor window (Developer: Reload Window)."
echo "Tip: turn off Auto Update for the foam extension so the Marketplace does not replace this build."
