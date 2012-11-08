-module(decouch_reader).

-include_lib("eunit/include/eunit.hrl").

-include("couch_db.hrl").

-export([open/1]).
-export([adh/0, adh/1]).
-export([all_docs/2]).

-export([process_docs/4, process_one/4, process_all_docs/5]).

-export([open_process_all/2]).

open_process_all(DbName, IterFn) ->
    {Db, _} = open(DbName),
    all_docs(Db, IterFn),
    close(Db).

adh() ->
    adh("chef_3f0cbfe0b0c0474d9ac86a8fd51d6a30.couch").

adh(File) ->
    {Db, _} = open(File),
    all_docs(Db, couch_data),
    close(Db).

open(FilePath) ->
    DbName = "foo",
    {ok, Fd} = couch_file:open(FilePath, []),
    {ok, Header} = couch_file:read_header(Fd),
    Db = couch_db_updater:init_db(DbName, FilePath, Fd, Header),
    {Db, Header}.

close(Db) ->
    couch_file:close(Db).


process_docs(_Db, Kv, _Reds, AccIn) ->
    ?debugVal(Kv),
    ?debugVal(Kv#full_doc_info.id),
    RevTree = Kv#full_doc_info.rev_tree,
    ?debugVal(hd(RevTree)),
    ?debugVal(couch_key_tree:get_all_leafs(RevTree)),
%%    ?debugVal(Reds),
    ?debugVal(AccIn),
    {ok, AccIn}.

process_one(Db, Kv, _Reds, AccIn) ->
    ?debugVal(Kv),
    ?debugVal(Kv#full_doc_info.id),
    RevTree = Kv#full_doc_info.rev_tree,
    ?debugVal(RevTree),
    {I, {B, X1, X2}} = hd(RevTree),
    ?debugFmt("~s", [B]),
    ?debugVal(catch binary_to_term(B)),
    ?debugVal(I), ?debugVal(B), ?debugVal(X1), ?debugVal(X2),
    ?debugVal(couch_key_tree:get_all_leafs_full(RevTree)),
    {ok, #doc{body = Body}} = couch_db:open_doc_int(Db, Kv, []),
    ?debugVal(Body),
    ?debugVal(AccIn),
    {stop, AccIn}.

process_all_docs(F, Db, Kv, _Reds, AccIn) ->
    Key = Kv#full_doc_info.id,
    {ok, #doc{body = Body}} = couch_db:open_doc_int(Db, Kv, []),
    AccOut = F(Key, Body, AccIn),
    {ok, AccOut}.

all_docs(Db, TableName) ->
    ets:new(TableName, [set,public,named_table]),
    Limit = 10,
    SkipCount = 0,
    Options = [end_key_gt], 
    FoldAccInit = {Limit, SkipCount, undefined, []},
    Fun = fun(Key, Body, AccIn) ->
                  ets:insert_new(TableName, {Key, Body}),
                  AccIn
          end,
    InFun = fun(KV, Reds, Acc) -> process_all_docs(Fun, Db, KV, Reds, Acc) end,
    Time = timer:tc(
             couch_btree, fold, [Db#db.fulldocinfo_by_id_btree, InFun, FoldAccInit, Options] ),
    ?debugVal(Time),
    ?debugVal(ets:info(TableName)).


