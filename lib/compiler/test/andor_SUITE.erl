%%
%% %CopyrightBegin%
%% 
%% Copyright Ericsson AB 2001-2009. All Rights Reserved.
%% 
%% The contents of this file are subject to the Erlang Public License,
%% Version 1.1, (the "License"); you may not use this file except in
%% compliance with the License. You should have received a copy of the
%% Erlang Public License along with this software. If not, it can be
%% retrieved online at http://www.erlang.org/.
%% 
%% Software distributed under the License is distributed on an "AS IS"
%% basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
%% the License for the specific language governing rights and limitations
%% under the License.
%% 
%% %CopyrightEnd%
%%
-module(andor_SUITE).

-export([all/1,
	 t_case/1,t_and_or/1,t_andalso/1,t_orelse/1,inside/1,overlap/1,
	 combined/1,in_case/1,before_and_inside_if/1]).
	 
-include("test_server.hrl").

all(suite) ->
    test_lib:recompile(?MODULE),
    [t_case,t_and_or,t_andalso,t_orelse,inside,overlap,combined,in_case,
     before_and_inside_if].

t_case(Config) when is_list(Config) ->
    %% We test boolean cases almost but not quite like cases
    %% generated by andalso/orelse.
    ?line less = t_case_a(1, 2),
    ?line not_less = t_case_a(2, 2),
    ?line {'EXIT',{{case_clause,false},_}} = (catch t_case_b({x,y,z}, 2)),
    ?line {'EXIT',{{case_clause,true},_}} = (catch t_case_b(a, a)),
    ?line eq = t_case_c(a, a),
    ?line ne = t_case_c(42, []),
    ?line t = t_case_d(x, x, true),
    ?line f = t_case_d(x, x, false),
    ?line f = t_case_d(x, y, true),
    ?line {'EXIT',{badarg,_}} = (catch t_case_d(x, y, blurf)),
    ?line true = (catch t_case_e({a,b}, {a,b})),
    ?line false = (catch t_case_e({a,b}, 42)),

    ?line true = t_case_xy(42, 100, 700),
    ?line true = t_case_xy(42, 100, whatever),
    ?line false = t_case_xy(42, wrong, 700),
    ?line false = t_case_xy(42, wrong, whatever),

    ?line true = t_case_xy(0, whatever, 700),
    ?line true = t_case_xy(0, 100, 700),
    ?line false = t_case_xy(0, whatever, wrong),
    ?line false = t_case_xy(0, 100, wrong),

    ok.

t_case_a(A, B) ->
    case A < B of
	[_|_] -> ok;
	true -> less;
	false -> not_less;
	{a,b,c} -> ok;
	_Var -> ok
    end.

t_case_b(A, B) ->
    case A =:= B of
	blurf -> ok
    end.

t_case_c(A, B) ->
    case not(A =:= B) of
	true -> ne;
	false -> eq
    end.

t_case_d(A, B, X) ->
    case (A =:= B) and X of
	true -> t;
	false -> f
    end.

t_case_e(A, B) ->
    case A =:= B of
	Bool when is_tuple(A) -> id(Bool)
    end.

t_case_xy(X, Y, Z) ->
    Res = t_case_x(X, Y, Z),
    Res = t_case_y(X, Y, Z).

t_case_x(X, Y, Z) ->
    case abs(X) =:= 42 of
	true ->
	    Y =:= 100;
	false ->
	    Z =:= 700
    end.

t_case_y(X, Y, Z) ->
    case abs(X) =:= 42 of
	false ->
	    Z =:= 700;
	true ->
	    Y =:= 100
    end.

t_and_or(Config) when is_list(Config) ->
    ?line true = true and true,
    ?line false = true and false,
    ?line false = false and true,
    ?line false = false and false,

    ?line true = id(true) and true,
    ?line false = id(true) and false,
    ?line false = id(false) and true,
    ?line false = id(false) and false,

    ?line true = true and id(true),
    ?line false = true and id(false),
    ?line false = false and id(true),
    ?line false = false and id(false),

    ?line true = true or true,
    ?line true = true or false,
    ?line true = false or true,
    ?line false = false or false,

    ?line true = id(true) or true,
    ?line true = id(true) or false,
    ?line true = id(false) or true,
    ?line false = id(false) or false,

    ?line true = true or id(true),
    ?line true = true or id(false),
    ?line true = false or id(true),
    ?line false = false or id(false),

   ok.

t_andalso(Config) when is_list(Config) ->
    Bs = [true,false],
    Ps = [{X,Y} || X <- Bs, Y <- Bs],
    lists:foreach(fun (P) -> t_andalso_1(P) end, Ps),

    ?line true = true andalso true,
    ?line false = true andalso false,
    ?line false = false andalso true,
    ?line false = false andalso false,

    ?line false = false andalso glurf,
    ?line false = false andalso exit(exit_now),

    ?line true = not id(false) andalso not id(false),
    ?line false = not id(false) andalso not id(true),
    ?line false = not id(true) andalso not id(false),
    ?line false = not id(true) andalso not id(true),

    ?line {'EXIT',{badarg,_}} = (catch not id(glurf) andalso id(true)),
    ?line {'EXIT',{badarg,_}} = (catch not id(false) andalso not id(glurf)),
    ?line false = id(false) andalso not id(glurf),
    ?line false = false andalso not id(glurf),

    ok.

t_orelse(Config) when is_list(Config) ->
    Bs = [true,false],
    Ps = [{X,Y} || X <- Bs, Y <- Bs],
    lists:foreach(fun (P) -> t_orelse_1(P) end, Ps),
    
    ?line true = true orelse true,
    ?line true = true orelse false,
    ?line true = false orelse true,
    ?line false = false orelse false,

    ?line true = true orelse glurf,
    ?line true = true orelse exit(exit_now),

    ?line true = not id(false) orelse not id(false),
    ?line true = not id(false) orelse not id(true),
    ?line true = not id(true) orelse not id(false),
    ?line false = not id(true) orelse not id(true),

    ?line {'EXIT',{badarg,_}} = (catch not id(glurf) orelse id(true)),
    ?line {'EXIT',{badarg,_}} = (catch not id(true) orelse not id(glurf)),
    ?line true = id(true) orelse not id(glurf),
    ?line true = true orelse not id(glurf),

    ok.

t_andalso_1({X,Y}) ->
    io:fwrite("~w andalso ~w: ",[X,Y]),
    V1 = echo(X) andalso echo(Y),
    V1 = if
	     X andalso Y -> true;
	     true -> false
	 end,
    check(V1, X and Y).

t_orelse_1({X,Y}) ->
    io:fwrite("~w orelse ~w: ",[X,Y]),
    V1 = echo(X) orelse echo(Y),
    V1 = if
	     X orelse Y -> true;
	     true -> false
	 end,
    check(V1, X or Y).

inside(Config) when is_list(Config) ->
    ?line true = inside(-8, 1),
    ?line false = inside(-53.5, -879798),
    ?line false = inside(1.0, -879),
    ?line false = inside(59, -879),
    ?line false = inside(-11, 1.0),
    ?line false = inside(100, 0.2),
    ?line false = inside(100, 1.2),
    ?line false = inside(-53.5, 4),
    ?line false = inside(1.0, 5.3),
    ?line false = inside(59, 879),
    ok.

inside(Xm, Ym) ->
    X = -10.0,
    Y = -2.0,
    W = 20.0,
    H = 4.0,
    Res = inside(Xm, Ym, X, Y, W, H),
    Res = if
	      X =< Xm andalso Xm < X+W andalso Y =< Ym andalso Ym < Y+H -> true;
	      true -> false
	  end,
    case not id(Res) of
	Outside ->
	    Outside = if
			  not(X =< Xm andalso Xm < X+W andalso Y =< Ym andalso Ym < Y+H) -> true;
			  true -> false
		      end
    end,
    {Res,Xm,Ym,X,Y,W,H} = inside_guard(Xm, Ym, X, Y, W, H),
    io:format("~p =< ~p andalso ~p < ~p andalso ~p =< ~p andalso ~p < ~p ==> ~p",
	      [X,Xm,Xm,X+W,Y,Ym,Ym,Y+H,Res]),
    Res.

inside(Xm, Ym, X, Y, W, H) ->
    X =< Xm andalso Xm < X+W andalso Y =< Ym andalso Ym < Y+H.

inside_guard(Xm, Ym, X, Y, W, H) when X =< Xm andalso Xm < X+W
				      andalso Y =< Ym andalso Ym < Y+H ->
    {true,Xm,Ym,X,Y,W,H};
inside_guard(Xm, Ym, X, Y, W, H) ->
    {false,Xm,Ym,X,Y,W,H}.

overlap(Config) when is_list(Config) ->
    ?line true = overlap(7.0, 2.0, 8.0, 0.5),
    ?line true = overlap(7.0, 2.0, 8.0, 2.5),
    ?line true = overlap(7.0, 2.0, 5.3, 2),
    ?line true = overlap(7.0, 2.0, 0.0, 100.0),

    ?line false = overlap(-1, 2, -35, 0.5),
    ?line false = overlap(-1, 2, 777, 0.5),
    ?line false = overlap(-1, 2, 2, 10),
    ?line false = overlap(2, 10, 12, 55.3),
    ok.

overlap(Pos1, Len1, Pos2, Len2) ->
    Res = case Pos1 of
	      Pos1 when (Pos2 =< Pos1 andalso Pos1 < Pos2+Len2)
			orelse (Pos1 =< Pos2 andalso Pos2 < Pos1+Len1) ->
		  true;
	      Pos1 -> false
	  end,
    Res = (Pos2 =< Pos1 andalso Pos1 < Pos2+Len2)
	orelse (Pos1 =< Pos2 andalso Pos2 < Pos1+Len1),
    Res = case Pos1 of
	      Pos1 when (Pos2 =< Pos1 andalso Pos1 < Pos2+Len2)
			orelse (Pos1 =< Pos2 andalso Pos2 < Pos1+Len1) ->
		  true;
	      Pos1 -> false
	  end,
    id(Res).


-define(COMB(A,B,C), (A andalso B orelse C)).

combined(Config) when is_list(Config) ->
    ?line false = comb(false, false, false),
    ?line true = comb(false, false, true),
    ?line false = comb(false, true, false),
    ?line true = comb(false, true, true),

    ?line false = comb(true, false, false),
    ?line true = comb(true, true, false),
    ?line true = comb(true, false, true),
    ?line true = comb(true, true, true),

    ?line false = comb(false, blurf, false),
    ?line true = comb(false, blurf, true),
    ?line true = comb(true, true, blurf),

    ?line false = ?COMB(false, false, false),
    ?line true = ?COMB(false, false, true),
    ?line false = ?COMB(false, true, false),
    ?line true = ?COMB(false, true, true),

    ?line false = ?COMB(true, false, false),
    ?line true = ?COMB(true, true, false),
    ?line true = ?COMB(true, false, true),
    ?line true = ?COMB(true, true, true),

    ?line false = ?COMB(false, blurf, false),
    ?line true = ?COMB(false, blurf, true),
    ?line true = ?COMB(true, true, blurf),

    ok.
-undef(COMB).

comb(A, B, C) ->
    Res = A andalso B orelse C,
    Res = if
	      A andalso B orelse C -> true;
	      true -> false
	  end,
    NotRes = if
		 not(A andalso B orelse C) -> true;
		 true -> false
	     end,
    NotRes = id(not Res),
    Res = A andalso B orelse C,
    Res = if
	      A andalso B orelse C -> true;
	      true -> false
	  end,
    NotRes = id(not Res),
    Res = if
	      A andalso B orelse C -> true;
	      true -> false
	  end,
    id(Res).

%% Test that a boolean expression in a case expression is properly
%% optimized (in particular, that the error behaviour is correct).
in_case(Config) when is_list(Config) ->
    ?line edge_rings = in_case_1(1, 1, 1, 1, 1),
    ?line not_loop = in_case_1(0.5, 1, 1, 1, 1),
    ?line loop = in_case_1(0.5, 0.9, 1.1, 1, 4),
    ?line {'EXIT',{badarith,_}} = (catch in_case_1(1, 1, 1, 1, 0)),
    ?line {'EXIT',{badarith,_}} = (catch in_case_1(1, 1, 1, 1, nan)),
    ?line {'EXIT',{badarg,_}} = (catch in_case_1(1, 1, 1, blurf, 1)),
    ?line {'EXIT',{badarith,_}} = (catch in_case_1([nan], 1, 1, 1, 1)),
    ok.

in_case_1(LenUp, LenDw, LenN, Rotation, Count) ->
    Res = in_case_1_body(LenUp, LenDw, LenN, Rotation, Count),
    Res = in_case_1_guard(LenUp, LenDw, LenN, Rotation, Count),
    Res.

in_case_1_body(LenUp, LenDw, LenN, Rotation, Count) ->
    case (LenUp/Count > 0.707) and (LenN/Count > 0.707) and
	(abs(Rotation) > 0.707) of
	true ->
	    edge_rings;
	false ->
	    case (LenUp >= 1) or (LenDw >= 1) or
		(LenN =< 1) or (Count < 4) of
		true ->
		    not_loop;
		false -> 
		    loop
	    end
    end.

in_case_1_guard(LenUp, LenDw, LenN, Rotation, Count) ->
    case (LenUp/Count > 0.707) andalso (LenN/Count > 0.707) andalso
	(abs(Rotation) > 0.707) of
	true -> edge_rings;
	false when LenUp >= 1 orelse LenDw >= 1 orelse
	LenN =< 1 orelse Count < 4 -> not_loop;
	false -> loop
    end.

before_and_inside_if(Config) when is_list(Config) ->
    ?line no = before_and_inside_if([a], [b], delete),
    ?line no = before_and_inside_if([a], [b], x),
    ?line no = before_and_inside_if([a], [], delete),
    ?line no = before_and_inside_if([a], [], x),
    ?line no = before_and_inside_if([], [], delete),
    ?line yes = before_and_inside_if([], [], x),
    ?line yes = before_and_inside_if([], [b], delete),
    ?line yes = before_and_inside_if([], [b], x),

    ?line {ch1,ch2} = before_and_inside_if_2([a], [b], blah),
    ?line {ch1,ch2} = before_and_inside_if_2([a], [b], xx),
    ?line {ch1,ch2} = before_and_inside_if_2([a], [], blah),
    ?line {ch1,ch2} = before_and_inside_if_2([a], [], xx),
    ?line {no,no} = before_and_inside_if_2([], [b], blah),
    ?line {no,no} = before_and_inside_if_2([], [b], xx),
    ?line {ch1,no} = before_and_inside_if_2([], [], blah),
    ?line {no,ch2} = before_and_inside_if_2([], [], xx),
    ok.

%% Thanks to Simon Cornish and Kostis Sagonas.
%% Used to crash beam_bool.
before_and_inside_if(XDo1, XDo2, Do3) ->
    Do1 = (XDo1 =/= []),
    Do2 = (XDo2 =/= []),
    if
	%% This expression occurs in a try/catch (protected)
	%% block, which cannot refer to variables outside of
	%% the block that are boolean expressions.
	Do1 =:= true;
	Do1 =:= false, Do2 =:= false, Do3 =:= delete ->
	    no;
       true ->
	    yes
    end.

%% Thanks to Simon Cornish.
%% Used to generate code that would not set {y,0} on
%% all paths before its use (and therefore fail
%% validation by the beam_validator).
before_and_inside_if_2(XDo1, XDo2, Do3) ->
    Do1    = (XDo1 =/= []),
    Do2    = (XDo2 =/= []),
    CH1 = if Do1 == true;
	     Do1 == false,Do2==false,Do3 == blah ->
		  ch1;
	     true ->
		  no
	  end,
    CH2 = if Do1 == true;
	     Do1 == false,Do2==false,Do3 == xx ->
		  ch2;
	     true ->
		  no
	  end,
    {CH1,CH2}.

%% Utilities.

check(V1, V0) ->
    if V1 /= V0 ->
	    io:fwrite("error: ~w.\n", [V1]),
	    ?t:fail();
       true ->
	    io:fwrite("ok: ~w.\n", [V1])
    end.

echo(X) ->	    
    io:fwrite("eval(~w); ",[X]),
    X.

id(I) -> I.
