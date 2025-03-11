// Project CSI2120/CSI2520
// Winter 2025
// Robert Laganiere, uottawa.ca

package main

import (
	"encoding/csv"
	"fmt"
	"log"
	"os"
	"runtime"
	"sort"
	"strconv"
	"sync"
	"time"
)

// K
const minimumLiked int = 10

// movies with rating greater or equal are considered 'liked'
const iLiked float64 = 3.5

// N
const numBestRecs int = 20

// Define the Recommendation type
type Recommendation struct {
	userID     int     // recommendation for this user
	movieID    int     // recommended movie ID
	movieTitle string  // recommended movie title
	score      float32 // probability that the user will like this movie
	nUsers     int     // number of users who likes this movie
}

// get the probability that this user will like this movie
func (r Recommendation) getProbLike() float32 {
	return r.score / (float32)(r.nUsers)
}

// Define the User type
// and its list of liked items
type User struct {
	userID   int
	liked    []int // list of movies with ratings >= iLiked
	notLiked []int // list of movies with ratings < iLiked
}

func (u User) getUserID() int {
	return u.userID
}

func (u *User) setUserID(id int) {
	u.userID = id
}

func (u *User) addLiked(id int) {
	u.liked = append(u.liked, id)
}

func (u *User) addNotLiked(id int) {
	u.notLiked = append(u.notLiked, id)
}

// Function to read the ratings CSV file and process each row.
// The output is a map in which user ID is used as key
func readRatingsCSV(fileName string) (map[int]*User, error) {
	// Open the CSV file.
	file, err := os.Open(fileName)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	// Create a CSV reader.
	reader := csv.NewReader(file)

	// Read first line and skip
	_, err = reader.Read()
	if err != nil {
		return nil, err
	}

	// creates the map
	users := make(map[int]*User, 1000)

	// Read all records from the CSV.
	records, err := reader.ReadAll()
	if err != nil {
		return nil, err
	}

	// Iterate over each record and convert the strings into integers or float.
	for _, record := range records {
		if len(record) != 4 {
			return nil, fmt.Errorf("each line must contain exactly 4 integers, but found %d", len(record))
		}

		// Parse user ID integer
		uID, err := strconv.Atoi(record[0])
		if err != nil {
			return nil, fmt.Errorf("error converting '%s' to userID integer: %v", record[0], err)
		}

		// Parse movie ID integer
		mID, err := strconv.Atoi(record[1])
		if err != nil {
			return nil, fmt.Errorf("error converting '%s' to movieID integer: %v", record[1], err)
		}

		// Parse rating float
		r, err := strconv.ParseFloat(record[2], 64)
		if err != nil {

			return nil, fmt.Errorf("error converting '%s' to rating: %v", record[2], err)
		}

		// checks if it is a new user
		u, ok := users[uID]
		if !ok {

			u = &User{uID, nil, nil}
			users[uID] = u
		}

		// ad movie in user list
		if r >= iLiked {

			u.addLiked(mID)

		} else {

			u.addNotLiked(mID)
		}
	}

	return users, nil
}

// Function to read the movies CSV file and process each row.
// The output is a map in which user ID is used as key
func readMoviesCSV(fileName string) (map[int]string, error) {
	// Open the CSV file.
	file, err := os.Open(fileName)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	// Create a CSV reader.
	reader := csv.NewReader(file)

	// Read first line and skip
	_, err = reader.Read()
	if err != nil {
		return nil, err
	}

	// creates the map
	movies := make(map[int]string, 1000)

	// Read all records from the CSV.
	records, err := reader.ReadAll()
	if err != nil {
		return nil, err
	}

	// Iterate over each record and convert the strings into integers or float.
	for _, record := range records {
		if len(record) != 3 {
			return nil, fmt.Errorf("each line must contain exactly 3 entries, but found %d", len(record))
		}

		// Parse movie ID integer
		mID, err := strconv.Atoi(record[0])
		if err != nil {
			return nil, fmt.Errorf("error converting '%s' to movieID integer: %v", record[1], err)
		}

		// record 1 is the title
		movies[mID] = record[1]
	}

	return movies, nil
}

// checks if value is in the set
func member(value int, set []int) bool {

	for _, v := range set {
		if value == v {

			return true
		}
	}

	return false
}

// generator producing Recommendation instances from movie list
func generateMovieRec(wg *sync.WaitGroup, stop <-chan bool, userID int, titles map[int]string) <-chan Recommendation {

	outputStream := make(chan Recommendation)

	go func() {
		defer func() {
			wg.Done()
		}()
		defer close(outputStream)
		// defer fmt.Println("\nFin de generateMovieRec...")
		for k, v := range titles {
			select {
			case <-stop:
				return
			case outputStream <- Recommendation{userID, k, v, 0.0, 0}:
			}
		}
	}()

	return outputStream
}

func notSeenByUser(rec Recommendation, users map[int]*User) bool {

	// S'il a aimé
	for _, likedID := range users[rec.userID].liked {
		if likedID == rec.movieID {
			return false
		}
	}

	// S'il n'a pas aimé
	for _, dislikedID := range users[rec.userID].notLiked {
		if dislikedID == rec.movieID {
			return false
		}
	}

	// S'il n'a pas vu le film
	return true
}

func likedByMinimum(rec Recommendation, users map[int]*User) bool {

	count := 0

	// Vérifie les utilisateurs jusqu'à ce que 20 aimés sont trouvés
	for _, user := range users {
		for _, likedID := range user.liked {
			if likedID == rec.movieID {
				count++
				if count >= minimumLiked {
					return true
				}
			}
		}
	}

	// Renvoie false si < 20 sont trouvés
	return false
}

func filter(
	wg *sync.WaitGroup,
	stop <-chan bool,
	inputStream <-chan Recommendation,
	filter func(Recommendation, map[int]*User) bool,
	users map[int]*User,
) <-chan Recommendation {

	outputStream := make(chan Recommendation)

	go func() {
		defer wg.Done()
		defer close(outputStream)

		for rec := range inputStream {

			// Saute l'iteration si bloqué par le filtre
			if !filter(rec, users) {
				continue
			}

			select {
			case <-stop:
				return
			case outputStream <- rec:
			}
		}
	}()

	return outputStream
}

func jaccard(user1 *User, user2 *User) float32 {
	var bothLiked float32 = 0
	var bothDisliked float32 = 0
	moviesViewed := make(map[int]bool)

	// Obtient le nombre de films que les deux ont aimés
	for _, movieID := range user1.liked {
		moviesViewed[movieID] = true // Ajoute dans les films regardés
		if member(movieID, user2.liked) {
			bothLiked++
		}
	}

	// Obtient le nombre de films que les deux n'ont pas aimés
	for _, movieID := range user1.notLiked {
		moviesViewed[movieID] = true // Ajoute dans les films regardés
		if member(movieID, user2.notLiked) {
			bothDisliked++
		}
	}

	for _, movieID := range user2.liked {
		moviesViewed[movieID] = true
	}

	for _, movieID := range user2.notLiked {
		moviesViewed[movieID] = true
	}

	return (bothLiked + bothDisliked) / float32(len(moviesViewed))
}

func computeScoreStage(
	wg *sync.WaitGroup,
	stop <-chan bool,
	inputStream <-chan Recommendation,
	users map[int]*User,
) <-chan Recommendation {

	outputStream := make(chan Recommendation)

	go func() {
		defer wg.Done()
		defer close(outputStream)

		for rec := range inputStream {

			movieID := rec.movieID

			// Parcourt chaque utilisateur
			for _, user := range users {

				// Si l'utilisateur a aimé le film
				if user.getUserID() != rec.userID && member(movieID, user.liked) {
					// Calcule S(U, V)
					rec.score += jaccard(users[rec.userID], user)
					rec.nUsers++
				}
			}

			// P(U, M)
			rec.score = rec.getProbLike()

			select {
			case <-stop:
				return
			case outputStream <- rec:
			}
		}
	}()

	return outputStream
}

func mergeAndGenerateBestRecs(
	wg *sync.WaitGroup,
	stop <-chan bool,
	channels []<-chan Recommendation,
) <-chan Recommendation {

	outputStream := make(chan Recommendation)
	recSlice := []Recommendation{}
	var muxGroup sync.WaitGroup

	// Ajout au slice
	muxGroup.Add(len(channels))
	for _, ch := range channels {
		go func() {
			defer muxGroup.Done()

			for rec := range ch {
				recSlice = append(recSlice, rec)
			}
		}()
	}

	go func() {
		defer wg.Done()
		defer close(outputStream)

		// Attend le transfert dans le slice
		muxGroup.Wait()

		// Trie le slice avec le P(U, M)
		sort.Slice(recSlice, func(i, j int) bool {
			return recSlice[i].score > recSlice[j].score
		})

		for _, rec := range recSlice {
			select {
			case <-stop:
				return
			case outputStream <- rec:
			}
		}
	}()

	return outputStream
}

func main() {

	fmt.Println("Number of CPUs:", runtime.NumCPU()) // just curious

	// user to be considered
	var currentUser int
	fmt.Println("Recommendations for which user? ")
	fmt.Scanf("%d", &currentUser)

	// Call the function to read and parse the movies CSV file.
	titles, err := readMoviesCSV("movies1.csv")
	if err != nil {
		log.Fatal(err)
	}

	// Call the function to read and parse the ratings CSV file.
	ratings, err := readRatingsCSV("ratings1.csv")
	if err != nil {
		log.Fatal(err)
	}

	// synchronization
	stop := make(chan bool)
	var wg sync.WaitGroup
	wg.Add(6)

	start := time.Now() // chrono

	// Toutes les recommandations de films
	recChannel := generateMovieRec(&wg, stop, currentUser, titles)

	// The sequence of filters
	// Supprime les films déjà regardé
	recChannel = filter(&wg, stop, recChannel, notSeenByUser, ratings)
	// Supprime les films qui n'ont pas été regardés par au moins K personnes
	recChannel = filter(&wg, stop, recChannel, likedByMinimum, ratings)

	// Fan out
	numStreams := 2
	computeStreams := make([]<-chan Recommendation, numStreams)
	for i := range numStreams {
		computeStreams[i] = computeScoreStage(&wg, stop, recChannel, ratings)
	}

	// Fan in
	recChannel = mergeAndGenerateBestRecs(&wg, stop, computeStreams)

	recommendations := [numBestRecs]Recommendation{}
	for i := range recommendations {
		recommendations[i] = <-recChannel
	}

	close(stop) // stop all threads
	wg.Wait()

	end := time.Now()

	for _, rec := range recommendations {
		fmt.Println(rec)
	}

	fmt.Println(ratings[currentUser])

	fmt.Printf("\n\nExecution time: %s", end.Sub(start))
}
