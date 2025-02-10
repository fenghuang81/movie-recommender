
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
        readMovies(movieFile);
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
            String title;

            if (parts.length < 4)
                throw new NumberFormatException("Error: Invalid line structure: " + line);

            // parse the ID
            int movieID = Integer.parseInt(parts[0]);

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

    public void generateRecommendations() {
        // Regarder tous les films
        for (Movie movie : movies) {
            if (userU.viewedMovie(movie) && numLikes(movie) >= K) {
                int score = 0;
                int numMoviesLiked = 0;

                for (User user : users) {
                    if (user != userU && user.likedMovie(movie)) {
                        score += jaccard(userU, user);
                        numMoviesLiked++;
                    }
                }
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

    // public float jaccard(User user1, User user2) {
    //     int bothLiked;
    //     int bothDisliked;

    //     for (Movie movie : user1.l) {

    //     }
    // }

    public static void main(String[] args) {

        try {

            RecommendationEngine rec = new RecommendationEngine(Integer.parseInt(args[0]), args[1], args[2]);

            // just printing few movies
            for (int i = 0; i < 20; i++) {
                System.out.println(rec.getMovie(i).toString());
            }

        } catch (Exception e) {
            System.err.println("Error reading the file: " + e.getMessage());
        }
    }
}
