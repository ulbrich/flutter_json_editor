#!/usr/bin/env bash
# Releases the next version of the package from the current release branch:
# runs the tests, bumps `version:` in pubspec.yaml (if needed), commits it,
# tags it and pushes branch and tag. Run it as `make release` from a clean
# branch that's in sync with origin.
#
#   master             (material_ui)              tags v<x.y.z>
#   renderer/material  (Flutter's material.dart)  tags material-v<x.y.z>
#
#   scripts/release.sh          release the next version
#   scripts/release.sh --next   only print the next tag and the last one
#
#   VERSION=1.2.3   use this version instead of the default: the pubspec's
#                   version if it has no tag yet, else the last tag's patch + 1
set -euo pipefail

REPO_DIR=$(cd "$(dirname "$0")/.." && pwd)
PUBSPEC=pubspec.yaml

die() { echo "release: $*" >&2; exit 1; }

mode=release
[ "${1:-}" = --next ] && mode=next

cd "$REPO_DIR"

branch=$(git symbolic-ref --short -q HEAD || true)
case "$branch" in
  master) prefix=v ;;
  renderer/material) prefix=material-v ;;
  *) die "releases are made from master or renderer/material, not ${branch:-$(git rev-parse --short HEAD)}" ;;
esac

current=$(sed -n 's/^version: *\([^ ]*\) *$/\1/p' "$PUBSPEC" | head -1)
[ -n "$current" ] || die "can't read the version from $PUBSPEC"

# The latest <prefix>x.y.z tag, sorted numerically (0.8.10 after 0.8.9).
last=$(git tag -l "$prefix[0-9]*.[0-9]*.[0-9]*" | sed "s/^$prefix//" |
  grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | sort -t. -k1,1n -k2,2n -k3,3n | tail -1 || true)

if [ -n "${VERSION:-}" ]; then
  version=$VERSION
elif [ -z "$last" ] || ! git rev-parse -q --verify "refs/tags/$prefix$current" >/dev/null; then
  version=$current
else
  version=$(echo "$last" | awk -F. '{ printf "%d.%d.%d", $1, $2, $3 + 1 }')
fi
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "VERSION must look like 1.2.3, not '$version'"
tag="$prefix$version"

if [ "$mode" = next ]; then
  echo "$tag ${last:+$prefix$last}${last:--} $current"
  exit 0
fi

# --- Checks ------------------------------------------------------------------

git diff --quiet HEAD -- || die "there are uncommitted changes; commit or stash them first"
[ -z "$(git ls-files --others --exclude-standard)" ] || die "there are untracked files; commit or remove them first"
git fetch --quiet origin "$branch" --tags
[ "$(git rev-parse HEAD)" = "$(git rev-parse "origin/$branch")" ] || die "$branch isn't the same as origin/$branch; push (or pull) first"
git rev-parse -q --verify "refs/tags/$tag" >/dev/null && die "tag $tag already exists"

echo "release: running the tests"
flutter test --reporter=failures-only || die "the tests failed; nothing was released"

# --- Bump, tag, push ---------------------------------------------------------

refs=("$tag")
if [ "$current" != "$version" ]; then
  echo "release: bumping $PUBSPEC $current → $version"
  sed -i '' "s/^version: *$current *$/version: $version/" "$PUBSPEC"
  git commit --quiet -m "Released $version" -- "$PUBSPEC"
  refs=("$branch" "$tag")
fi

echo "release: tagging and pushing $tag"
git tag -a "$tag" -m "flutter_json_editor $version ($branch)"
git push --quiet --atomic origin "${refs[@]}" ||
  die "pushing failed; fix it and push ${refs[*]} by hand (or undo with: git tag -d $tag${refs[1]:+ && git reset --hard HEAD~1})"

echo "release: done, depend on it with ref: $tag"
