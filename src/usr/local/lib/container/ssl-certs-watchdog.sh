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
    printf "%s %s: Info: %s\n" "$(date +'%b %d %H:%M:%S')" "ssl-certs-watchdog" "$(printf "$@")" >&2
}

CERT_DIR="/etc/dovecot/ssl/mail"
[ -e "$CERT_DIR" ] || exit 0
[ -d "$CERT_DIR" ] || { echo "Invalid certificate directory '$CERT_DIR': Not a directory" >&2; exit 1; }

log "Starting SSL certificates watchdog service"
inotifywait -e close_write,delete,move -m "$CERT_DIR/" \
    | while read -r DIRECTORY EVENTS FILENAME; do
        log "Receiving inotify event '%s' for '%s%s'" "$EVENTS" "$DIRECTORY" "$FILENAME"

        # wait till 300 sec (5 min) after the last event, new events reset the timer
        while read -t 300 -r DIRECTORY EVENTS FILENAME; do
            log "Receiving inotify event '%s' for '%s%s'" "$EVENTS" "$DIRECTORY" "$FILENAME"
        done

        log "Triggering configuration reload"
        dovecot reload
    done
