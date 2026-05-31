package com.university.ui;

import com.university.exception.UniversityException;
import com.university.model.Admin;
import com.university.model.Instructor;
import com.university.model.Person;
import com.university.model.Student;
import com.university.service.AuthService;
import com.university.util.NavigationManager;
import com.university.util.UIHelper;
import javafx.animation.*;
import javafx.application.Platform;
import javafx.geometry.*;
import javafx.scene.Scene;
import javafx.scene.control.*;
import javafx.scene.layout.*;
import javafx.util.Duration;

/**
 * Login screen.
 *
 * This version fixes the "button clicks but nothing happens" problem by:
 * 1. catching ALL runtime errors during login/dashboard routing,
 * 2. showing the error on the login screen instead of silently staying there,
 * 3. disabling the button while trying to log in,
 * 4. printing the real exception to the console for debugging.
 */
public class LoginScreen {

    private final AuthService authService = AuthService.getInstance();
    private final NavigationManager nav = NavigationManager.getInstance();

    public Scene build() {
        HBox mainLayout = new HBox();
        mainLayout.setAlignment(Pos.CENTER);
        mainLayout.setStyle("-fx-background-color: transparent;");

        VBox brandPanel = buildBrandPanel();
        brandPanel.setPrefWidth(460);

        VBox formPanel = buildFormPanel();
        formPanel.setPrefWidth(460);

        mainLayout.getChildren().addAll(brandPanel, formPanel);

        StackPane root = UIHelper.wrapWithParticles(mainLayout);

        Scene scene = new Scene(root, 920, 640);
        scene.getStylesheets().add(UIHelper.getStylesheet());
        UIHelper.fadeIn(mainLayout);
        return scene;
    }

    private VBox buildBrandPanel() {
        VBox panel = new VBox(18);
        panel.setAlignment(Pos.CENTER_LEFT);
        panel.setPadding(new Insets(60, 40, 60, 60));
        panel.setStyle("-fx-background-color: rgba(8,11,20,0.85);");

        Label icon = new Label("🎓");
        icon.setStyle("-fx-font-size: 68px;");

        Label title = new Label("UniReg");
        title.setStyle(
                "-fx-font-size: 46px;" +
                        "-fx-font-weight: bold;" +
                        "-fx-text-fill: white;" +
                        "-fx-effect: dropshadow(gaussian,#00D4FF88,20,0,0,0);"
        );

        Label accent = new Label("University Registration System");
        accent.setStyle(
                "-fx-font-size: 14px;" +
                        "-fx-text-fill: " + UIHelper.COLOR_ACCENT + ";" +
                        "-fx-effect: dropshadow(gaussian,#00D4FF44,8,0,0,0);"
        );

        Region line = new Region();
        line.setPrefHeight(2);
        line.setPrefWidth(0);
        line.setStyle("-fx-background-color: linear-gradient(to right,#00D4FF,#7C5CFC);");

        Timeline lineTl = new Timeline(
                new KeyFrame(Duration.ZERO, new KeyValue(line.prefWidthProperty(), 0)),
                new KeyFrame(Duration.millis(800), new KeyValue(line.prefWidthProperty(), 340, Interpolator.EASE_OUT))
        );
        lineTl.setDelay(Duration.millis(300));
        lineTl.play();

        VBox features = new VBox(12);
        String[][] feats = {
                {"📚", "Course Registration & Management"},
                {"👨‍🏫", "Instructor Grade Portal"},
                {"🛡", "Administrative Control Panel"},
                {"📊", "Real-time GPA Tracking & Charts"}
        };

        for (int i = 0; i < feats.length; i++) {
            HBox row = new HBox(10);
            row.setAlignment(Pos.CENTER_LEFT);

            Label ico = new Label(feats[i][0]);
            ico.setStyle("-fx-font-size: 16px;");

            Label txt = new Label(feats[i][1]);
            txt.setStyle("-fx-font-size: 13px; -fx-text-fill: " + UIHelper.COLOR_MUTED + ";");

            row.getChildren().addAll(ico, txt);
            row.setOpacity(0);
            features.getChildren().add(row);

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

        Label version = new Label("v1.0 — ECE2104 Spring 2025-26");
        version.setStyle("-fx-font-size: 11px; -fx-text-fill: #2A3050;");

        panel.getChildren().addAll(icon, title, accent, line, features, version);
        return panel;
    }

    private VBox buildFormPanel() {
        VBox panel = new VBox(18);
        panel.setAlignment(Pos.CENTER);
        panel.setPadding(new Insets(50, 55, 50, 45));
        panel.setStyle(
                "-fx-background-color: rgba(14,18,32,0.92);" +
                        "-fx-border-color: #1A2040;" +
                        "-fx-border-width: 0 0 0 1;"
        );

        Label heading = UIHelper.makeTitle("Welcome back");
        Label sub = UIHelper.makeSubtitle("Sign in to your account to continue");

        VBox emailBox = new VBox(6);
        Label emailLbl = UIHelper.makeLabel("Email Address");
        TextField emailField = UIHelper.makeTextField("e.g. super.admin@university.edu");
        emailBox.getChildren().addAll(emailLbl, emailField);

        VBox passBox = new VBox(6);
        Label passLbl = UIHelper.makeLabel("Password");
        PasswordField passField = UIHelper.makePasswordField("Enter your password");
        passBox.getChildren().addAll(passLbl, passField);

        Label errorLabel = new Label();
        errorLabel.setWrapText(true);
        errorLabel.setMaxWidth(Double.MAX_VALUE);
        errorLabel.setStyle(
                "-fx-text-fill: " + UIHelper.COLOR_DANGER + ";" +
                        "-fx-font-size: 12px;" +
                        "-fx-background-color: " + UIHelper.COLOR_DANGER + "15;" +
                        "-fx-padding: 8 12;" +
                        "-fx-background-radius: 6;" +
                        "-fx-border-color: " + UIHelper.COLOR_DANGER + "44;" +
                        "-fx-border-radius: 6;" +
                        "-fx-border-width: 1;"
        );
        errorLabel.setVisible(false);
        errorLabel.setManaged(false);

        Button loginBtn = UIHelper.makePrimaryButton("Sign In  →");
        loginBtn.setMaxWidth(Double.MAX_VALUE);
        loginBtn.setPrefHeight(48);
        loginBtn.setDefaultButton(true);

        VBox hintBox = new VBox(8);
        hintBox.setPadding(new Insets(12));
        hintBox.setStyle(
                "-fx-background-color: " + UIHelper.COLOR_ACCENT + "0A;" +
                        "-fx-border-color: " + UIHelper.COLOR_ACCENT + "33;" +
                        "-fx-border-radius: 8;" +
                        "-fx-background-radius: 8;" +
                        "-fx-border-width: 1;"
        );

        Label hintTitle = new Label("⚡ Demo Credentials");
        hintTitle.setStyle("-fx-text-fill: " + UIHelper.COLOR_ACCENT + "; -fx-font-size: 11px; -fx-font-weight: bold;");
        hintBox.getChildren().add(hintTitle);

        hintBox.getChildren().add(makeCredentialRow("Admin", "super.admin@university.edu", "admin123", emailField, passField));
        hintBox.getChildren().add(makeCredentialRow("Student", "student001@university.edu", "stu123", emailField, passField));
        hintBox.getChildren().add(makeCredentialRow("Instructor", "instructor001@university.edu", "ins123", emailField, passField));

        Runnable doLogin = () -> {
            String email = emailField.getText() == null ? "" : emailField.getText().trim();
            String pass = passField.getText() == null ? "" : passField.getText().trim();

            if (email.isEmpty() || pass.isEmpty()) {
                showInlineError(errorLabel, "Please fill in all fields.");
                return;
            }

            loginBtn.setDisable(true);
            loginBtn.setText("Signing in...");

            try {
                System.out.println("[LOGIN] Attempting login for: " + email);

                Person user = authService.login(email, pass);

                if (user == null) {
                    throw new IllegalStateException("AuthService returned null user.");
                }

                System.out.println("[LOGIN] Success as " + user.getRole() + ": " + user.getEmail());

                errorLabel.setVisible(false);
                errorLabel.setManaged(false);

                routeUser(user);
            } catch (UniversityException ex) {
                System.err.println("[LOGIN] Failed: " + ex.getMessage());
                showInlineError(errorLabel, ex.getMessage());
            } catch (Exception ex) {
                ex.printStackTrace();
                showInlineError(
                        errorLabel,
                        "Login succeeded or started, but the next screen failed: " + rootCauseMessage(ex)
                                + ". Check the Run console for the full error."
                );
            } finally {
                loginBtn.setDisable(false);
                loginBtn.setText("Sign In  →");
            }
        };

        loginBtn.setOnAction(e -> doLogin.run());
        passField.setOnAction(e -> doLogin.run());

        panel.getChildren().addAll(
                heading,
                sub,
                UIHelper.makeSeparator(),
                emailBox,
                passBox,
                errorLabel,
                loginBtn,
                hintBox
        );

        return panel;
    }

    private HBox makeCredentialRow(String role, String email, String password, TextField emailField, PasswordField passField) {
        HBox row = new HBox(8);
        row.setAlignment(Pos.CENTER_LEFT);

        Label text = new Label(role + ":  " + email + "  /  " + password);
        text.setStyle("-fx-text-fill: " + UIHelper.COLOR_MUTED + "; -fx-font-size: 11px; -fx-font-family: monospace;");

        Region spacer = new Region();
        HBox.setHgrow(spacer, Priority.ALWAYS);

        Button useBtn = UIHelper.makeSecondaryButton("Use");
        useBtn.setStyle(useBtn.getStyle() + "-fx-font-size: 10px; -fx-padding: 4 10;");
        useBtn.setOnAction(e -> {
            emailField.setText(email);
            passField.setText(password);
            emailField.requestFocus();
        });

        row.getChildren().addAll(text, spacer, useBtn);
        return row;
    }

    private void showInlineError(Label errorLabel, String message) {
        errorLabel.setText("⚠  " + message);
        errorLabel.setVisible(true);
        errorLabel.setManaged(true);
        UIHelper.slideIn(errorLabel);
    }

    private String rootCauseMessage(Throwable throwable) {
        Throwable t = throwable;
        while (t.getCause() != null) {
            t = t.getCause();
        }

        String message = t.getMessage();
        return message == null || message.isBlank() ? t.getClass().getSimpleName() : message;
    }

    private void routeUser(Person user) {
        if (user instanceof Admin) {
            nav.navigateTo(new AdminDashboardScreen().build(), "Admin Dashboard");
        } else if (user instanceof Instructor) {
            nav.navigateTo(new InstructorScreen().build(), "Instructor Portal");
        } else if (user instanceof Student) {
            nav.navigateTo(new StudentDashboardScreen().build(), "Student Dashboard");
        } else {
            throw new IllegalStateException("Unknown user type: " + user.getClass().getName());
        }
    }
}
