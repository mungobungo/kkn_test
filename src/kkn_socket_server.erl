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
		  start_parallel_server(9999),
		  %% now go to sleep - otherwise the 
		  %% listening socket will be closed
		  sleep(infinity)
	  end).

start_parallel_server(Port) ->
    {ok, Listen} = gen_tcp:listen(Port, [binary, {packet, 4},
					 {reuseaddr, true},
					 {active, true}]),
    Kkn_Server = spawn(fun() -> dummyFunc()  end),
    spawn(fun() -> par_connect(Listen, Kkn_Server) end).

dummyFunc() ->
    receive
	_Any -> dummyFunc()
    after 5000 ->
	dummyFunc()
end.


par_connect(Listen, Kkn_Server) ->
    {ok, Socket} = gen_tcp:accept(Listen),
    spawn(fun() -> par_connect(Listen, Kkn_Server) end),
    inet:setopts(Socket, [{packet,0},binary, {nodelay,true},{active, true}]),
    get_request(Socket, Kkn_Server, []).

get_request(Socket, Kkn_Server, L) ->
     receive
	{tcp, Socket, Bin} ->
	    io:format("Server received binary = ~p~n", [Bin]),
	    Str = binary_to_term(Bin),
	    io:format("Server (unpacked) ~p~n",[Str]),
	    Reply = some_reply,
	    io:format("Server replying = ~p~n", [Reply]),
	    gen_tcp:send(Socket, term_to_binary(Reply)),
	    get_request(Socket, Kkn_Server, L);
	{tcp_closed, Socket} ->
	    io:format("Server socket closed~n");

	_Any  ->
	    %% skip this
	    get_request(Socket, Kkn_Server, L)
    end.
sleep(T) ->
    receive
    after T ->
	    sleep(T)
end.
