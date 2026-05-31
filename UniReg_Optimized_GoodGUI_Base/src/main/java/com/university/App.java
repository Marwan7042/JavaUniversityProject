package com.university;

import com.university.dao.DatabaseManager;
import com.university.service.NotificationService;
import com.university.ui.LoginScreen;
import com.university.util.NavigationManager;
import javafx.application.Application;
import javafx.application.Platform;
import javafx.geometry.Insets;
import javafx.geometry.Pos;
import javafx.scene.Scene;
import javafx.scene.control.Alert;
import javafx.scene.control.Label;
import javafx.scene.control.ProgressIndicator;
import javafx.scene.layout.VBox;
import javafx.stage.Stage;

public class App extends Application {
    @Override public void start(Stage primaryStage) {
        NavigationManager nav = NavigationManager.getInstance();
        nav.setPrimaryStage(primaryStage);
        primaryStage.setTitle("University Registration System");
        primaryStage.setResizable(true);
        primaryStage.setMinWidth(900);
        primaryStage.setMinHeight(600);
        primaryStage.setMaximized(true);
        primaryStage.setScene(buildLoadingScene());
        primaryStage.show();

        Thread dbThread = new Thread(() -> {
            try {
                DatabaseManager.getInstance();
                Platform.runLater(() -> nav.navigateTo(new LoginScreen().build(), "Login"));
            } catch (Exception e) {
                Platform.runLater(() -> { showDatabaseError(e.getMessage()); primaryStage.close(); });
            }
        });
        dbThread.setDaemon(true);
        dbThread.start();
    }

    private Scene buildLoadingScene() {
        VBox root = new VBox(16);
        root.setAlignment(Pos.CENTER); root.setPadding(new Insets(40)); root.setStyle("-fx-background-color:#0F1117;");
        Label icon = new Label("🎓"); icon.setStyle("-fx-font-size:56px;");
        Label title = new Label("University Registration System"); title.setStyle("-fx-font-size:22px;-fx-font-weight:bold;-fx-text-fill:white;");
        Label status = new Label("Connecting to database..."); status.setStyle("-fx-font-size:14px;-fx-text-fill:#8892A4;");
        ProgressIndicator spinner = new ProgressIndicator(); spinner.setPrefSize(48, 48);
        root.getChildren().addAll(icon, title, spinner, status);
        return new Scene(root, 700, 450);
    }

    private void showDatabaseError(String errorMessage) {
        Alert alert = new Alert(Alert.AlertType.ERROR);
        alert.setTitle("Database Connection Failed");
        alert.setHeaderText("Could not connect to SQL Server or verify schema");
        alert.setContentText("Make sure SQL Server is running, UniversityDB exists, and the seed/schema script was run.\n\nDetails:\n" + errorMessage);
        alert.showAndWait();
    }

    @Override public void stop() { NotificationService.getInstance().shutdown(); }
    public static void main(String[] args) { launch(args); }
}
