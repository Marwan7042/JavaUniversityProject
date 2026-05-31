package com.university.ui;

import com.university.dao.DatabaseManager;
import com.university.model.*;
import com.university.service.*;
import com.university.util.*;
import javafx.collections.FXCollections;
import javafx.collections.ObservableList;
import javafx.geometry.*;
import javafx.scene.Scene;
import javafx.scene.control.*;
import javafx.scene.control.cell.PropertyValueFactory;
import javafx.scene.layout.*;

import java.util.Map;

/**
 * Screen 5: Course Catalog / Details Screen
 * A dedicated browsable catalog of all courses with full details.
 * Accessible from both Student and Admin dashboards.
 */
public class CourseDetailsScreen {

    private final DatabaseManager db = DatabaseManager.getInstance();
    private final AuthService auth = AuthService.getInstance();
    private final NavigationManager nav = NavigationManager.getInstance();

    public Scene build() {
        BorderPane root = new BorderPane();
        root.setStyle("-fx-background-color: " + UIHelper.COLOR_BG + ";");
        root.setTop(buildTopBar());
        root.setCenter(buildContent());
        return new Scene(root, 1100, 700);
    }

    private HBox buildTopBar() {
        HBox bar = new HBox(16);
        bar.setAlignment(Pos.CENTER_LEFT);
        bar.setPadding(new Insets(16, 24, 16, 24));
        bar.setStyle("-fx-background-color: " + UIHelper.COLOR_SURFACE + ";");

        Label logo = new Label("🎓 UniReg — Course Catalog");
        logo.setStyle("-fx-font-size: 18px; -fx-font-weight: bold; -fx-text-fill: " + UIHelper.COLOR_ACCENT + ";");

        Region spacer = new Region(); HBox.setHgrow(spacer, Priority.ALWAYS);

        Button backBtn = UIHelper.makeSecondaryButton("← Back");
        backBtn.setOnAction(e -> {
            Person user = auth.getCurrentUser();
            if (user instanceof Student) nav.navigateTo(new StudentDashboardScreen().build(), "Student Dashboard");
            else if (user instanceof Admin) nav.navigateTo(new AdminDashboardScreen().build(), "Admin Dashboard");
            else nav.navigateTo(new LoginScreen().build(), "Login");
        });

        bar.getChildren().addAll(logo, spacer, backBtn);
        return bar;
    }

    private SplitPane buildContent() {
        SplitPane split = new SplitPane();
        split.setStyle("-fx-background-color: " + UIHelper.COLOR_BG + ";");

        // Left: course list
        VBox leftPanel = new VBox(12);
        leftPanel.setPadding(new Insets(20));
        leftPanel.setStyle("-fx-background-color: " + UIHelper.COLOR_BG + ";");

        Label title = UIHelper.makeTitle("All Courses");

        Map<String, Course> courseCache = db.getAllCourses();

        // Department filter
        ComboBox<String> deptFilter = new ComboBox<>();
        deptFilter.setPromptText("Filter by Department...");
        deptFilter.getItems().add("All Departments");
        courseCache.values().stream()
                .map(Course::getDepartment).distinct().sorted()
                .forEach(deptFilter.getItems()::add);
        deptFilter.setValue("All Departments");

        TextField searchField = UIHelper.makeTextField("Search courses...");

        TableView<Course> courseTable = new TableView<>();
        courseTable.setStyle("-fx-background-color: " + UIHelper.COLOR_SURFACE + ";");
        courseTable.setColumnResizePolicy(TableView.CONSTRAINED_RESIZE_POLICY);

        TableColumn<Course, String> idCol = new TableColumn<>("ID");
        idCol.setCellValueFactory(new PropertyValueFactory<>("courseId"));
        idCol.setPrefWidth(80);

        TableColumn<Course, String> nameCol = new TableColumn<>("Course");
        nameCol.setCellValueFactory(new PropertyValueFactory<>("courseName"));

        TableColumn<Course, String> statusCol = new TableColumn<>("Status");
        statusCol.setCellValueFactory(d -> {
            Course c = d.getValue();
            String text = c.getStatus() == Course.Status.OPEN ? "OPEN" : "CLOSED";
            return new javafx.beans.property.SimpleStringProperty(text);
        });
        statusCol.setPrefWidth(70);

        courseTable.getColumns().addAll(idCol, nameCol, statusCol);

        ObservableList<Course> allCourses = FXCollections.observableArrayList(courseCache.values());
        courseTable.setItems(allCourses);
        VBox.setVgrow(courseTable, Priority.ALWAYS);

        // Filter logic
        Runnable applyFilter = () -> {
            String dept = deptFilter.getValue();
            String q = searchField.getText().toLowerCase();
            courseTable.setItems(allCourses.filtered(c -> {
                boolean deptMatch = "All Departments".equals(dept) || dept == null || c.getDepartment().equals(dept);
                boolean searchMatch = q.isEmpty() || c.getCourseId().toLowerCase().contains(q)
                        || c.getCourseName().toLowerCase().contains(q);
                return deptMatch && searchMatch;
            }));
        };
        deptFilter.setOnAction(e -> applyFilter.run());
        searchField.textProperty().addListener((o, ov, nv) -> applyFilter.run());

        leftPanel.getChildren().addAll(title, deptFilter, searchField, courseTable);

        // Right: course detail panel
        VBox rightPanel = buildDetailPanel(courseTable);

        split.getItems().addAll(leftPanel, rightPanel);
        split.setDividerPositions(0.38);
        return split;
    }

    private VBox buildDetailPanel(TableView<Course> courseTable) {
        VBox panel = new VBox(16);
        panel.setPadding(new Insets(24));
        panel.setStyle("-fx-background-color: " + UIHelper.COLOR_SURFACE + ";");

        Label placeholder = UIHelper.makeSubtitle("← Select a course to see details");

        courseTable.getSelectionModel().selectedItemProperty().addListener((obs, old, course) -> {
            panel.getChildren().clear();
            if (course == null) { panel.getChildren().add(placeholder); return; }

            Label courseId = UIHelper.makeStatusBadge(course.getCourseId(), UIHelper.COLOR_ACCENT);
            Label courseName = UIHelper.makeTitle(course.getCourseName());
            courseName.setWrapText(true);

            String statusColor = course.getStatus() == Course.Status.OPEN
                    ? UIHelper.COLOR_SUCCESS : UIHelper.COLOR_DANGER;
            Label statusBadge = UIHelper.makeStatusBadge(course.getStatus().name(), statusColor);

            HBox headerRow = new HBox(10, courseId, statusBadge);
            headerRow.setAlignment(Pos.CENTER_LEFT);

            // Meta grid
            GridPane meta = new GridPane();
            meta.setHgap(16); meta.setVgap(10);
            meta.setPadding(new Insets(16));
            meta.setStyle("-fx-background-color: " + UIHelper.COLOR_SURFACE2 + "; -fx-background-radius: 8;");

            addMetaRow(meta, 0, "Department",  course.getDepartment());
            addMetaRow(meta, 1, "Credits",     course.getCredits() + " credit hours");
            addMetaRow(meta, 2, "Instructor",  course.getInstructorName());
            addMetaRow(meta, 3, "Schedule",    course.getSchedule());
            addMetaRow(meta, 4, "Room",        course.getRoom());
            addMetaRow(meta, 5, "Capacity",    course.getEnrolled() + " / " + course.getCapacity() + " enrolled");

            String prereqs = course.getPrerequisiteIds().isEmpty()
                    ? "None" : String.join(", ", course.getPrerequisiteIds());
            addMetaRow(meta, 6, "Prerequisites", prereqs);

            // Seat bar
            double pct = (double) course.getEnrolled() / course.getCapacity();
            ProgressBar seatBar = new ProgressBar(pct);
            seatBar.setPrefWidth(Double.MAX_VALUE);
            seatBar.setStyle(pct > 0.8
                    ? "-fx-accent: " + UIHelper.COLOR_DANGER + ";"
                    : "-fx-accent: " + UIHelper.COLOR_SUCCESS + ";");

            Label seatLabel = UIHelper.makeSubtitle(course.getAvailableSeats() + " seats remaining");

            // Description
            Label descTitle = UIHelper.makeLabel("About this course:");
            descTitle.setStyle(descTitle.getStyle() + "-fx-font-weight: bold;");
            Label desc = new Label(course.getDescription());
            desc.setWrapText(true);
            desc.setStyle("-fx-text-fill: " + UIHelper.COLOR_MUTED + "; -fx-font-size: 13px;");

            // Enrolled students count
                    long enrolled = db.getAllStudents().values().stream()
                    .filter(s -> s.isEnrolledIn(course.getCourseId())).count();
            Label enrolledLabel = UIHelper.makeStatusBadge("👥 " + enrolled + " students enrolled",
                    UIHelper.COLOR_ACCENT2);

            panel.getChildren().addAll(
                headerRow, courseName, UIHelper.makeSeparator(),
                meta, seatBar, seatLabel,
                UIHelper.makeSeparator(), descTitle, desc, enrolledLabel
            );
            UIHelper.slideIn(panel);
        });

        panel.getChildren().add(placeholder);
        return panel;
    }

    private void addMetaRow(GridPane grid, int row, String key, String value) {
        Label k = UIHelper.makeLabel(key + ":");
        k.setStyle(k.getStyle() + "-fx-text-fill: " + UIHelper.COLOR_MUTED + "; -fx-font-size: 12px;");
        Label v = UIHelper.makeLabel(value);
        v.setStyle(v.getStyle() + "-fx-font-weight: bold;");
        grid.addRow(row, k, v);
    }
}
