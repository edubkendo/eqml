-module(eqml).
-export([
	start/1, init/1, send/2, set/3, 
	connect0/3, connect1/3, connect2/3, connect3/3, connect4/3, connect5/3,
	invoke/2, invoke/3, invoke/4, invoke/5,
	url/1,
	point/2,
	datetime/2
]).

start(QmlFile) ->
	proc_lib:start(eqml, init, [QmlFile]).

init(QmlFile) ->
	PortName = filename:join(filename:dirname(code:which(eqml)), "eqml"),
	Port = open_port({spawn, PortName ++ " " ++ QmlFile}, [{packet, 4}, binary, nouse_stdio]),
	erlang:register(eqml, Port),
	proc_lib:init_ack(ok), 

	loop(Port).

loop(Port) ->
	receive
		{Port, {data, Data}} ->
			dispatch(binary_to_term(Data)),
			loop(Port);
		Other ->
			io:format("eqml: ~p~n", [Other]),
			loop(Port)
	end.

dispatch({signal, To, Slot}) ->
	list_to_pid(To) ! Slot;
dispatch({signal, To, Slot, A}) ->
	list_to_pid(To) ! {Slot, A};
dispatch({signal, To, Slot, A, B}) ->
	list_to_pid(To) ! {Slot, A, B};
dispatch({signal, To, Slot, A, B, C}) ->
	list_to_pid(To) ! {Slot, A, B, C};
dispatch({signal, To, Slot, A, B, C, D}) ->
	list_to_pid(To) ! {Slot, A, B, C, D};
dispatch({signal, To, Slot, A, B, C, D, E}) ->
	list_to_pid(To) ! {Slot, A, B, C, D, E};
dispatch(Unknown) ->
	io:format("eqml: can't dispatch ~p~n", [Unknown]).

set(Obj, Prop, Val) ->
	send(set, {Obj, Prop, Val}).

connect0(Obj, Signal, Tag) -> connect(Obj, Signal, Tag, 0).
connect1(Obj, Signal, Tag) -> connect(Obj, Signal, Tag, 1).
connect2(Obj, Signal, Tag) -> connect(Obj, Signal, Tag, 2).
connect3(Obj, Signal, Tag) -> connect(Obj, Signal, Tag, 3).
connect4(Obj, Signal, Tag) -> connect(Obj, Signal, Tag, 4).
connect5(Obj, Signal, Tag) -> connect(Obj, Signal, Tag, 5).

connect(Obj, Signal, Tag, Order) ->
	send(connect, {Obj, Signal, Tag, Order, pid_to_list(self())}).

invoke(Obj, Member) ->
	send(invoke0, {Obj, Member}).
invoke(Obj, Member, Arg0) ->
	send(invoke1, {Obj, Member, Arg0}).
invoke(Obj, Member, Arg0, Arg1) ->
	send(invoke2, {Obj, Member, Arg0, Arg1}).
invoke(Obj, Member, Arg0, Arg1, Arg2) ->
	send(invoke3, {Obj, Member, Arg0, Arg1, Arg2}).

send(Tag, Msg) ->
	erlang:port_command(eqml, erlang:term_to_binary({Tag, Msg})).

url(Url) ->
	{url, Url}.
point(X, Y) ->
	{point, {X, Y}}.
datetime(Date, Time) ->
	{datetime, {Date, Time}}.
