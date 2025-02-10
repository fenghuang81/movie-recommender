public class Recommendation {
    private User user;
    private Movie movie;
    private float score;
    private int nUsers;

    public Recommendation(User user, Movie movie, float score, int nUsers) {
        this.user = user;
        this.movie = movie;
        this.score = score;
        this.nUsers = nUsers;
    }
}
