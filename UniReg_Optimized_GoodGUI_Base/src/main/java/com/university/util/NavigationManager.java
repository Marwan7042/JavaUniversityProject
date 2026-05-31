package com.university.util;

import javafx.scene.Scene;
import javafx.stage.Stage;

/**
 * NavigationManager — Singleton + Facade design pattern.
 * Centrally manages all screen (Stage) transitions in the application.
 * Bonus: demonstrates a design pattern beyond the course scope.
 */
public class NavigationManager {

    private static NavigationManager instance;
    private Stage primaryStage;

    private NavigationManager() {}

    public static synchronized NavigationManager getInstance() {
        if (instance == null) instance = new NavigationManager();
        return instance;
    }

    public void setPrimaryStage(Stage stage) { this.primaryStage = stage; }
    public Stage getPrimaryStage() { return primaryStage; }

    public void navigateTo(Scene scene, String title) {
        if (primaryStage == null) throw new IllegalStateException("Primary stage not set.");
        primaryStage.setTitle("University Registration System — " + title);
        primaryStage.setMaximized(false);
        primaryStage.setScene(scene);
        javafx.application.Platform.runLater(() -> primaryStage.setMaximized(true));
        UIHelper.fadeIn(scene.getRoot());
    }
}