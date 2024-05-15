#!/bin/sh

set -eu

curdir="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
readonly curdir
readonly tlshost="${1:-*}"
readonly tlsport="${2:-4433}"

readonly certs_dir="$curdir/tls-gen/one_intermediate/result"
readonly ca_file="$certs_dir/chained_ca_certificate.pem"
readonly cert_file="$certs_dir/server_certificate.pem"
readonly key_file="$certs_dir/server_key.pem"

openssl s_server -accept "$tlshost:$tlsport" -CAfile "$ca_file" -cert "$cert_file" -key "$key_file"
