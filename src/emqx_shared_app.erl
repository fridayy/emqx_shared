%%%-------------------------------------------------------------------
%% @doc emqx_shared public API
%% @end
%%%-------------------------------------------------------------------

-module(emqx_shared_app).

-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    emqx_shared_sup:start_link().

stop(_State) ->
    ok.

%% internal functions
