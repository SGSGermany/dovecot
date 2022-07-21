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

[ $# -gt 0 ] || set -- dovecot -F

if [ "$1" == "dovecot" ]; then
    /usr/local/lib/container/dovecot-ssl-setup.sh
    /usr/local/lib/container/dovecot-sql-setup.sh

    /usr/local/lib/container/ssl-certs-watchdog.sh &
fi

exec "$@"
