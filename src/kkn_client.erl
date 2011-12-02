-module(kkn_client).

-export([start/0]).

start() ->
    {ok, Socket} =
	gen_tcp:connect("localhost" , 3000,
			[binary, {packet, 4}]),
    client_loop(Socket).
    
client_loop(Socket) ->
    
    Commands = [get, who, i_am_devil],
    Index = random:uniform(length(Commands)),
    Command = lists:nth(Index, Commands),
    ok = gen_tcp:send(Socket, term_to_binary(Command)),

    receive
	{tcp,Socket,Bin} ->
	    io:format("Client received binary = ~p~n" ,[Bin]),
	    Val = binary_to_term(Bin),
	    io:format("Client result = ~p~n" ,[Val]),
	    case Val of
		redirect ->

		    waiting_for_death(Socket);
		_ ->
		    lib_misc:sleep(4000),
		    client_loop(Socket)
	    end;

	Any ->
	    io:format("Received something like that ~p~n", [Any]),
	    gen_tcp:close(Socket)
		
end.


waiting_for_death(Socket) ->
    ok = gen_tcp:send(Socket, term_to_binary(death_confirmed)),
    receive
	{tcp,Socket,Bin} ->
	    Val = binary_to_term(Bin),
	    case Val of
		death ->
		    io:format("Client received death note ~n"),
		    gen_tcp:close(Socket)
		end;
	Any ->
	    io:format("in death we have ~p~n", [Any]),
	    gen_tcp:close(Socket)
    
end.



