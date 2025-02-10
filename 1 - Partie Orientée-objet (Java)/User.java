import java.util.ArrayList;
import java.util.List;

public class User {

    private int userID;
    private List<Movie> likedMovies;
    private List<Movie> dislikedMovies;

    public User(int userId) {
        this.userID = userId;
        likedMovies = new ArrayList<>();
        dislikedMovies = new ArrayList<>();
    }

    public int getUserID() {
        return userID;
    }

    public void addLikedMovie(Movie movie) {
        likedMovies.add(movie);
    }

    public boolean likedMovie(Movie movie) {
        return likedMovies.contains(movie);
    }

    public List<Movie> getLikedMovies() {
        return likedMovies;
    }

    public void addDislikedMovie(Movie movie) {
        dislikedMovies.add(movie);
    }

    public boolean dislikedMovie(Movie movie) {
        return dislikedMovies.contains(movie);
    }

    public List<Movie> getDislikedMovies() {
        return dislikedMovies;
    }

    public boolean viewedMovie(Movie movie) {
        return likedMovie(movie) || dislikedMovie(movie);
    }

}
