-module(http2_spec_5_1_SUITE).

-include("http2.hrl").
-include_lib("eunit/include/eunit.hrl").
-include_lib("common_test/include/ct.hrl").
-compile([export_all]).

all() ->
    [
     sends_rst_stream_to_idle
    ].

init_per_suite(Config) ->
    application:ensure_started(crypto),
    chatterbox_test_buddy:start(Config).

end_per_suite(Config) ->
    chatterbox_test_buddy:stop(Config),
    ok.

sends_rst_stream_to_idle(_Config) ->
    {ok, Client} = http2c:start_link(),

    RstStream = #rst_stream{error_code=?CANCEL},
    RstStreamBin = http2_frame:to_binary(
                     {#frame_header{
                         stream_id=1
                        },
                      RstStream}),

    http2c:send_binary(Client, RstStreamBin),

    Resp = http2c:wait_for_n_frames(Client, 0, 1),
    ct:pal("Resp: ~p", [Resp]),
    ?assertEqual(1, length(Resp)),
    [{_GoAwayH, GoAway}] = Resp,
    ?PROTOCOL_ERROR = GoAway#goaway.error_code,
    ok.
