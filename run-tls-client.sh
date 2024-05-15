#!/bin/sh

set -eux

openssl s_client -ign_eof -connect localhost:4433 \
    -CAfile "./tls-gen/one_intermediate/result/chained_ca_certificate.pem" \
    -cert "./tls-gen/one_intermediate/result/client_certificate.pem" \
    -key "./tls-gen/one_intermediate/result/client_key.pem"
