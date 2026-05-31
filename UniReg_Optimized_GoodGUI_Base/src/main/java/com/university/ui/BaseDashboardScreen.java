package com.university.ui;

import com.university.service.AuthService;
import com.university.util.NavigationManager;
import com.university.util.UIHelper;
import javafx.fxml.FXMLLoader;
import javafx.geometry.Insets;
import javafx.geometry.Pos;
import javafx.scene.Node;
import javafx.scene.Scene;
import javafx.scene.control.*;
import javafx.scene.layout.*;
import javafx.scene.paint.Color;
import java.io.IOException;

public abstract class BaseDashboardScreen {

    protected final AuthService       auth = AuthService.getInstance();
    protected final NavigationManager nav  = NavigationManager.getInstance();

    protected abstract Node[] topBarInfoNodes();
    protected abstract VBox   buildSidebarContent();
    protected abstract Node   buildContent();

    protected double getWidth()  { return 1280; }
    protected double getHeight() { return 800;  }

    public Scene build() {
        BorderPane shell = loadShell();
        shell.setTop(buildTopBar());
        shell.setLeft(buildSidebar());
        shell.setCenter(buildContent());

        StackPane root = UIHelper.wrapWithDashboardBackground(shell);
        UIHelper.fadeIn(root);

        Scene scene = new Scene(root, getWidth(), getHeight());
        scene.getStylesheets().add(UIHelper.getStylesheet());
        return scene;
    }

    protected Node buildTopBar() {
        HBox topBar = new HBox(20);
        topBar.setAlignment(Pos.CENTER_LEFT);
        topBar.setPadding(new Insets(15, 25, 15, 25));
        topBar.getStyleClass().add("top-bar");

        Label logo = new Label("UNIVERSITY");
        logo.setStyle("-fx-font-size: 20px; -fx-font-weight: 900; -fx-text-fill: linear-gradient(to right, #00D4FF, #7C5CFC); -fx-letter-spacing: 2px;");

        Region spacer = new Region();
        HBox.setHgrow(spacer, Priority.ALWAYS);

        HBox infoBox = new HBox(15);
        infoBox.setAlignment(Pos.CENTER_RIGHT);
        infoBox.getChildren().addAll(topBarInfoNodes());

        javafx.scene.control.Button logoutBtn = UIHelper.makeSecondaryButton("Logout");
        logoutBtn.setOnAction(e -> {
            auth.logout();
            nav.navigateTo(new LoginScreen().build(), "Login");
        });

        topBar.getChildren().addAll(logo, spacer, infoBox, logoutBtn);
        return topBar;
    }

    protected Node buildSidebar() {
        VBox sidebar = new VBox(25);
        sidebar.setPadding(new Insets(30, 20, 30, 20));
        sidebar.setPrefWidth(260);
        sidebar.getStyleClass().add("sidebar");

        VBox content = buildSidebarContent();
        VBox.setVgrow(content, Priority.ALWAYS);

        sidebar.getChildren().add(content);
        return sidebar;
    }

    protected VBox buildProfileCard(String icon, String id, String email) {
        VBox card = new VBox(5);
        card.setPadding(new Insets(12));
        card.getStyleClass().add("profile-card");

        HBox header = new HBox(10);
        header.setAlignment(Pos.CENTER_LEFT);
        Label iconLbl = new Label(icon);
        iconLbl.setStyle("-fx-font-size: 20px;");
        Label idLbl = new Label("ID: " + id);
        idLbl.setStyle("-fx-font-size: 12px; -fx-font-weight: bold; -fx-text-fill: " + UIHelper.COLOR_ACCENT + ";");
        header.getChildren().addAll(iconLbl, idLbl);

        Label emailLbl = new Label(email);
        emailLbl.setStyle("-fx-font-size: 11px; -fx-text-fill: " + UIHelper.COLOR_MUTED + ";");

        card.getChildren().addAll(header, emailLbl);
        return card;
    }

    protected VBox panel() {
        VBox panel = new VBox(20);
        panel.setPadding(new Insets(24));
        panel.setStyle("-fx-background-color: transparent;");
        return panel;
    }

    protected VBox emptyBox(String icon, String title, String subtitle) {
        VBox box = new VBox(15);
        box.setAlignment(Pos.CENTER);
        box.setPadding(new Insets(60, 20, 60, 20));

        Label iconLbl = new Label(icon);
        iconLbl.setStyle("-fx-font-size: 64px;");

        Label titleLbl = UIHelper.makeTitle(title);
        Label subLbl   = UIHelper.makeSubtitle(subtitle);

        box.getChildren().addAll(iconLbl, titleLbl, subLbl);
        return box;
    }

    protected Label muted(String text) {
        Label lbl = new Label(text);
        lbl.getStyleClass().add("label-muted");
        return lbl;
    }

    protected Label styledLabel(String text, double size, String color) {
        Label lbl = new Label(text);
        lbl.setStyle("-fx-font-size: " + size + "px; -fx-font-weight: bold; -fx-text-fill: " + color + ";");
        return lbl;
    }

    protected GridPane makeAnalyticsGrid() {
        GridPane grid = new GridPane();
        grid.setHgap(15);
        grid.setVgap(15);
        ColumnConstraints c1 = new ColumnConstraints(); c1.setPercentWidth(33.3);
        ColumnConstraints c2 = new ColumnConstraints(); c2.setPercentWidth(33.3);
        ColumnConstraints c3 = new ColumnConstraints(); c3.setPercentWidth(33.3);
        grid.getColumnConstraints().addAll(c1, c2, c3);
        return grid;
    }

    protected GridPane formGrid(Object... nodes) {
        GridPane grid = new GridPane();
        grid.setHgap(15); grid.setVgap(15);
        grid.setPadding(new Insets(10));
        for (int i = 0; i < nodes.length; i += 2) {
            grid.add(muted(nodes[i].toString()), 0, i / 2);
            grid.add((Node) nodes[i + 1], 1, i / 2);
        }
        return grid;
    }

    protected void showDialog(String title, Node content, Runnable onSave) {
        Dialog<Void> dialog = new Dialog<>();
        dialog.setTitle(title);
        dialog.setResizable(true);

        DialogPane pane = dialog.getDialogPane();
        pane.getStyleClass().add("card-glass-strong");
        pane.getStylesheets().add(UIHelper.getStylesheet());
        pane.setPrefWidth(780);
        pane.setPrefHeight(640);
        pane.setMaxHeight(680);
        pane.setStyle(
                "-fx-background-color: rgba(8,11,20,0.96);" +
                        "-fx-background-radius: 18;" +
                        "-fx-border-color: rgba(0,212,255,0.30);" +
                        "-fx-border-radius: 18;" +
                        "-fx-border-width: 1.2;" +
                        "-fx-effect: dropshadow(gaussian,rgba(0,0,0,0.55),22,0,0,6);"
        );

        StackPane contentShell = new StackPane(content);
        contentShell.setPadding(new Insets(16));
        contentShell.setStyle(
                "-fx-background-color: rgba(10,15,31,0.90);" +
                        "-fx-background-radius: 16;" +
                        "-fx-border-color: rgba(124,92,252,0.22);" +
                        "-fx-border-radius: 16;" +
                        "-fx-border-width: 1;"
        );

        ScrollPane scroll = new ScrollPane(contentShell);
        scroll.setFitToWidth(true);
        scroll.setHbarPolicy(ScrollPane.ScrollBarPolicy.NEVER);
        scroll.setVbarPolicy(ScrollPane.ScrollBarPolicy.AS_NEEDED);
        scroll.setPrefViewportWidth(730);
        scroll.setPrefViewportHeight(500);
        scroll.setMaxHeight(520);
        scroll.setStyle(
                "-fx-background-color: transparent;" +
                        "-fx-background: transparent;" +
                        "-fx-control-inner-background: transparent;" +
                        "-fx-border-color: transparent;"
        );

        pane.setContent(scroll);

        ButtonType saveType = new ButtonType("Save", javafx.scene.control.ButtonBar.ButtonData.OK_DONE);
        pane.getButtonTypes().addAll(saveType, ButtonType.CANCEL);

        Node saveButton = pane.lookupButton(saveType);
        if (saveButton instanceof Button b) {
            b.setText("Save / Apply");
            b.setPrefWidth(130);
            b.setStyle(
                    "-fx-background-color: linear-gradient(to right,#00D4FF,#2DE2E6);" +
                            "-fx-text-fill: #020617;" +
                            "-fx-font-weight: bold;" +
                            "-fx-background-radius: 10;" +
                            "-fx-padding: 9 18;"
            );
        }

        Node cancelButton = pane.lookupButton(ButtonType.CANCEL);
        if (cancelButton instanceof Button b) {
            b.setText("Close");
            b.setPrefWidth(100);
            b.setStyle(
                    "-fx-background-color: rgba(10,15,31,0.92);" +
                            "-fx-text-fill: #E5F4FF;" +
                            "-fx-border-color: rgba(0,212,255,0.45);" +
                            "-fx-border-radius: 10;" +
                            "-fx-background-radius: 10;" +
                            "-fx-padding: 9 18;"
            );
        }

        dialog.setResultConverter(bt -> {
            if (bt == saveType) {
                onSave.run();
            }
            return null;
        });

        UIHelper.fadeIn(pane);
        dialog.showAndWait();
    }

    protected HBox headerRow(String title, String subtitle, String badge, String color) {
        HBox row = new HBox(15);
        row.setAlignment(Pos.CENTER_LEFT);
        VBox texts = new VBox(2, UIHelper.makeTitle(title), UIHelper.makeSubtitle(subtitle));
        Region sp = new Region(); HBox.setHgrow(sp, Priority.ALWAYS);
        row.getChildren().addAll(texts, sp, UIHelper.makeStatusBadge(badge, color));
        return row;
    }

    private BorderPane loadShell() {
        try {
            java.net.URL shellUrl = BaseDashboardScreen.class.getResource("/com/university/ui/dashboard-shell.fxml");

            if (shellUrl == null) {
                System.err.println("[UI] dashboard-shell.fxml was not found. Using programmatic dashboard shell.");
                return fallbackShell();
            }

            FXMLLoader loader = new FXMLLoader(shellUrl);
            return loader.load();
        } catch (Exception e) {
            System.err.println("[UI] Could not load dashboard-shell.fxml. Using programmatic dashboard shell.");
            e.printStackTrace();
            return fallbackShell();
        }
    }

    private BorderPane fallbackShell() {
        BorderPane fallback = new BorderPane();
        fallback.setStyle("-fx-background-color: transparent;");
        fallback.getStyleClass().add("dashboard-shell");
        return fallback;
    }
}