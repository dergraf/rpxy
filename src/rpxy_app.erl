-module(rpxy_app).

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

%% ===================================================================
%% Application callbacks
%% ===================================================================

start(_StartType, _StartArgs) ->
    Port =
    case proplists:get_value(rpxy_port, init:get_arguments()) of
        [StringPort] -> list_to_integer(StringPort);
        undefined ->
                {ok, P} = application:get_env(port),
                P
    end,
    {ok, _} = ranch:start_listener(rpxy, 1,
                                   ranch_tcp, [{port, Port}], rpxy_session,
                                   application:get_all_env()),
    rpxy_sup:start_link().

stop(_State) ->
    ok.
