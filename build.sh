#!/bin/bash
set -euo pipefail

ROOT=$(realpath "$(dirname "$0")")
DOMAIN="laravel.com"
REPO="https://github.com/ElfSundae/laravel.com.git"
BRANCH="master"
OPTIONS="local-cdn remove-ga remove-ads cache"

if [[ -n ${1:-} ]]; then
    DOMAIN=$1
    shift
fi

WEBROOT="$ROOT/$DOMAIN"

rm -rf "$WEBROOT"
git clone $REPO --depth=1 -b $BRANCH "$WEBROOT"

rm -rf "$ROOT/laravel-docs-zh"
git clone "https://${GITHUB_TOKEN}@github.com/ElfSundae/laravel-docs-zh.git" "$ROOT/laravel-docs-zh"

rm -rf "$WEBROOT/resources/docs/zh"
mkdir -p "$WEBROOT/resources/docs/zh"
git -C "$ROOT/laravel-docs-zh" for-each-ref --shell --format="version=%(refname:lstrip=-1)" \
    --exclude=refs/remotes/origin/HEAD refs/remotes/ | \
    while read entry; do
        eval "$entry"
        path="$WEBROOT/resources/docs/zh/$version"
        cp -a "$ROOT/laravel-docs-zh" "$path"
        git -C "$path" switch $version -q
    done
rm -rf "$ROOT/laravel-docs-zh"

wget https://raw.githubusercontent.com/ElfSundae/build-laravel.com/master/build-laravel.com -O "$ROOT/build-laravel.com"
chmod +x "$ROOT/build-laravel.com"

"$ROOT/build-laravel.com" "$WEBROOT" --root-url="https://$DOMAIN" $OPTIONS "$@"
