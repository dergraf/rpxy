-module(rpxy_session).
-behaviour(ranch_protocol).

-export([start_link/4]).
-export([init/4]).

start_link(Ref, Socket, Transport, Opts) ->
    random:seed(now()),
    {_, Endpoints} = lists:keyfind(endpoints, 1, Opts),
    Endpoint = lists:nth(random:uniform(length(Endpoints)), Endpoints),
    Pid = spawn_link(?MODULE, init, [Ref, Socket, Transport, Endpoint]),
    {ok, Pid}.

init(Ref, Socket, Transport, {Ip, Port}) ->
    ok = ranch:accept_ack(Ref),
    {ok, OutSocket} = Transport:connect(Ip, Port, []),
    Self = self(),
    OutPid = spawn_link(fun() ->
                       loop(OutSocket, Transport, Self)
               end),
    Transport:controlling_process(OutSocket, OutPid),
    loop(Socket, Transport, OutPid).

loop(Socket, Transport, OtherPid) ->
    Transport:setopts(Socket, [{active, once}]),
    receive
        {tcp, Socket, Data} ->
            OtherPid ! {other, Data},
            loop(Socket, Transport, OtherPid);
        {other, Data} ->
            Transport:send(Socket, Data),
            loop(Socket, Transport, OtherPid);
        close ->
            ok = Transport:close(Socket);
        _ ->
            OtherPid ! close,
            ok = Transport:close(Socket)
    end.

