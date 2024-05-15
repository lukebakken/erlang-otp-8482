# Setup

* Initialize submodules
    ```
    git submodule update --init
    ```
* Generate certs
    * The `DOMAIN` argument _must_ start with a dot `.`
    * The `CN` argument must be a host in the `DOMAIN`
    ```
    make -C tls-gen/one_intermediate DOMAIN=.foo.bar CN=host.foo.bar
    ```

# Reproducing issue

* In one terminal, run TLS server:
    ```
    ./run-tls-server.sh
    ```
* In another terminal, run TLS client:
    ```
    ./run-tls-client.sh
    ```
* The TLS server should log the following:
    ```
    =NOTICE REPORT==== 15-May-2024::07:03:08.770115 ===
    TLS server: In state wait_cert at ssl_handshake.erl:2115 generated SERVER ALERT: Fatal - Bad Certificate

    =ERROR REPORT==== 15-May-2024::07:03:08.770926 ===
    ssl:handshake Error: {error,
                            {tls_alert,
                                {bad_certificate,
                                    "TLS server: In state wait_cert at ssl_handshake.erl:2115 generated SERVER ALERT: Fatal - Bad Certificate\n"}}}
    ```

# Workaround

To "resolve" the issue, comment-out the `nameConstraints` extension in
`tls-gen/one_intermediate/openssl.cnf`, and re-generate certificates. The above
steps will succeed.

# OpenSSL server

* In one terminal, run OpenSSL TLS server:
    ```
    ./run-openssl-server.sh
    ```
* In another terminal, run TLS client:
    ```
    ./run-tls-client.sh
    ```
* Both client and server should report success.
