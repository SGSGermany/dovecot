#!/bin/bash
# Dovecot
# A container running Dovecot, an open-source IMAP server.
#
# Copyright (c) 2022  SGS Serious Gaming & Simulations GmbH
#
# This work is licensed under the terms of the MIT license.
# For a copy, see LICENSE file or <https://opensource.org/licenses/MIT>.
#
# SPDX-License-Identifier: MIT
# License-Filename: LICENSE

set -eu -o pipefail
export LC_ALL=C
shopt -u nullglob

[ -v CI_TOOLS ] && [ "$CI_TOOLS" == "SGSGermany" ] \
    || { echo "Invalid build environment: Environment variable 'CI_TOOLS' not set or invalid" >&2; exit 1; }

[ -v CI_TOOLS_PATH ] && [ -d "$CI_TOOLS_PATH" ] \
    || { echo "Invalid build environment: Environment variable 'CI_TOOLS_PATH' not set or invalid" >&2; exit 1; }

source "$CI_TOOLS_PATH/helper/common.sh.inc"
source "$CI_TOOLS_PATH/helper/container.sh.inc"
source "$CI_TOOLS_PATH/helper/container-alpine.sh.inc"

BUILD_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "$BUILD_DIR/container.env"

readarray -t -d' ' TAGS < <(printf '%s' "$TAGS")

echo + "CONTAINER=\"\$(buildah from $(quote "$BASE_IMAGE"))\"" >&2
CONTAINER="$(buildah from "$BASE_IMAGE")"

echo + "MOUNT=\"\$(buildah mount $(quote "$CONTAINER"))\"" >&2
MOUNT="$(buildah mount "$CONTAINER")"

pkg_install "$CONTAINER" --virtual .dovecot \
    dovecot \
    dovecot-mysql \
    dovecot-lmtpd \
    dovecot-pigeonhole-plugin \
    dovecot-fts-xapian

pkg_install "$CONTAINER" --virtual .dovecot-run-deps \
    inotify-tools \
    gettext

user_changeuid "$CONTAINER" dovecot 65536

user_add "$CONTAINER" ssl-certs 65537

user_add "$CONTAINER" mysql 65538

user_add "$CONTAINER" vmail 65539 "/var/vmail"

user_add "$CONTAINER" dovecot-sock 65540

echo + "rm -rf …/etc/dovecot …/etc/ssl/dovecot" >&2
rm -rf \
    "$MOUNT/etc/dovecot" \
    "$MOUNT/etc/ssl/dovecot"

echo + "rsync -v -rl --exclude .gitignore ./src/ …/" >&2
rsync -v -rl --exclude '.gitignore' "$BUILD_DIR/src/" "$MOUNT/"

cmd buildah run "$CONTAINER" -- \
    find "/etc/dovecot" -name 'dovecot-sql*.conf.ext' -mindepth 1 -maxdepth 1 \
         -exec chmod 640 {} \;

cmd buildah run "$CONTAINER" -- \
    find "/etc/dovecot" -name 'dovecot-sql*.conf.ext' -mindepth 1 -maxdepth 1 \
        -exec chown root:dovecot {} \;

VERSION="$(pkg_version "$CONTAINER" dovecot)"

cleanup "$CONTAINER"

cmd buildah config \
    --port "143/tcp" \
    --port "993/tcp" \
    --port "4190/tcp" \
    "$CONTAINER"

cmd buildah config \
    --volume "/etc/dovecot/ssl" \
    --volume "/var/vmail" \
    --volume "/run/mail" \
    --volume "/run/mysql" \
    "$CONTAINER"

cmd buildah config \
    --workingdir "/var/vmail" \
    --entrypoint '[ "/entrypoint.sh" ]' \
    --cmd '[ "dovecot", "-F" ]' \
    "$CONTAINER"

cmd buildah config \
    --annotation org.opencontainers.image.title="Dovecot" \
    --annotation org.opencontainers.image.description="A container running Dovecot, an open-source IMAP server." \
    --annotation org.opencontainers.image.version="$VERSION" \
    --annotation org.opencontainers.image.url="https://github.com/SGSGermany/dovecot" \
    --annotation org.opencontainers.image.authors="SGS Serious Gaming & Simulations GmbH" \
    --annotation org.opencontainers.image.vendor="SGS Serious Gaming & Simulations GmbH" \
    --annotation org.opencontainers.image.licenses="MIT" \
    --annotation org.opencontainers.image.base.name="$BASE_IMAGE" \
    --annotation org.opencontainers.image.base.digest="$(podman image inspect --format '{{.Digest}}' "$BASE_IMAGE")" \
    "$CONTAINER"

con_commit "$CONTAINER" "${TAGS[@]}"
