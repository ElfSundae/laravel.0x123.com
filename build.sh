#!/bin/bash
set -euo pipefail

ROOT=$(realpath "$(dirname "$0")")
WEBROOT="$ROOT/webroot"

DOMAIN="laravel.com"
REPO="https://github.com/ElfSundae/laravel.com.git"
BRANCH="master"
OPTIONS="local-cdn remove-ga remove-ads cache"

if [[ -n ${1:-} ]]; then
    DOMAIN=$1
    shift
fi

# Clone laravel website
rm -rf "$WEBROOT"
git clone $REPO --depth=1 -b $BRANCH "$WEBROOT"

# Download the Chinese docs
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

# Build website
wget https://raw.githubusercontent.com/ElfSundae/build-laravel.com/master/build-laravel.com -O "$ROOT/build-laravel.com"
chmod +x "$ROOT/build-laravel.com"

(set -x; bash "$ROOT/build-laravel.com" "$WEBROOT" --root-url="https://$DOMAIN" $OPTIONS "$@")

rm -rf "$ROOT/build-laravel.com"

# Process the static website
original_storage=$(readlink "$WEBROOT/public/storage")
rm "$WEBROOT/public/storage"
mv "$original_storage" "$WEBROOT/public/storage"

mv "$WEBROOT/public/storage/site-cache/"* "$WEBROOT/public"
rm -rf "$WEBROOT/public/storage/site-cache"

rm -f "$WEBROOT/public/.htaccess"
rm -f "$WEBROOT/public/index.php"
rm -f "$WEBROOT/public/web.config"

rm -rf "$ROOT/public"
mv "$WEBROOT/public" "$ROOT"

rm -rf "$WEBROOT"
