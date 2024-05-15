#!/bin/sh

set -eux

curdir="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
readonly curdir

erlc +debug "$curdir/src/tls_server.erl"
erl -noinput -s tls_server start
