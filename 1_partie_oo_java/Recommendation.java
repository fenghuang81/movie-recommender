/*
 * Projet CSI2120/CSI2520
 * Hiver 2025
 * Nom : Steven Wu
 * Numéro d'étudiant : 300370421
 */

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

    public User getUser() {
        return user;
    }

    @Override
    public String toString() {
        return String.format("%s at %.4f [ %d]", movie.getTitle(), score, nUsers);
    }

    @Override
    public int compareTo(Recommendation anotherRecommendation) {
        return Float.compare(anotherRecommendation.score, this.score);
    }
}
