/*
 * Projet CSI2120/CSI2520
 * Hiver 2025
 * Nom : Steven Wu
 * Numéro d'étudiant : 300370421
 */

public class Movie {

    private int movieID;
    private String title;

    // constructs a movie
    public Movie(int id, String title) {

        movieID = id;
        this.title = title;
    }

    // gets the ID
    public int getID() {

        return movieID;
    }

    // get the movie title
    public String getTitle() {

        return title;
    }

    // string representation
    @Override
    public String toString() {

        return "[" + movieID + "]:" + title;
    }
}