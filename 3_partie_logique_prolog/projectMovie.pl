:- dynamic user/3, movie/2.
% K
min_liked(10).
% R
liked_th(3.5).
% N
number_of_rec(20).

read_users(Filename) :-
    csv_read_file(Filename, Data), assert_users(Data).
assert_users([]).
assert_users([row(U,_,_,_) | Rows]) :- \+number(U),!, assert_users(Rows).
assert_users([row(U,M,Rating,_) | Rows]) :- number(U),\+user(U,_,_), liked_th(R), Rating>=R,!,assert(user(U,[M],[])), assert_users(Rows).
assert_users([row(U,M,Rating,_) | Rows]) :- number(U),\+user(U,_,_), liked_th(R), Rating<R,!,assert(user(U,[],[M])), assert_users(Rows).
assert_users([row(U,M,Rating,_) | Rows]) :- number(U), liked_th(R), Rating>=R, !, retract(user(U,Liked,NotLiked)), assert(user(U,[M|Liked],NotLiked)), assert_users(Rows).
assert_users([row(U,M,Rating,_) | Rows]) :- number(U), liked_th(R), Rating<R, !, retract(user(U,Liked,NotLiked)), assert(user(U,Liked,[M|NotLiked])), assert_users(Rows).

read_movies(Filename) :-
    csv_read_file(Filename, Rows), assert_movies(Rows).

assert_movies([]).
assert_movies([row(M,_,_) | Rows]) :- \+number(M),!, assert_movies(Rows).
assert_movies([row(M,Title,_) | Rows]) :- number(M),!, assert(movie(M,Title)), assert_movies(Rows).

display_first_n(_, 0) :- !.
display_first_n([], _) :- !.
display_first_n([H|T], N) :-
    writeln(H), 
    N1 is N - 1,
    display_first_n(T, N1).

% recommendations(User) :- setof(M,L^movie(M,L),Ms),   % generate list of all movie 
%	prob_movies(User,Ms,Rec),   % compute probabilities for all movies 
%	sort(2,@>=,Rec,Rec_Sorted), % sort by descending probabilities
%	number_of_rec(N), display_first_n(Rec_Sorted,N). % display the result

init :- read_users('ratings.csv'), read_movies('movies.csv').
test(1):- similarity(33,88,S1), 291 is truncate(S1 * 10000),similarity(44,55,S2), 138 is truncate(S2 * 10000).
test(2):- prob(44,1080,P1), 122 is truncate(P1 * 10000), prob(44,1050,P2), 0 is truncate(P2).
test(3):- liked(1080, [28, 30, 32, 40, 45, 48, 49, 50], [28, 45, 50]).
test(4):- seen(32, 1080), \+seen(44, 1080).
test(5):- prob_movies(44,[1010, 1050, 1080, 2000],Rs), length(Rs,4), display(Rs).


similarity(User1, User2, Sim) :-
    % Obtient les listes de films aimés et non aimés
    user(User1, User1Likes, User1Dislikes),
    user(User2, User2Likes, User2Dislikes),
    
    % Obtient l'intersection des aimés et non aimés
    intersection(User1Likes, User2Likes, CommonLikes),
    intersection(User1Dislikes, User2Dislikes, CommonDislikes),
    
    % Obtient tous les films regardés
    union(User1Likes, User2Likes, TotalLikes),
    union(User1Dislikes, User2Dislikes, TotalDislikes),
    union(TotalLikes, TotalDislikes, TotalViewed),

    % Obtient les longueurs de tous des ensembles
    length(CommonLikes, NumCommonLikes),
    length(CommonDislikes, NumCommonDislikes),
    length(TotalViewed, NumTotalViewed),

    Sim is (NumCommonLikes + NumCommonDislikes) / NumTotalViewed.