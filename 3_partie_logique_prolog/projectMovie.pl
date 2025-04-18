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

recommendations(User) :-
    setof(M,L^movie(M,L),Ms),   % generate list of all movie 
	prob_movies(User,Ms,Rec),   % compute probabilities for all movies 
	sort(2,@>=,Rec,Rec_Sorted), % sort by descending probabilities
	number_of_rec(N),
    display_first_n(Rec_Sorted,N). % display the result

init :- read_users('ratings.csv'), read_movies('movies.csv').
test(1):- similarity(33,88,S1), 291 is truncate(S1 * 10000),similarity(44,55,S2), 138 is truncate(S2 * 10000).
test(2):- prob(44,1080,P1), 122 is truncate(P1 * 10000), prob(44,1050,P2), 0 is truncate(P2).
test(3):- liked(1080, [28, 30, 32, 40, 45, 48, 49, 50], [28, 45, 50]).
test(4):- seen(32, 1080), \+seen(44, 1080).
test(5):- prob_movies(44,[1010, 1050, 1080, 2000],Rs), length(Rs,4), display(Rs).


% Calcule la similarité entre deux utilisateurs
% User1 : Utilisateur 1 (ID)
% User2 : Utilisateur 2 (ID)
% Sim   : La similarité
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

%  Vérifie si le film atteint le nombre minimum d'aimés
%  Movie: Le film (ID)
meets_min_liked(Movie) :-
    min_liked(K),
    findall(User, (user(User, Liked, _), member(Movie, Liked)), UsersWhoLiked),
    length(UsersWhoLiked, Count),
    Count >= K.
% Calcule la probabilité que l'utilisateur aime un film
% User  : L'utilisateur
% Movie : Le film
% Prob  : La probabilité
prob(_, Movie, 0.0) :-
    \+ meets_min_liked(Movie). % < K
prob(User, Movie, 0.0) :-
    seen(User, Movie). % Déjà vu le film
prob(User, Movie, Prob) :-
    meets_min_liked(Movie), % >= K
    \+ seen(User, Movie), % Pas encore vu le film
    user(User, _, _), % Vérifie que l'utilisateur existe
    findall(
        Sim,
        (
            user(OtherUser, Liked, _), % L'utilisateur actuel
            OtherUser \= User, % Utilisateur différent
            member(Movie, Liked), % Aime le film
            similarity(User, OtherUser, Sim)
        ),
        Similarities
    ),
    sum_list(Similarities, Score),
    length(Similarities, UsersWhoLiked),
    Prob is Score / UsersWhoLiked.

% Génère la paire (MovieTitle, Prob) pour tous les films dans Movies
% User   : L'utilisateur
% Movies : La liste de films
% Recs   : La liste de recommandations
prob_movies(User, Movies, Recs) :-
    findall(
        (Title, Prob),
        (
            member(Movie, Movies),
            movie(Movie, Title),
            prob(User, Movie, Prob)
        ),
        Recs
    ).

% Extrait les utilisateurs dans la listes qui ont aimé le film
% Movie         : Le film
% Users         : La liste d'utilisateurs
% UsersWhoLiked : La liste produit
liked(Movie, Users, UsersWhoLiked) :-
    findall(
        User,
        (
            member(User, Users), % Dans l'entrée
            user(User, Liked, _), % Dans le CSV
            member(Movie, Liked) % Aime le film
        ),
        UsersWhoLiked
    ).

% Determine si l'utilisateur a vu le film
% User  : L'utilisateur
% Movie : Le film
seen(User, Movie) :-
    user(User, Liked, Disliked),
    (
        member(Movie, Liked)
        ;
        member(Movie, Disliked)
    ).