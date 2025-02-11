
// Project CSI2120/CSI2520
// Winter 2025
// Robert Laganiere, uottawa.ca
import java.io.*;
import java.util.ArrayList;
import java.util.List;

// this is the (incomplete) class that will generate the recommendations for a user
public class RecommendationEngine {

    // Fiabilité minimale
    private static final int K = 10;
    // Aime le film si son évaluation est >= R
    private static final float R = 3.5f;
    // Nombre de recommandation (N)
    private static final int NUM_RECOMMENDATIONS = 20;

    private User userU;
    private List<Movie> movies;
    private List<User> users;
    private List<Recommendation> recommendations;

    // constructs a recommendation engine from files
    public RecommendationEngine(int userID, String movieFile, String ratingsFile)
            throws IOException, NumberFormatException {

        movies = new ArrayList<Movie>();
        users = new ArrayList<User>();
        recommendations = new ArrayList<Recommendation>();

        readMovies(movieFile);
        readRatings(ratingsFile);
        userU = users.get(userID - 1);

        generateRecommendations();
    }

    // Reads the Movie csv file of the MovieLens dataset
    // It populates the list of Movies
    public void readMovies(String csvFile) throws IOException, NumberFormatException {
        String line;
        String delimiter = ","; // Assuming values are separated by commas

        BufferedReader br = new BufferedReader(new FileReader(csvFile));
        // Read each line from the CSV file
        line = br.readLine();

        while ((line = br.readLine()) != null && line.length() > 0) {
            // Split the line into parts using the delimiter
            String[] parts = line.split(delimiter);
            String title;

            // parse the ID
            int movieID = Integer.parseInt(parts[0]);

            if (parts.length < 3)
                throw new NumberFormatException("Error: Invalid line structure: " + line);

            // we assume that the first part is the ID
            // and the last one are genres, the rest is the title
            title = parts[1];
            if (parts.length > 3) {

                for (int i = 2; i < parts.length - 1; i++)
                    title += parts[i];
            }

            movies.add(new Movie(movieID, title));
        }

    }

    public Movie getMovie(int index) {
        return movies.get(index);
    }

    public int getNumberOfMovies() {
        return movies.size();
    }

    public void readRatings(String csvFile) throws IOException, NumberFormatException {
        String line;
        String delimiter = ","; // Assuming values are separated by commas

        BufferedReader br = new BufferedReader(new FileReader(csvFile));
        // Read each line from the CSV file
        line = br.readLine();

        while ((line = br.readLine()) != null && line.length() > 0) {
            // Split the line into parts using the delimiter
            String[] parts = line.split(delimiter);

            // Vérifier le fichier
            if (parts.length < 4)
                throw new NumberFormatException("Error: Invalid line structure: " + line);

            // Convertir les parties en nombres
            int userID = Integer.parseInt(parts[0]);
            int movieID = Integer.parseInt(parts[1]);
            float rating = Float.parseFloat(parts[2]);

            // Créer un nouveau User si le Reader atteint la prochaine ligne
            if (userID > users.size()) {
                users.add(new User(userID));
            }

            
            User currentUser = users.get(userID - 1);
            Movie currentMovie = movies.get(binSearchMovies(movieID));

            // Déterminer si le User aime le film
            if (rating >= R) {
                currentUser.addLikedMovie(currentMovie);
            } else {
                currentUser.addDislikedMovie(currentMovie);
            }

        }

    }

    public void generateRecommendations() {
        // Regarder tous les films
        for (Movie movie : movies) {
            if (userU.viewedMovie(movie) && numLikes(movie) >= K) {
                float score = 0;
                int numMovieLikes = 0;

                for (User user : users) {
                    if (user != userU && user.likedMovie(movie)) {
                        score += jaccard(userU, user);
                        numMovieLikes++;
                    }
                }

                recommendations.add(new Recommendation(userU, movie, score, numMovieLikes));
            }
        }
    }

    public int numLikes(Movie movie) {
        int numLikes = 0;

        for (User user : users) {
            if (user.likedMovie(movie)) {
                numLikes++;
            }
        }

        return numLikes;
    }

    public float jaccard(User user1, User user2) {
        float bothLiked = 0;
        float bothDisliked = 0;

        for (Movie movie : user1.getLikedMovies()) {
            if (user2.likedMovie(movie)) {
                bothLiked++;
            }
        }

        for (Movie movie : user1.getDislikedMovies()) {
            if (user2.dislikedMovie(movie)) {
                bothLiked++;
            }
        }

        return (bothLiked + bothDisliked) / (user1.numMoviesViewed() + user2.numMoviesViewed());
    }

    public int binSearchMovies(int movieID) {
        int left = 0;
        int right = movies.size() - 1;

        while (left <= right) {
            int mid = left + (right - left) / 2;
            Movie movie = movies.get(mid);

            if (movie.getID() < movieID) {
                left = mid + 1;
            } else if (movie.getID() > movieID) {
                right = mid - 1;
            } else if (movie.getID() == movieID) {
                return mid;
            }
        }

        return -1;
    }

    public static void main(String[] args) {

        try {

            RecommendationEngine rec = new RecommendationEngine(Integer.parseInt(args[0]), args[1], args[2]);

            // just printing few movies
            for (int i = 0; i < 20; i++) {
                System.out.println(rec.getMovie(i).toString());
            }

        } catch (Exception e) {
            System.err.println("Error reading the file: " + e.getMessage());
            e.printStackTrace();
        }
    }
}
