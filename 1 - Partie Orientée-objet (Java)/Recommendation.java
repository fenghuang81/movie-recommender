public class Recommendation implements Comparable<Recommendation> {
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

    @Override
    public String toString() {
        return String.format("%s at %f [ %d]", movie.getTitle(), score, nUsers);
    }

    @Override
    public int compareTo(Recommendation anotherRecommendation) {
        return Float.compare(this.score, anotherRecommendation.score);
    }
}
