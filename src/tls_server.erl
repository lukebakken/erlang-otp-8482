-module(tls_server).

-export([start/0, sni_fun/1]).

-include_lib("kernel/include/logger.hrl").

start() ->
    inets:start(),
    ssl:start(),
    logger:set_application_level(ssl, debug),
    {ok, Cwd} = file:get_cwd(),
    ok = io:format("[INFO] tls_server working directory:~tp~n", [Cwd]),
    % Default = ssl:signature_algs(default, 'tlsv1.3'),
    SslOpts = [
        {cacertfile, "./tls-gen/one_intermediate/result/chained_ca_certificate.pem"},
        {certfile, "./tls-gen/one_intermediate/result/server_certificate.pem"},
        {keyfile, "./tls-gen/one_intermediate/result/server_key.pem"},
        {reuseaddr, true},
        {sni_fun, fun tls_server:sni_fun/1},
        {crl_check, false},
        {verify, verify_peer},
        {fail_if_no_peer_cert, true},
        {log_level, debug} %,
        % {signature_algs_cert, Default ++ [{sha, rsa}]}
    ],
    % dbg:tracer(),
    % dbg:p(all, [call]),
    % dbg:tpl(pubkey_cert, validate_time, cx),
    ListenSocket = listen(SslOpts),
    accept_and_handshake(SslOpts, ListenSocket).

listen(SslOpts) ->
    ?LOG_DEBUG("before ssl:listen, SslOpts: ~p", [SslOpts]),
    S = case ssl:listen(4433, SslOpts) of
            {error, eaddrinuse} ->
                ?LOG_ERROR("ssl:listen eaddrinuse"),
                timer:sleep(1000),
                listen(SslOpts);
            {error, _}=Error ->
                ?LOG_ERROR("ssl:listen exiting, Error: ~p", [Error]),
                ok = init:stop();
            {ok, S0} ->
                S0
        end,
    ?LOG_DEBUG("after ssl:listen"),
    S.

accept_and_handshake(SslOpts, ListenSocket) ->
    ?LOG_DEBUG("before ssl:transport_accept"),
    {ok, TLSTransportSocket} = ssl:transport_accept(ListenSocket),
    ?LOG_DEBUG("after ssl:transport_accept"),
    ?LOG_DEBUG("before ssl:handshake"),
    Result =
        case ssl:handshake(TLSTransportSocket, SslOpts, 10000) of
            {ok, S, Ext} ->
                ?LOG_INFO("ssl:handshake Ext: ~p~n", [Ext]),
                {ok, S};
            {ok, _} = Res ->
                Res;
            Error ->
                ssl:shutdown(ListenSocket, read_write),
                ssl:close(ListenSocket),
                ?LOG_ERROR("ssl:handshake Error: ~p", [Error]),
                NewSocket = listen(SslOpts),
                accept_and_handshake(SslOpts, NewSocket)
        end,
    case Result of
        {error, _}=Error1 ->
            ?LOG_ERROR("exiting, Error: ~p", [Error1]),
            ok = init:stop();
        {ok, TlsSocket} ->
            ?LOG_DEBUG("after ssl:handshake, Socket: ~p", [TlsSocket]),
            ?LOG_DEBUG("ssl:handshake sni_hostname: ~p", [get_sni_hostname(TlsSocket)]),
            write_keylog(TlsSocket),
            ok = loop(TlsSocket),
            accept_and_handshake(SslOpts, ListenSocket)
    end.

loop(TlsSocket) ->
    ?LOG_DEBUG("top of loop/2"),
    receive
        {ssl_closed, TlsSocket} ->
            ?LOG_DEBUG("shutdown/close socket"),
            ssl:shutdown(TlsSocket, read_write),
            ssl:close(TlsSocket),
            ok;
        Data ->
            ?LOG_INFO("Received Data: ~p", [Data]),
            loop(TlsSocket)
    after 5000 ->
        ?LOG_WARNING("no data in last 5 seconds!"),
        loop(TlsSocket)
    end.

write_keylog(Socket) ->
    ?LOG_INFO("writing keylog data to keylog.bin"),
    KeylogItems1 =
        case ssl:connection_information(Socket, [keylog]) of
            {ok, [{keylog, KeylogItems0}]} ->
                KeylogItems0;
            {ok, []} ->
                ?LOG_WARNING("[WARNING] no keylog data!"),
                []
        end,
    ok = file:write_file("keylog.bin", [[KeylogItem, $\n] || KeylogItem <- KeylogItems1]),
    ok.

sni_fun(ServerName) ->
    ?LOG_DEBUG("sni_fun ServerName: ~p", [ServerName]),
    [].

get_sni_hostname(Socket) ->
    case ssl:connection_information(Socket, [sni_hostname]) of
        {ok, []} ->
            undefined;
        {ok, [{sni_hostname, Hostname}]} ->
            Hostname;
        Error ->
            ?LOG_ERROR("ssl:connection_information Error: ~p", [Error]),
            undefined
    end.
