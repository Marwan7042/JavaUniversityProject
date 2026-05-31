package com.university.ui;

import com.university.exception.UniversityException;
import com.university.model.Admin;
import com.university.model.Instructor;
import com.university.model.Person;
import com.university.model.Student;
import com.university.service.AuthService;
import com.university.util.NavigationManager;
import com.university.util.UIHelper;
import javafx.animation.FadeTransition;
import javafx.animation.KeyFrame;
import javafx.animation.KeyValue;
import javafx.animation.ParallelTransition;
import javafx.animation.Timeline;
import javafx.animation.TranslateTransition;
import javafx.fxml.FXML;
import javafx.scene.control.Button;
import javafx.scene.control.Label;
import javafx.scene.control.PasswordField;
import javafx.scene.control.TextField;
import javafx.scene.layout.HBox;
import javafx.scene.layout.Region;
import javafx.scene.layout.VBox;
import javafx.util.Duration;

public class LoginController {

    private final AuthService authService = AuthService.getInstance();
    private final NavigationManager nav = NavigationManager.getInstance();

    @FXML private VBox featureList;
    @FXML private Region brandLine;
    @FXML private TextField emailField;
    @FXML private PasswordField passField;
    @FXML private Label errorLabel;
    @FXML private Button loginButton;

    @FXML
    private void initialize() {
        buildFeatures();
        animateBrandLine();

        loginButton.setOnAction(e -> doLogin());
        passField.setOnAction(e -> doLogin());
    }

    private void buildFeatures() {
        String[][] feats = {
                {"📚", "Course Registration & Management"},
                {"👨‍🏫", "Instructor Grade Portal"},
                {"🛡", "Administrative Control Panel"},
                {"📊", "Real-time GPA Tracking & Charts"}
        };

        for (int i = 0; i < feats.length; i++) {
            HBox row = new HBox(10);
            row.getStyleClass().add("feature-row");

            Label ico = new Label(feats[i][0]);
            ico.getStyleClass().add("feature-icon");

            Label txt = new Label(feats[i][1]);
            txt.getStyleClass().add("feature-text");

            row.getChildren().addAll(ico, txt);
            featureList.getChildren().add(row);

            FadeTransition ft = new FadeTransition(Duration.millis(400), row);
            ft.setFromValue(0);
            ft.setToValue(1);
            ft.setDelay(Duration.millis(400 + i * 120L));

            TranslateTransition tt = new TranslateTransition(Duration.millis(400), row);
            tt.setFromX(-15);
            tt.setToX(0);
            tt.setDelay(Duration.millis(400 + i * 120L));

            new ParallelTransition(ft, tt).play();
        }
    }

    private void animateBrandLine() {
        Timeline lineTl = new Timeline(
                new KeyFrame(Duration.ZERO, new KeyValue(brandLine.prefWidthProperty(), 0)),
                new KeyFrame(Duration.millis(800), new KeyValue(brandLine.prefWidthProperty(), 340))
        );
        lineTl.setDelay(Duration.millis(300));
        lineTl.play();
    }

    private void doLogin() {
        String email = emailField.getText().trim();
        String pass = passField.getText().trim();

        if (email.isEmpty() || pass.isEmpty()) {
            showError("Please fill in all fields.");
            return;
        }

        try {
            Person user = authService.login(email, pass);
            hideError();
            routeUser(user);
        } catch (UniversityException ex) {
            showError(ex.getMessage());
            UIHelper.slideIn(errorLabel);
        }
    }

    private void showError(String message) {
        errorLabel.setText("⚠  " + message);
        errorLabel.setVisible(true);
        errorLabel.setManaged(true);
    }

    private void hideError() {
        errorLabel.setVisible(false);
        errorLabel.setManaged(false);
    }

    private void routeUser(Person user) {
        if (user instanceof Admin) {
            nav.navigateTo(new AdminDashboardScreen().build(), "Admin Dashboard");
        } else if (user instanceof Instructor) {
            nav.navigateTo(new InstructorScreen().build(), "Instructor Portal");
        } else if (user instanceof Student) {
            nav.navigateTo(new StudentDashboardScreen().build(), "Student Dashboard");
        }
    }
}
