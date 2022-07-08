%%%-------------------------------------------------------------------
%%% @author bnjm
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 08. Jul 2022 2:43 PM
%%%-------------------------------------------------------------------
-module(emqx_shared).
-author("bnjm").

%% API

%% API
-compile([export_all]).

connect() ->
  Host = "localhost",
  Port = 1883,
  {ok, ConnPid} = emqtt:start_link([
    {proto_ver, v5},
    {host, Host},
    {port, Port}
  ]),
  {ok, _P} = emqtt:connect(ConnPid),
%%  logger:info("[~p] connected~n", [ConnPid]),
  ConnPid.

disconnect(ClientPid) ->
  emqtt:disconnect(ClientPid),
%%  logger:info("[~p] disconnected~n", [ClientPid]),
  ok.

publish(ClientPid, Topic, Message) ->
  ok = emqtt:publish(ClientPid, <<Topic/binary>>, Message),
%%  logger:info("[~p] published to ~p", [ClientPid, Topic]),
  ok.

fire_and_forget(Topic, Message) ->
  Pub0 = connect(),
  ok = emqtt:publish(Pub0, <<Topic/binary>>, Message),
  disconnect(Pub0),
  ok.

recv_loop(ClientPid, MessageCount) ->
  receive
    {publish, #{payload := M}} ->
      logger:info("[~p] ~p~n", [ClientPid, M]),
      recv_loop(ClientPid, MessageCount + 1)
  after 3000 ->
    logger:info("[~p] finished received: ~p~n", [ClientPid, MessageCount]),
    disconnect(ClientPid)
  end.

subscribe_shared(Topic) ->
  spawn(fun() ->
    ClientPid = connect(),
    T = <<"$share/", Topic/binary>>,
    {ok, _, Code} = emqtt:subscribe(ClientPid, T),
    logger:info("[~p] subscribed to ~p (code: ~p)  ~n", [ClientPid, T, Code]),
    recv_loop(ClientPid, 0)
        end),
  ok.


test_lasting_publishers() ->
  subscribe_shared(<<"group1/test/in">>),
  subscribe_shared(<<"group1/test/in">>),
  timer:sleep(1000),
  Pub0 = connect(),
  Pub1 = connect(),
  lists:foreach(fun(_) ->
    timer:sleep(100),
    publish(Pub0, <<"test/in">>, <<"hello world">>),
    timer:sleep(100),
    publish(Pub1, <<"test/in">>, <<"hello world">>)
                end, lists:seq(1, 10)),

  ok.

test_fire_and_forget_scenario() ->
  subscribe_shared(<<"group1/test/in">>),
  subscribe_shared(<<"group1/test/in">>),
  subscribe_shared(<<"group1/test/in">>),
  subscribe_shared(<<"group1/test/in">>),
  subscribe_shared(<<"group1/test/in">>),
  timer:sleep(1000),
  lists:foreach(fun(_) ->
    fire_and_forget(<<"test/in">>, <<"hello world">>)
                end, lists:seq(1, 10)),

  ok.
