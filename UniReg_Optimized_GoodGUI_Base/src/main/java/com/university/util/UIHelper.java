package com.university.util;

import javafx.animation.*;
import javafx.application.Platform;
import javafx.scene.effect.GaussianBlur;
import javafx.geometry.Insets;
import javafx.geometry.Pos;
import javafx.scene.Node;
import javafx.scene.canvas.Canvas;
import javafx.scene.canvas.GraphicsContext;
import javafx.scene.control.*;
import javafx.scene.layout.*;
import javafx.scene.paint.Color;
import javafx.scene.shape.Circle;
import javafx.scene.shape.Line;
import javafx.util.Duration;

import java.util.ArrayList;
import java.util.List;
import java.util.Random;

public class UIHelper {

    // ── Color constants (kept for code that still needs them) ─────────────
    public static final String COLOR_BG       = "#080B14";
    public static final String COLOR_SURFACE  = "#0E1220";
    public static final String COLOR_SURFACE2 = "#151929";
    public static final String COLOR_ACCENT   = "#00D4FF";
    public static final String COLOR_ACCENT2  = "#7C5CFC";
    public static final String COLOR_SUCCESS  = "#00FF88";
    public static final String COLOR_WARNING  = "#FFB700";
    public static final String COLOR_DANGER   = "#FF3D5A";
    public static final String COLOR_TEXT     = "#E8EAF0";
    public static final String COLOR_MUTED    = "#5A6480";

    // ── CSS stylesheet path helper ────────────────────────────────────────
    public static String getStylesheet() {
        return UIHelper.class.getResource("/com/university/ui/styles.css").toExternalForm();
    }

    // ── Particle background (login) ───────────────────────────────────────
    public static Canvas makeParticleBackground() {
        Canvas canvas = new Canvas();
        canvas.setMouseTransparent(true);
        GraphicsContext gc = canvas.getGraphicsContext2D();
        Random random = new Random();
        final int particleCount = 48;
        final double connectionDistance = 125;
        final long targetFrameGapNanos = 33_333_333L;

        class Particle {
            double x, y, vx, vy, radius;
            Color color;
            void randomize(double w, double h) {
                x = random.nextDouble() * Math.max(w, 1);
                y = random.nextDouble() * Math.max(h, 1);
                vx = (random.nextDouble() - 0.5) * 28;
                vy = (random.nextDouble() - 0.5) * 28;
                radius = 1.0 + random.nextDouble() * 1.6;
                color = random.nextBoolean() ? Color.rgb(0, 212, 255, 0.82) : Color.rgb(124, 92, 252, 0.82);
            }
        }

        Particle[] particles = new Particle[particleCount];
        for (int i = 0; i < particleCount; i++) particles[i] = new Particle();

        final boolean[] initialized  = {false};
        final boolean[] running      = {false};
        final double[]  lastWidth    = {0};
        final double[]  lastHeight   = {0};
        final long[]    lastFrameTime = {0};
        final long[]    lastDrawTime  = {0};

        AnimationTimer timer = new AnimationTimer() {
            @Override public void handle(long now) {
                if (canvas.getScene() == null) { stop(); running[0] = false; lastFrameTime[0] = 0; lastDrawTime[0] = 0; return; }
                if (lastDrawTime[0] != 0 && now - lastDrawTime[0] < targetFrameGapNanos) return;
                double width = canvas.getWidth(), height = canvas.getHeight();
                if (width <= 0 || height <= 0) return;
                double delta = lastFrameTime[0] == 0 ? 1.0/30.0 : Math.min((now - lastFrameTime[0]) / 1_000_000_000.0, 1.0/30.0);
                lastFrameTime[0] = now; lastDrawTime[0] = now;
                if ((!initialized[0] && width > 200 && height > 200) || (initialized[0] && lastWidth[0] > 0 && (width > lastWidth[0] * 1.25 || height > lastHeight[0] * 1.25))) {
                    for (Particle p : particles) p.randomize(width, height);
                    initialized[0] = true; lastWidth[0] = width; lastHeight[0] = height;
                }
                gc.setFill(Color.web(COLOR_BG));
                gc.fillRect(0, 0, width, height);
                if (!initialized[0]) return;
                for (int i = 0; i < particles.length; i++) {
                    Particle p = particles[i];
                    p.x += p.vx * delta; p.y += p.vy * delta;
                    if (p.x <= 0) { p.x = 0; p.vx *= -1; } else if (p.x >= width)  { p.x = width;  p.vx *= -1; }
                    if (p.y <= 0) { p.y = 0; p.vy *= -1; } else if (p.y >= height) { p.y = height; p.vy *= -1; }
                    for (int j = i + 1; j < particles.length; j++) {
                        Particle q = particles[j];
                        double dx = p.x - q.x, dy = p.y - q.y, dist = Math.sqrt(dx*dx + dy*dy);
                        if (dist < connectionDistance) {
                            gc.setStroke(Color.rgb(0, 212, 255, 0.12 * (1 - dist / connectionDistance)));
                            gc.setLineWidth(0.55); gc.strokeLine(p.x, p.y, q.x, q.y);
                        }
                    }
                    gc.setFill(Color.rgb((int)(p.color.getRed()*255),(int)(p.color.getGreen()*255),(int)(p.color.getBlue()*255), 0.14));
                    gc.fillOval(p.x - 5, p.y - 5, 10, 10);
                    gc.setFill(p.color);
                    gc.fillOval(p.x - p.radius, p.y - p.radius, p.radius * 2, p.radius * 2);
                }
            }
        };
        canvas.sceneProperty().addListener((obs, o, n) -> {
            if (n == null) { timer.stop(); running[0] = false; lastFrameTime[0] = 0; lastDrawTime[0] = 0; }
            else if (!running[0]) { running[0] = true; lastFrameTime[0] = 0; lastDrawTime[0] = 0; timer.start(); }
        });
        return canvas;
    }

    public static StackPane wrapWithParticles(Node content) {
        StackPane stack = new StackPane();
        stack.setStyle("-fx-background-color: " + COLOR_BG + ";");
        Canvas bg = makeParticleBackground();
        bg.widthProperty().bind(stack.widthProperty());
        bg.heightProperty().bind(stack.heightProperty());
        StackPane.setAlignment(bg, Pos.TOP_LEFT);
        StackPane.setAlignment(content, Pos.CENTER);
        stack.getChildren().addAll(bg, content);
        return stack;
    }

    public static StackPane wrapWithDashboardBackground(Node content) {
        StackPane stack = new StackPane();
        stack.setStyle("-fx-background-color: #050713;");
        Pane bg = makeAliveDashboardBackground(stack);
        StackPane.setAlignment(bg, Pos.CENTER);
        StackPane.setAlignment(content, Pos.CENTER);
        stack.getChildren().addAll(bg, content);
        return stack;
    }

    private static Pane makeAliveDashboardBackground(StackPane parent) {
        Pane layer = new Pane();
        layer.setMouseTransparent(true);
        layer.setStyle("-fx-background-color: linear-gradient(to bottom right, #050713, #07101F, #0B1024);");
        layer.prefWidthProperty().bind(parent.widthProperty());
        layer.prefHeightProperty().bind(parent.heightProperty());

        List<Animation> animations = new ArrayList<>();

        Circle cyanGlow = new Circle(260); cyanGlow.setFill(Color.rgb(0, 212, 255, 0.20)); cyanGlow.setEffect(new GaussianBlur(90));
        cyanGlow.centerXProperty().bind(parent.widthProperty().multiply(0.14)); cyanGlow.centerYProperty().bind(parent.heightProperty().multiply(0.22));

        Circle purpleGlow = new Circle(300); purpleGlow.setFill(Color.rgb(124, 92, 252, 0.18)); purpleGlow.setEffect(new GaussianBlur(100));
        purpleGlow.centerXProperty().bind(parent.widthProperty().multiply(0.88)); purpleGlow.centerYProperty().bind(parent.heightProperty().multiply(0.18));

        Circle blueGlow = new Circle(360); blueGlow.setFill(Color.rgb(0, 120, 220, 0.13)); blueGlow.setEffect(new GaussianBlur(110));
        blueGlow.centerXProperty().bind(parent.widthProperty().multiply(0.55)); blueGlow.centerYProperty().bind(parent.heightProperty().multiply(0.96));

        layer.getChildren().addAll(cyanGlow, purpleGlow, blueGlow);
        animations.addAll(createGlowAnimation(cyanGlow, 18, 10, 5200));
        animations.addAll(createGlowAnimation(purpleGlow, -18, 12, 6000));
        animations.addAll(createGlowAnimation(blueGlow, 14, -10, 6800));

        for (int i = 1; i < 10; i++) {
            double ratio = i / 10.0;
            Line v = new Line(); v.startXProperty().bind(parent.widthProperty().multiply(ratio)); v.endXProperty().bind(parent.widthProperty().multiply(ratio));
            v.setStartY(0); v.endYProperty().bind(parent.heightProperty()); v.setStroke(Color.rgb(0, 212, 255, 0.055)); v.setStrokeWidth(1);
            Line h = new Line(); h.setStartX(0); h.endXProperty().bind(parent.widthProperty());
            h.startYProperty().bind(parent.heightProperty().multiply(ratio)); h.endYProperty().bind(parent.heightProperty().multiply(ratio));
            h.setStroke(Color.rgb(0, 212, 255, 0.04)); h.setStrokeWidth(1);
            layer.getChildren().addAll(v, h);
        }

        addCircuitLine(layer, parent, 0.06, 0.18, 0.28, 0.08, COLOR_ACCENT);
        addCircuitLine(layer, parent, 0.28, 0.08, 0.45, 0.22, COLOR_ACCENT2);
        addCircuitLine(layer, parent, 0.65, 0.12, 0.92, 0.28, COLOR_ACCENT);
        addCircuitLine(layer, parent, 0.10, 0.82, 0.34, 0.68, COLOR_ACCENT2);
        addCircuitLine(layer, parent, 0.34, 0.68, 0.58, 0.86, COLOR_ACCENT);

        animations.add(addNode(layer, parent, 0.06, 0.18, COLOR_ACCENT)); animations.add(addNode(layer, parent, 0.28, 0.08, COLOR_ACCENT2));
        animations.add(addNode(layer, parent, 0.45, 0.22, COLOR_ACCENT)); animations.add(addNode(layer, parent, 0.65, 0.12, COLOR_ACCENT2));
        animations.add(addNode(layer, parent, 0.92, 0.28, COLOR_ACCENT)); animations.add(addNode(layer, parent, 0.10, 0.82, COLOR_ACCENT));
        animations.add(addNode(layer, parent, 0.34, 0.68, COLOR_ACCENT2)); animations.add(addNode(layer, parent, 0.58, 0.86, COLOR_ACCENT));

        layer.sceneProperty().addListener((obs, o, n) -> {
            if (n == null) animations.forEach(Animation::stop); else animations.forEach(Animation::play);
        });
        return layer;
    }

    private static List<Animation> createGlowAnimation(Node node, double byX, double byY, int millis) {
        TranslateTransition move = new TranslateTransition(Duration.millis(millis), node);
        move.setByX(byX); move.setByY(byY); move.setAutoReverse(true); move.setCycleCount(Animation.INDEFINITE); move.setInterpolator(Interpolator.EASE_BOTH);
        FadeTransition fade = new FadeTransition(Duration.millis(millis + 700), node);
        fade.setFromValue(0.82); fade.setToValue(1.0); fade.setAutoReverse(true); fade.setCycleCount(Animation.INDEFINITE); fade.setInterpolator(Interpolator.EASE_BOTH);
        return List.of(move, fade);
    }

    private static void addCircuitLine(Pane layer, StackPane parent, double x1, double y1, double x2, double y2, String color) {
        Line line = new Line();
        line.startXProperty().bind(parent.widthProperty().multiply(x1)); line.startYProperty().bind(parent.heightProperty().multiply(y1));
        line.endXProperty().bind(parent.widthProperty().multiply(x2));   line.endYProperty().bind(parent.heightProperty().multiply(y2));
        line.setStroke(Color.web(color, 0.16)); line.setStrokeWidth(1.4);
        layer.getChildren().add(line);
    }

    private static Animation addNode(Pane layer, StackPane parent, double xR, double yR, String color) {
        Circle outer = new Circle(8); outer.setFill(Color.web(color, 0.18));
        outer.centerXProperty().bind(parent.widthProperty().multiply(xR)); outer.centerYProperty().bind(parent.heightProperty().multiply(yR));
        Circle inner = new Circle(3); inner.setFill(Color.web(color, 0.85));
        inner.centerXProperty().bind(parent.widthProperty().multiply(xR)); inner.centerYProperty().bind(parent.heightProperty().multiply(yR));
        FadeTransition pulse = new FadeTransition(Duration.millis(1800), outer);
        pulse.setFromValue(0.55); pulse.setToValue(1.0); pulse.setAutoReverse(true); pulse.setCycleCount(Animation.INDEFINITE); pulse.setInterpolator(Interpolator.EASE_BOTH);
        layer.getChildren().addAll(outer, inner);
        return pulse;
    }

    // ── Styled Labels — now use CSS classes ───────────────────────────────
    public static Label makeTitle(String text) {
        Label lbl = new Label(text);
        lbl.getStyleClass().add("title-label");
        return lbl;
    }

    public static Label makeSubtitle(String text) {
        Label lbl = new Label(text);
        lbl.getStyleClass().add("subtitle-label");
        return lbl;
    }

    public static Label makeLabel(String text) {
        Label lbl = new Label(text);
        lbl.getStyleClass().add("body-label");
        return lbl;
    }

    // ── Styled Buttons — now use CSS classes ──────────────────────────────
    public static Button makePrimaryButton(String text) {
        Button btn = new Button(text);
        btn.getStyleClass().add("btn-primary");
        return btn;
    }

    public static Button makeDangerButton(String text) {
        Button btn = new Button(text);
        btn.getStyleClass().add("btn-danger");
        return btn;
    }

    public static Button makeSuccessButton(String text) {
        Button btn = new Button(text);
        btn.getStyleClass().add("btn-success");
        return btn;
    }

    public static Button makeSecondaryButton(String text) {
        Button btn = new Button(text);
        btn.getStyleClass().add("btn-secondary");
        return btn;
    }

    // ── Styled Inputs — still use inline for focus effect ─────────────────
    public static TextField makeTextField(String prompt) {
        TextField tf = new TextField();
        tf.setPromptText(prompt);
        tf.getStyleClass().add("text-field");
        tf.setPrefHeight(44);
        return tf;
    }

    public static PasswordField makePasswordField(String prompt) {
        PasswordField pf = new PasswordField();
        pf.setPromptText(prompt);
        pf.getStyleClass().add("password-field");
        pf.setPrefHeight(44);
        return pf;
    }

    // ── Card ──────────────────────────────────────────────────────────────
    public static VBox makeCard(double padding) {
        VBox card = new VBox(12);
        card.setPadding(new Insets(padding));
        card.getStyleClass().add("card");
        return card;
    }

    // ── Status Badge ──────────────────────────────────────────────────────
    public static Label makeStatusBadge(String text, String color) {
        Label lbl = new Label(text);
        // Map known colors to CSS classes; fallback to inline for custom colors
        String cssClass = colorToBadgeClass(color);
        if (cssClass != null) {
            lbl.getStyleClass().addAll("badge", cssClass);
        } else {
            lbl.setStyle(
                    "-fx-background-color: " + color + "18; -fx-text-fill: " + color + ";" +
                    "-fx-padding: 4 12; -fx-background-radius: 20; -fx-font-size: 11px;" +
                    "-fx-font-weight: bold; -fx-border-color: " + color + "44;" +
                    "-fx-border-radius: 20; -fx-border-width: 1;");
        }
        return lbl;
    }

    private static String colorToBadgeClass(String color) {
        return switch (color) {
            case "#00D4FF" -> "badge-accent";
            case "#7C5CFC" -> "badge-accent2";
            case "#00FF88" -> "badge-success";
            case "#FFB700" -> "badge-warning";
            case "#FF3D5A" -> "badge-danger";
            case "#5A6480" -> "badge-muted";
            default -> null;
        };
    }

    // ── Separator ─────────────────────────────────────────────────────────
    public static Separator makeSeparator() {
        Separator sep = new Separator();
        sep.getStyleClass().add("separator");
        return sep;
    }

    // ── Glass Table ───────────────────────────────────────────────────────
    public static <T> void styleGlassTable(TableView<T> table) {
        table.getStyleClass().add("glass-table");
        table.setColumnResizePolicy(TableView.CONSTRAINED_RESIZE_POLICY);
        table.setFixedCellSize(34);
        table.setPlaceholder(makeSubtitle("No data available"));
        forceDarkTableSkin(table);
    }

    public static <S, T> void addGlassCol(TableView<S> table, String header, String propertyName,
            javafx.util.Callback<TableColumn.CellDataFeatures<S, T>, javafx.beans.value.ObservableValue<T>> factory) {
        TableColumn<S, T> col = new TableColumn<>(header);
        if (factory != null) col.setCellValueFactory(factory);
        else if (propertyName != null) col.setCellValueFactory(new javafx.scene.control.cell.PropertyValueFactory<>(propertyName));
        applyGlassCellFactory(col);
        table.getColumns().add(col);
    }

    public static <S> void makeStatusColumn(TableColumn<S, String> column) {
        column.setCellFactory(col -> new TableCell<>() {
            @Override protected void updateItem(String item, boolean empty) {
                super.updateItem(item, empty);
                getStyleClass().add("table-cell");
                if (empty || item == null) { setText(null); setGraphic(null); return; }
                setText(null); setGraphic(makeStatusPill(item));
            }
        });
    }

    private static Label makeStatusPill(String status) {
        return switch (status) {
            case "OPEN", "COMPLETED", "ENROLLED" -> makeStatusBadge(status, colorForStatus(status));
            case "CLOSED", "DROPPED"             -> makeStatusBadge(status, COLOR_DANGER);
            default                              -> makeStatusBadge(status, COLOR_MUTED);
        };
    }

    private static String colorForStatus(String status) {
        return switch(status) {
            case "OPEN", "COMPLETED" -> COLOR_SUCCESS;
            case "ENROLLED" -> COLOR_ACCENT;
            default -> COLOR_MUTED;
        };
    }

    public static void forceDarkTableSkin(TableView<?> table) {
        // Most of this is now handled by CSS, but keeping some for complex skin parts
        Runnable apply = () -> {
            table.lookupAll(".scroll-bar").forEach(n -> n.setStyle("-fx-background-color: transparent; -fx-background-insets: 0; -fx-padding: 0 2 0 2;"));
            table.lookupAll(".scroll-bar .track").forEach(n -> n.setStyle("-fx-background-color: rgba(10,15,31,0.35); -fx-background-radius: 8; -fx-background-insets: 0;"));
            table.lookupAll(".scroll-bar .thumb").forEach(n -> n.setStyle("-fx-background-color: rgba(0,212,255,0.34); -fx-background-radius: 8; -fx-background-insets: 0;"));
            table.lookupAll(".increment-button, .decrement-button, .increment-arrow, .decrement-arrow").forEach(n -> n.setStyle("-fx-background-color: transparent; -fx-padding: 0;"));
        };
        table.skinProperty().addListener((obs, o, n)  -> { Platform.runLater(apply); Platform.runLater(apply); });
        table.itemsProperty().addListener((obs, o, n) -> { Platform.runLater(apply); Platform.runLater(apply); });
        table.widthProperty().addListener((obs, o, n) -> Platform.runLater(apply));
        table.heightProperty().addListener((obs, o, n) -> Platform.runLater(apply));
        Platform.runLater(apply); Platform.runLater(apply);
    }

    // ── Shared widget builders ────────────────────────────────────────────
    public static VBox makeStatCard(String icon, String label, int value, String color) {
        VBox card = new VBox(4);
        card.setPadding(new Insets(12));
        card.getStyleClass().add("stat-card");
        String hoverStyle = "-fx-background-color: " + color + "22; -fx-background-radius: 12; -fx-border-color: " + color + "77; -fx-border-radius: 12; -fx-border-width: 1; -fx-effect: dropshadow(gaussian," + color + "44,10,0,0,3);";

        HBox row = new HBox(10); row.setAlignment(Pos.CENTER_LEFT);
        Label iconLabel = new Label(icon); iconLabel.setStyle("-fx-font-size: 20px;");
        VBox textBox = new VBox(2);
        Label numLabel = new Label("0"); numLabel.setStyle("-fx-font-size: 22px; -fx-font-weight: bold; -fx-text-fill: " + color + ";");
        Label nameLabel = new Label(label); nameLabel.setStyle("-fx-font-size: 11px; -fx-text-fill: " + COLOR_MUTED + ";");
        textBox.getChildren().addAll(numLabel, nameLabel);
        row.getChildren().addAll(iconLabel, textBox);
        card.getChildren().add(row);

        Timeline tl = new Timeline();
        for (int i = 1; i <= 20; i++) { int v = (int) Math.round((double) value * i / 20); tl.getKeyFrames().add(new KeyFrame(Duration.millis(i * 35L), e -> numLabel.setText(String.valueOf(v)))); }
        tl.play();

        card.setOnMouseEntered(e -> card.setStyle(hoverStyle));
        card.setOnMouseExited(e  -> { card.setStyle(""); card.getStyleClass().add("stat-card"); });
        return card;
    }

    public static VBox makeKpiCard(String title, String value, String subtitle, String color) {
        VBox card = new VBox(4);
        card.setPadding(new Insets(14, 16, 14, 16));
        card.setMinHeight(82);
        card.setStyle("-fx-background-color: rgba(10,15,31,0.74); -fx-background-radius: 14; -fx-border-color: " + color + "55; -fx-border-radius: 14; -fx-border-width: 1; -fx-effect: dropshadow(gaussian,rgba(0,0,0,0.26),10,0,0,2);");
        HBox.setHgrow(card, Priority.ALWAYS);
        Label t = new Label(title); t.setStyle("-fx-font-size: 12px; -fx-font-weight: bold; -fx-text-fill: " + COLOR_MUTED + ";");
        Label v = new Label(value); v.setStyle("-fx-font-size: 30px; -fx-font-weight: bold; -fx-text-fill: " + color + ";");
        Label s = new Label(subtitle); s.setStyle("-fx-font-size: 11px; -fx-text-fill: " + COLOR_MUTED + ";");
        card.getChildren().addAll(t, v, s);
        return card;
    }

    public static VBox makeChartCard(String title, Node chart) {
        VBox card = new VBox(8);
        card.setPadding(new Insets(12));
        card.getStyleClass().add("glass-card");
        Label titleLabel = new Label(title); titleLabel.setStyle("-fx-font-size: 13px; -fx-font-weight: bold; -fx-text-fill: " + COLOR_TEXT + ";");
        if (chart instanceof javafx.scene.web.WebView web) { web.setMinHeight(0); web.setPrefHeight(170); web.setMaxHeight(Double.MAX_VALUE); }
        VBox.setVgrow(chart, Priority.ALWAYS);
        card.getChildren().addAll(titleLabel, chart);
        return card;
    }

    public static HBox makeInsightLine(String label, String value, String color) {
        HBox row = new HBox(8); row.setAlignment(Pos.CENTER_LEFT);
        Label dot = new Label("●"); dot.setStyle("-fx-text-fill: " + color + "; -fx-font-size: 11px;");
        Label lbl = new Label(label); lbl.setStyle("-fx-text-fill: " + COLOR_MUTED + "; -fx-font-size: 12px;");
        Region spacer = new Region(); HBox.setHgrow(spacer, Priority.ALWAYS);
        Label val = new Label(value); val.setStyle("-fx-text-fill: " + COLOR_TEXT + "; -fx-font-size: 12px; -fx-font-weight: bold;");
        row.getChildren().addAll(dot, lbl, spacer, val);
        return row;
    }

    public static javafx.scene.web.WebView makeChartWebView(String script) {
        return createChartWebView(chartHtml(script));
    }

    // ── Animations ────────────────────────────────────────────────────────
    public static void fadeIn(Node node) {
        FadeTransition ft = new FadeTransition(Duration.millis(500), node);
        ft.setFromValue(0); ft.setToValue(1); ft.play();
    }

    public static void slideIn(Node node) {
        TranslateTransition tt = new TranslateTransition(Duration.millis(400), node);
        tt.setFromY(24); tt.setToY(0);
        FadeTransition ft = new FadeTransition(Duration.millis(400), node);
        ft.setFromValue(0); ft.setToValue(1);
        new ParallelTransition(tt, ft).play();
    }

    // ── Alert Dialogs ─────────────────────────────────────────────────────
    public static void showError(String title, String message) {
        Alert a = new Alert(Alert.AlertType.ERROR); a.setTitle(title); a.setHeaderText(null); a.setContentText(message);
        styleAlert(a); a.showAndWait();
    }

    public static void showSuccess(String title, String message) {
        Alert a = new Alert(Alert.AlertType.INFORMATION); a.setTitle(title); a.setHeaderText(null); a.setContentText(message);
        styleAlert(a); a.showAndWait();
    }

    public static boolean showConfirmation(String title, String message) {
        Alert a = new Alert(Alert.AlertType.CONFIRMATION); a.setTitle(title); a.setHeaderText(null); a.setContentText(message);
        styleAlert(a);
        return a.showAndWait().map(r -> r == ButtonType.OK).orElse(false);
    }

    private static void styleAlert(Alert alert) {
        alert.getDialogPane().setStyle("-fx-background-color: " + COLOR_SURFACE + "; -fx-font-size: 13px; -fx-text-fill: " + COLOR_TEXT + ";");
        Node c = alert.getDialogPane().lookup(".content.label");
        if (c != null) c.setStyle("-fx-text-fill: " + COLOR_TEXT + ";");
    }

    // ── Glass cell factory ────────────────────────────────────────────────
    public static <S, T> void applyGlassCellFactory(TableColumn<S, T> column) {
        column.setCellFactory(col -> new TableCell<>() {
            @Override protected void updateItem(T item, boolean empty) {
                super.updateItem(item, empty);
                getStyleClass().add("table-cell");
                if (empty || item == null) { setText(null); setGraphic(null); } 
                else { setText(String.valueOf(item)); setGraphic(null); }
            }
        });
    }

    // ── Chart helpers ─────────────────────────────────────────────────────
    public static String escapeJs(String value) {
        if (value == null) return "";
        return value.replace("\\", "\\\\").replace("'", "\\'");
    }

    public static String chartHtml(String script) {
        return "<!DOCTYPE html><html><head><meta charset='UTF-8'>" +
                "<script src='https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js'></script>" +
                "<style>html,body{margin:0;padding:0;width:100%;height:100%;overflow:hidden;background:#0A0F1F;font-family:Arial,sans-serif;}" +
                ".wrap{position:relative;width:100vw;height:100vh;background:linear-gradient(135deg,#0A0F1F,#101729);border-radius:10px;box-sizing:border-box;padding:4px;}" +
                "canvas{width:100% !important;height:100% !important;}" +
                "#centerText{position:absolute;top:52%;left:50%;transform:translate(-50%,-50%);color:#E8EAF0;font-size:28px;font-weight:800;text-shadow:0 0 12px rgba(0,212,255,0.55);}" +
                "#centerText span{font-size:11px;color:#8A94B8;margin-left:3px;}" +
                "</style></head>" +
                "<body><div class='wrap'><canvas id='chart'></canvas><div id='centerText'></div></div>" +
                "<script>Chart.defaults.color='#E8EAF0';Chart.defaults.font.family='Arial';" +
                "Chart.defaults.plugins.tooltip.backgroundColor='rgba(10,15,31,0.95)';" +
                "Chart.defaults.plugins.tooltip.titleColor='#E8EAF0';Chart.defaults.plugins.tooltip.bodyColor='#E8EAF0';" +
                script + "</script></body></html>";
    }

    public static javafx.scene.web.WebView createChartWebView(String html) {
        javafx.scene.web.WebView wv = new javafx.scene.web.WebView();
        wv.setContextMenuEnabled(false);
        wv.setStyle("-fx-background-color: #0A0F1F; -fx-background-radius: 10;");
        wv.getEngine().loadContent(html);
        return wv;
    }

    // ── SplitPane glass styling ───────────────────────────────────────────
    public static void styleGlassSplitPane(SplitPane split) {
        split.getStyleClass().add("glass-split-pane");
        split.setStyle("-fx-background-color: transparent; -fx-background: transparent; -fx-padding: 0;");
        Runnable apply = () -> split.lookupAll(".split-pane-divider").forEach(d ->
            d.setStyle("-fx-background-color: linear-gradient(to bottom,rgba(0,212,255,0.10),rgba(124,92,252,0.12)); -fx-padding: 0 1.5 0 1.5; -fx-border-color: rgba(0,212,255,0.18); -fx-border-width: 0 1 0 1;"));
        split.skinProperty().addListener((obs, o, n) -> { Platform.runLater(apply); Platform.runLater(apply); });
        split.widthProperty().addListener((obs, o, n) -> Platform.runLater(apply));
        Platform.runLater(apply); Platform.runLater(apply);
    }

    // ── Kept for old tab pane compat ──────────────────────────────────────
    public static String getTabPaneStyle() { return "-fx-background-color: " + COLOR_BG + "; -fx-tab-min-height: 40px; -fx-tab-max-height: 40px;"; }
    public static String getTabStyle()     { return "-fx-background-color: " + COLOR_SURFACE2 + "; -fx-text-fill: " + COLOR_MUTED + "; -fx-font-size: 13px; -fx-font-weight: bold; -fx-padding: 8 20; -fx-background-radius: 8 8 0 0;"; }
    public static <T> void applyTableStyle(TableView<T> table) { styleGlassTable(table); }
}