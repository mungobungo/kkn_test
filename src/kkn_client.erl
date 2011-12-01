-module(kkn_client).

-export([client_start/1]).

client_start(Str)->
    {ok, Socket} =
	gen_tcp:connect("127.0.0.1", 9999,
			[binary, {packet, 4}]),
    client_loop(Socket, Str).


client_loop(Socket, Str) ->
    ok = gen_tcp:send(Socket, term_to_binary(Str)),
    sleep(5000),
    
    receive
	{tcp, Socket, Bin} ->
	    io:format("Client received binary = ~p ~n", [Bin]),
	    Val = binary_to_term(Bin),
	    io:format("Client result = ~p ~n", [Val]),
	    client_loop(Socket, Str);
%%	    gen_tcp:close(Socket);
	{tcp_closed, Socket} ->
	    io:format("Socket closed~n")

	 
    end.
    
sleep(T) ->
    receive
    after T ->
	    true
    end.
