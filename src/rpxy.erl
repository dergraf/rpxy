-module(rpxy).
-export([start/0, stop/0]).

start() ->
    application:ensure_all_started(rpxy).

stop() ->
    application:stop(rpxy),
    application:stop(ranch).
