#!/bin/sh
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

log() {
    printf "%s %s: Info: %s\n" "$(date +'%b %d %H:%M:%S')" "dovecot-ssl-setup" "$(printf "$@")" >&2
}

log "Setting up Dovecot SSL configuration"

if [ ! -f "/etc/dovecot/ssl/dhparams.pem" ]; then
    # generating Diffie Hellman parameters might take a few minutes...
    log "Generating Diffie Hellman parameters"
    openssl dhparam -out "/etc/dovecot/ssl/dhparams.pem" 2048
fi
