-module(kkn_socket_server).

-compile(export_all).
start_server()->
    {ok, Listen} = gen_tcp:listen(9999, [binary, {packet,4},
					 {reuseaddr, true},
					 {active, true}]),
    {ok, Socket} = gen_tcp:accept(Listen),
    gen_tcp:close(Listen),
    loop(Socket).

loop(Socket) ->
    receive
	{tcp, Socket, Bin} ->
	    io:format("Server received binary = ~p~n", [Bin]),
	    Str = binary_to_term(Bin),
	    io:format("Server (unpacked ~p~n",[Str]),
	    Reply = some_reply,
	    io:format("Server replying = ~p~n", [Reply]),
	    gen_tcp:send(Socket, term_to_binary(Reply)),
	    loop(Socket);
	{tcp_closed, Socket} ->
	    io:format("Server socket closed~n")
end.

client_eval(Str)->
    {ok, Socket} =
	gen_tcp:connect("127.0.0.1", 9999,
			[binary, {packet, 4}]),
    ok = gen_tcp:send(Socket, term_to_binary(Str)),
    receive
	{tcp, Socket, Bin} ->
	    io:format("Client received binary = ~p ~n", [Bin]),
	    Val = binary_to_term(Bin),
	    io:format("Client result = ~p ~n", [Val]),
	    gen_tcp:close(Socket);
	{tcp_closed, Socket} ->
	   io:format("Socket closed~n")
end.
	
