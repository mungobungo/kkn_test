%%%-------------------------------------------------------------------
%%% @author oleg <oleg@ubuntu>
%%% @copyright (C) 2011, oleg
%%% @doc
%%%
%%% @end
%%% Created :  1 Dec 2011 by oleg <oleg@ubuntu>
%%%-------------------------------------------------------------------
-module(kkn_socket_server).

-behaviour(gen_server).

%% API
-export([start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).


-define(SERVER, ?MODULE). 

-record(state, {}).

%%%===================================================================
%%% API
%%%===================================================================

%%--------------------------------------------------------------------
%% @doc
%% Starts the server
%%
%% @spec start_link() -> {ok, Pid} | ignore | {error, Error}
%% @end
%%--------------------------------------------------------------------
start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Initializes the server
%%
%% @spec init(Args) -> {ok, State} |
%%                     {ok, State, Timeout} |
%%                     ignore |
%%                     {stop, Reason}
%% @end
%%--------------------------------------------------------------------
init([]) ->
    io:format("server started~n"),
    start(),
    {ok, #state{}}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling call messages
%%
%% @spec handle_call(Request, From, State) ->
%%                                   {reply, Reply, State} |
%%                                   {reply, Reply, State, Timeout} |
%%                                   {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, Reply, State} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling cast messages
%%
%% @spec handle_cast(Msg, State) -> {noreply, State} |
%%                                  {noreply, State, Timeout} |
%%                                  {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_cast(_Msg, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling all non call/cast messages
%%
%% @spec handle_info(Info, State) -> {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_info(_Info, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any
%% necessary cleaning up. When it returns, the gen_server terminates
%% with Reason. The return value is ignored.
%%
%% @spec terminate(Reason, State) -> void()
%% @end
%%--------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Convert process state when code is changed
%%
%% @spec code_change(OldVsn, State, Extra) -> {ok, NewState}
%% @end
%%--------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================


start() ->
    spawn(fun() -> 
		  start_parallel_server(3000),
		  %% now go to sleep - otherwise the 
		  %% listening socket will be closed
		  lib_misc:sleep(infinity)
	  end).

start_parallel_server(Port) ->
    {ok, Listen} = gen_tcp:listen(Port, [binary, {packet, 4},
					 {reuseaddr, true},
					 {active, true}]),
    MessageServer = spawn(fun() -> something_useful() end),
    spawn(fun() -> par_connect(Listen, MessageServer) end).

par_connect(Listen, MessageServer) ->
    {ok, Socket} = gen_tcp:accept(Listen),
    spawn(fun() -> par_connect(Listen, MessageServer) end),
    inet:setopts(Socket, [{packet,4},binary, {nodelay,true},{active, true}]),
    io:format("connecting ~p~n", [Listen]),
    loop(Socket).


loop(Socket) ->
    receive
	{tcp, Socket, Bin} ->
	    io:format("Server received binary = ~p~n" ,[Bin]),
	    Command = binary_to_term(Bin),
	    io:format("Server (unpacked) ~p~n" ,[Command]),
	    Reply = handle_command(Command),
	    io:format("Server replying = ~p~n" ,[Reply]),
	    ok = gen_tcp:send(Socket, term_to_binary(Reply)),
	    case Reply of
		death ->
		    io:format("And now server is closing everything"),
		    gen_tcp:close(Socket);
		_Default ->
%%		   ok = gen_tcp:send(Socket, term_to_binary(default_handler)),
		    loop(Socket)
	    end;

	    
	{tcp_closed, Socket} ->
	    io:format("Server socket closed~n" );
	Any ->
	    io:format("Server received something funny~p~n", [Any])
end.

handle_command(get) ->
    { Xml, _Rest } = xmerl_scan:string("<xml><doc><test>4</test> <test>3</test></doc></xml>"),
    [Four, _Three] = xmerl_xpath:string("//test/text()", Xml),
    {_, _, _, _, _, Resp} = Four,
    Resp;

handle_command(who) ->
    io:format("rip dennis~n"),
    rip_dennis;

handle_command(i_am_devil) ->
    redirect;

handle_command(death_confirmed)->
    death;

handle_command(_) ->
    unknown.



something_useful() ->
    io:format("something happening handerl ~n"),
    
    receive
	{_From, _Smth} ->
	    io:format("inside handler receive~n"),
	    something_useful();
	_Any ->
	    io:format("received something unknown~n"),
	    something_useful()
%%    after 3000 ->
%%	    io:format("looping again"),
%%	    songs()
    end.
