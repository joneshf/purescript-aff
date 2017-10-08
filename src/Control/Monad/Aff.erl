-module(control_monad_aff@foreign).
-behavior(gen_server).
-export(['_bind'/2, '_delay'/0, '_catchError'/2, '_fork'/2, '_killAll'/0]).
-export(['_liftEff'/1, '_makeFiber'/0, '_makeSupervisedFiber'/0, '_map'/2]).
-export(['_parAffAlt'/2, '_parAffApply'/2, '_parAffMap'/2, '_pure'/1]).
-export(['_sequential'/1, '_throwError'/1, generalBracket/3, makeAff/1]).

-export([handle_call/3, handle_cast/2, init/1]).

'_bind'(Aff, F) ->
    {ok, NewAff} = gen_server:start(?MODULE, {bind, Aff, F}, []),
    NewAff.

'_delay'() -> '_delay'.

'_catchError'(Aff, CB) ->
    {ok, NewAff} = gen_server:start(?MODULE, {catch_, Aff, CB}, []),
    NewAff.

'_fork'(_X, _Y) -> '_fork'.

'_killAll'() -> '_killAll'.

'_liftEff'(Eff) ->
    {ok, Aff} = gen_server:start(?MODULE, {lift, Eff}, []),
    Aff.

'_makeFiber'() ->
    fun(Util, Aff) ->
        fun() ->
            #{ run => fun() -> gen_server:call(Aff, {run, Util}), unit end
             }
        end
    end.

'_makeSupervisedFiber'() -> '_makeSupervisedFiber'.

'_map'(F, Aff) -> gen_server:call(Aff, {map, F}).

'_parAffAlt'(_X, _Y) -> '_parAffAlt'.

'_parAffApply'(_X, _Y) -> '_parAffApply'.

'_parAffMap'(_X, _Y) -> '_parAffMap'.

'_pure'(Value) ->
    {ok, Aff} = gen_server:start(?MODULE, {pure, Value}, []),
    Aff.

'_sequential'(_X) -> '_sequential'.

'_throwError'(_X) -> '_throwError'.

generalBracket(_X, _Y, _Z) -> generalBracket.

makeAff(_X) -> makeAff.

%% gen_server required callbacks.

init({bind, Aff, F}) -> {ok, {bind, Aff, F}};
init({catch_, Aff, CB}) -> {ok, {catch_, Aff, CB}};
init({lift, Eff}) -> {ok, {lift, Eff}};
init({pure, Value}) -> {ok, {pure, Value}}.

handle_call({map, G}, _From, State) ->
    {ok, Aff} = gen_server:start(?MODULE, handle_map(G, State), []),
    {reply, Aff, State};
handle_call({run, Util}, _From, State) -> {reply, handle_run(Util, State), State}.

%% default callbacks.

handle_cast(_Request, State) -> {noreply, State}.

%% helpers

handle_map(G, {bind, Aff, F}) ->
    MappedF = fun(X) -> gen_server:call(F(X), {map, G}) end,
    {bind, Aff, MappedF};
handle_map(F, {catch_, Aff, CB}) ->
    MappedAff = gen_server:call(Aff, {map, F}),
    MappedCB = fun(Error) -> gen_server:call(CB(Error), {map, F}) end,
    {catch_, MappedAff, MappedCB};
handle_map(F, {lift, Eff}) -> {lift, fun() -> F(Eff()) end};
handle_map(F, {pure, Value}) -> {pure, F(Value)}.

handle_run(Util, {bind, Aff, F}) ->
    Value = gen_server:call(Aff, {run, Util}),
    gen_server:call(F(Value), {run, Util});
handle_run(Util, {catch_, Aff, CB}) ->
    try gen_server:call(Aff, {run, Util})
    catch error:Error -> gen_server:call(CB(Error), {run, Util})
    end;
handle_run(_Util, {lift, Eff}) -> Eff();
handle_run(_Util, {pure, Value}) -> Value.
