package com.university.ui;

import com.university.dao.DatabaseManager;
import com.university.model.*;
import com.university.service.AdminPermissionService;
import com.university.service.AdminPermissionService.Permission;
import com.university.util.*;
import com.university.util.GlassTable;
import javafx.collections.*;
import javafx.geometry.*;
import javafx.scene.Node;
import javafx.scene.control.*;
import javafx.scene.layout.*;

import java.sql.*;
import java.time.LocalDate;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Optimized Admin Dashboard.
 *
 * Restores the missing admin features without returning to the huge old GUI:
 * - real dashboard insights
 * - students management with year 1-7
 * - instructors management with Teaching Assistant support
 * - advanced course/offering form
 * - saves course_offerings + course_instructors + room_schedule through CourseDAO
 * - academic settings / registration periods
 * - admin account management with SUPER/MODERATOR/STANDARD permissions
 * - schedule/room conflict monitor
 */
public class AdminDashboardScreen extends BaseDashboardScreen {

    private final DatabaseManager db = DatabaseManager.getInstance();

    private Admin currentAdmin() {
        return (Admin) auth.getCurrentUser();
    }

    private boolean can(Permission permission) {
        return AdminPermissionService.hasPermission(currentAdmin(), permission);
    }

    private boolean checkPermission(Permission permission) {
        if (!can(permission)) {
            UIHelper.showError("Access Denied", "Your admin level does not allow this action.");
            return false;
        }
        return true;
    }

    private void configurePermissionButton(Button button, Permission permission) {
        if (!can(permission)) {
            button.setDisable(true);
            button.setTooltip(new Tooltip("Not allowed for your admin level."));
            button.setStyle(button.getStyle() + "-fx-opacity: 0.45;");
        }
    }

    private Label makeReadOnlyBadge() {
        return UIHelper.makeStatusBadge("READ ONLY", UIHelper.COLOR_WARNING);
    }

    private Map<String, Student> studentsCache;
    private Map<String, Instructor> instructorsCache;
    private Map<String, Course> coursesCache;

    @Override
    protected Node[] topBarInfoNodes() {
        Admin admin = currentAdmin();

        Label info = UIHelper.makeLabel("🛡  " + admin.getFullName());
        info.setStyle(info.getStyle() + "-fx-text-fill: " + UIHelper.COLOR_MUTED + ";");

        return new Node[]{
                info,
                UIHelper.makeStatusBadge(admin.getAdminLevel(), UIHelper.COLOR_ACCENT2)
        };
    }

    @Override
    protected VBox buildSidebarContent() {
        refreshCaches();

        long openOfferings = courses().values().stream()
                .filter(c -> c.getStatus() == Course.Status.OPEN)
                .count();

        VBox sidebar = new VBox(14);

        Label lbl = UIHelper.makeSubtitle("SYSTEM OVERVIEW");
        lbl.setStyle(lbl.getStyle() + "-fx-font-size:10px;-fx-font-weight:bold;-fx-text-fill:#7D88AA;");

        sidebar.getChildren().addAll(
                lbl,
                UIHelper.makeStatCard("👨‍🎓", "Students", students().size(), UIHelper.COLOR_ACCENT),
                UIHelper.makeStatCard("👨‍🏫", "Instructors", instructors().size(), UIHelper.COLOR_ACCENT2),
                UIHelper.makeStatCard("📚", "Offerings", courses().size(), UIHelper.COLOR_SUCCESS),
                UIHelper.makeStatCard("🟢", "Open", (int) openOfferings, UIHelper.COLOR_WARNING),
                UIHelper.makeSeparator(),
                buildProfileCard("🛡", auth.getCurrentUser().getId(), auth.getCurrentUser().getEmail())
        );

        return sidebar;
    }

    @Override
    protected Node buildContent() {
        ChromeTabPane tabs = new ChromeTabPane();
        tabs.setStyle("-fx-background-color: transparent;");

        if (can(Permission.VIEW_STUDENTS)) {
            tabs.addTab(new ChromeTab("👨‍🎓 Students", this::buildStudentsPanel));
        }

        if (can(Permission.VIEW_INSTRUCTORS)) {
            tabs.addTab(new ChromeTab("👨‍🏫 Instructors", this::buildInstructorsPanel));
        }

        if (can(Permission.VIEW_COURSES)) {
            tabs.addTab(new ChromeTab("📘 Courses", this::buildCourseCatalogPanel));
            tabs.addTab(new ChromeTab("🧩 Course Offerings", () -> new AdminCourseOfferingsPanel(this::can, this::checkPermission).build()));
        }

        if (can(Permission.VIEW_ACADEMIC_SETTINGS) || can(Permission.MANAGE_REGISTRATION_PERIODS)) {
            tabs.addTab(new ChromeTab("⚙ Academic Settings", this::buildAcademicSettingsPanel));
        }

        if (can(Permission.MANAGE_ADMINS)) {
            tabs.addTab(new ChromeTab("🛡 Admins", this::buildAdminsPanel));
        }

        tabs.addTab(new ChromeTab("📊 Analytics", this::buildDashboardPanel));

        return tabs;
    }

    private void refreshCaches() {
        studentsCache = db.getAllStudents();
        instructorsCache = db.getAllInstructors();
        coursesCache = db.getAllCourses();
    }

    private Map<String, Student> students() {
        if (studentsCache == null) studentsCache = db.getAllStudents();
        return studentsCache;
    }

    private Map<String, Instructor> instructors() {
        if (instructorsCache == null) instructorsCache = db.getAllInstructors();
        return instructorsCache;
    }

    private Map<String, Course> courses() {
        if (coursesCache == null) coursesCache = db.getAllCourses();
        return coursesCache;
    }

    // ── Dashboard ─────────────────────────────────────────────────────────

    private VBox buildDashboardPanel() {
        refreshCaches();

        long activeEnrollments = students().values().stream()
                .flatMap(s -> s.getEnrollments().stream())
                .filter(e -> e.getStatus() == Enrollment.Status.ENROLLED)
                .count();

        long completedEnrollments = students().values().stream()
                .flatMap(s -> s.getEnrollments().stream())
                .filter(e -> e.getStatus() == Enrollment.Status.COMPLETED)
                .count();

        double avgGpa = students().values().stream()
                .mapToDouble(Student::getGpa)
                .average()
                .orElse(0.0);

        long openOfferings = courses().values().stream()
                .filter(c -> c.getStatus() == Course.Status.OPEN)
                .count();

        HBox kpis = new HBox(12,
                UIHelper.makeKpiCard("Students", String.valueOf(students().size()), "registered accounts", UIHelper.COLOR_ACCENT),
                UIHelper.makeKpiCard("Instructors", String.valueOf(instructors().size()), "teaching staff", UIHelper.COLOR_ACCENT2),
                UIHelper.makeKpiCard("Active Enrollments", String.valueOf(activeEnrollments), "current registrations", UIHelper.COLOR_SUCCESS),
                UIHelper.makeKpiCard("Average GPA", String.format("%.2f", avgGpa), "student average", UIHelper.COLOR_WARNING)
        );

        GridPane grid = makeAnalyticsGrid();
        grid.add(buildMajorSummaryCard(), 0, 0);
        grid.add(buildCourseLoadCard(), 1, 0);
        grid.add(buildSystemHealthCard(activeEnrollments, completedEnrollments, openOfferings), 2, 0);
        grid.add(buildAtRiskStudentsCard(), 0, 1, 3, 1);

        VBox panel = new VBox(14,
                headerRow("Admin Analytics Center", "Useful operational view for registration, teaching load, and student risk.", openOfferings + " Open Offerings", UIHelper.COLOR_SUCCESS),
                kpis,
                grid
        );

        panel.setPadding(new Insets(20, 24, 20, 24));
        panel.setStyle("-fx-background-color: transparent;");
        VBox.setVgrow(grid, Priority.ALWAYS);

        return panel;
    }

    private VBox buildMajorSummaryCard() {
        Map<String, Long> byMajor = students().values().stream()
                .collect(Collectors.groupingBy(Student::getMajor, LinkedHashMap::new, Collectors.counting()));

        VBox list = new VBox(6);
        byMajor.entrySet().stream()
                .sorted(Map.Entry.<String, Long>comparingByValue().reversed())
                .limit(8)
                .forEach(e -> list.getChildren().add(UIHelper.makeInsightLine(e.getKey(), String.valueOf(e.getValue()), UIHelper.COLOR_ACCENT)));

        VBox card = cardShell("Students by Major", "Top represented programs");
        card.getChildren().add(list);
        return card;
    }

    private VBox buildCourseLoadCard() {
        VBox list = new VBox(6);

        courses().values().stream()
                .sorted(Comparator.comparingInt(Course::getEnrolled).reversed())
                .limit(8)
                .forEach(c -> list.getChildren().add(UIHelper.makeInsightLine(
                        c.getCourseId() + " " + safe(c.getSectionCode()),
                        c.getEnrolled() + "/" + c.getCapacity(),
                        c.getEnrolled() >= c.getCapacity() ? UIHelper.COLOR_DANGER : UIHelper.COLOR_SUCCESS
                )));

        VBox card = cardShell("Course Load", "Most occupied offerings");
        card.getChildren().add(list);
        return card;
    }

    private VBox buildSystemHealthCard(long activeEnrollments, long completedEnrollments, long openOfferings) {
        long totalOfferings = courses().size();
        long closedOfferings = totalOfferings - openOfferings;
        long scheduleRows = countQuery("SELECT COUNT(*) FROM room_schedule");

        VBox lines = new VBox(7,
                UIHelper.makeInsightLine("Open offerings", String.valueOf(openOfferings), UIHelper.COLOR_SUCCESS),
                UIHelper.makeInsightLine("Closed/completed offerings", String.valueOf(closedOfferings), UIHelper.COLOR_WARNING),
                UIHelper.makeInsightLine("Active enrollments", String.valueOf(activeEnrollments), UIHelper.COLOR_ACCENT),
                UIHelper.makeInsightLine("Completed records", String.valueOf(completedEnrollments), UIHelper.COLOR_ACCENT2),
                UIHelper.makeInsightLine("Schedule rows", String.valueOf(scheduleRows), UIHelper.COLOR_SUCCESS)
        );

        VBox card = cardShell("System Health", "Database-backed operational status");
        card.getChildren().add(lines);
        return card;
    }

    private VBox buildAtRiskStudentsCard() {
        ObservableList<Student> atRisk = FXCollections.observableArrayList(
                students().values().stream()
                        .filter(s -> s.getGpa() > 0 && s.getGpa() < 2.0)
                        .sorted(Comparator.comparingDouble(Student::getGpa))
                        .limit(12)
                        .toList()
        );

        TableView<Student> table = GlassTable.<Student>create()
                .prop("ID", "id")
                .col("Name", Student::getFullName)
                .prop("Major", "major")
                .col("Year", Student::getYearLabel)
                .col("GPA", s -> String.format("%.2f", s.getGpa()))
                .prefHeight(230)
                .build();

        table.setItems(atRisk);

        VBox card = cardShell("At-Risk Watchlist", "Students below GPA 2.00");
        card.getChildren().add(table);
        VBox.setVgrow(table, Priority.ALWAYS);

        return card;
    }

    // ── Students ──────────────────────────────────────────────────────────

    private VBox buildStudentsPanel() {
        ObservableList<Student> all = FXCollections.observableArrayList(students().values());

        Runnable refresh = () -> {
            studentsCache = db.getAllStudents();
            all.setAll(studentsCache.values());
        };

        TableView<Student> table = GlassTable.<Student>create()
                .prop("ID", "id")
                .col("Full Name", Student::getFullName)
                .prop("Email", "email")
                .prop("Major", "major")
                .col("Year", Student::getYearLabel)
                .col("GPA", s -> String.format("%.2f", s.getGpa()))
                .build();

        table.setItems(all);
        VBox.setVgrow(table, Priority.ALWAYS);

        TextField search = UIHelper.makeTextField("🔍 Search by name, email, major, or ID...");
        HBox.setHgrow(search, Priority.ALWAYS);

        search.textProperty().addListener((o, oldValue, q) -> table.setItems(filterStudents(all, q)));

        Button addBtn = UIHelper.makePrimaryButton("➕ Add Student");
        Button delBtn = UIHelper.makeDangerButton("🗑 Delete Selected");

        configurePermissionButton(addBtn, Permission.MANAGE_STUDENTS);
        configurePermissionButton(delBtn, Permission.DELETE_RECORDS);

        addBtn.setOnAction(e -> {
            if (!checkPermission(Permission.MANAGE_STUDENTS)) return;
            showAddStudentDialog(refresh);
        });

        delBtn.setOnAction(e -> {
            Student selected = table.getSelectionModel().getSelectedItem();

            if (selected == null) {
                UIHelper.showError("No Selection", "Select a student first.");
                return;
            }

            if (!UIHelper.showConfirmation("Delete Student", "Delete " + selected.getFullName() + "?")) return;

            try {
                db.deleteStudent(selected.getId());
                refresh.run();
            } catch (RuntimeException ex) {
                UIHelper.showError("Delete Failed", rootCauseMessage(ex));
            }
        });

        VBox panel = panel();
        panel.getChildren().addAll(
                headerRow("Manage Students", "Add, search, and remove student accounts.", all.size() + " Students", UIHelper.COLOR_ACCENT),
                new HBox(10, search, addBtn, delBtn),
                table
        );

        return panel;
    }

    private ObservableList<Student> filterStudents(ObservableList<Student> all, String query) {
        String q = query == null ? "" : query.trim().toLowerCase();

        if (q.isBlank()) return all;

        return all.filtered(s ->
                safe(s.getId()).toLowerCase().contains(q)
                        || safe(s.getFullName()).toLowerCase().contains(q)
                        || safe(s.getEmail()).toLowerCase().contains(q)
                        || safe(s.getMajor()).toLowerCase().contains(q)
        );
    }

    private void showAddStudentDialog(Runnable refresh) {
        if (!checkPermission(Permission.MANAGE_STUDENTS)) return;
        TextField firstName = UIHelper.makeTextField("First Name");
        TextField lastName = UIHelper.makeTextField("Last Name");
        TextField email = UIHelper.makeTextField("Email");
        TextField phone = UIHelper.makeTextField("Phone");
        PasswordField password = UIHelper.makePasswordField("Password");

        ComboBox<String> major = stringCombo(loadOptions("SELECT major_name FROM majors ORDER BY major_name"), "Major");
        ComboBox<Integer> year = new ComboBox<>(FXCollections.observableArrayList(1, 2, 3, 4, 5, 6, 7));
        year.setPromptText("Year");

        GridPane grid = formGrid(
                "First Name", firstName,
                "Last Name", lastName,
                "Email", email,
                "Phone", phone,
                "Major", major,
                "Year", year,
                "Password", password
        );

        showDialog("Add New Student", grid, () -> {
            try {
                require(firstName, "First name");
                require(lastName, "Last name");
                require(email, "Email");
                require(password, "Password");

                String id = db.generateStudentId();
                db.insertStudent(new Student(
                        id,
                        firstName.getText().trim(),
                        lastName.getText().trim(),
                        email.getText().trim(),
                        password.getText().trim(),
                        phone.getText().trim(),
                        valueOrDefault(major.getValue(), "Computer Science"),
                        year.getValue() == null ? 1 : year.getValue()
                ));

                refresh.run();
            } catch (Exception ex) {
                UIHelper.showError("Student Save Failed", rootCauseMessage(ex));
            }
        });
    }

    // ── Instructors ───────────────────────────────────────────────────────

    private VBox buildInstructorsPanel() {
        ObservableList<Instructor> all = FXCollections.observableArrayList(instructors().values());

        Runnable refresh = () -> {
            instructorsCache = db.getAllInstructors();
            all.setAll(instructorsCache.values());
        };

        TableView<Instructor> table = GlassTable.<Instructor>create()
                .prop("ID", "id")
                .col("Full Name", Instructor::getFullName)
                .prop("Email", "email")
                .prop("Department", "department")
                .prop("Title", "title")
                .col("Offerings", i -> String.valueOf(i.getOfferingIds().size()))
                .build();

        table.setItems(all);
        VBox.setVgrow(table, Priority.ALWAYS);

        TextField search = UIHelper.makeTextField("🔍 Search by name, email, department, or title...");
        HBox.setHgrow(search, Priority.ALWAYS);

        search.textProperty().addListener((o, oldValue, q) -> table.setItems(filterInstructors(all, q)));

        Button addBtn = UIHelper.makePrimaryButton("➕ Add Instructor");
        Button delBtn = UIHelper.makeDangerButton("🗑 Delete Selected");

        configurePermissionButton(addBtn, Permission.MANAGE_INSTRUCTORS);
        configurePermissionButton(delBtn, Permission.DELETE_RECORDS);

        addBtn.setOnAction(e -> {
            if (!checkPermission(Permission.MANAGE_INSTRUCTORS)) return;
            showAddInstructorDialog(refresh);
        });

        delBtn.setOnAction(e -> {
            Instructor selected = table.getSelectionModel().getSelectedItem();

            if (selected == null) {
                UIHelper.showError("No Selection", "Select an instructor first.");
                return;
            }

            if (!UIHelper.showConfirmation("Delete Instructor", "Delete " + selected.getFullName() + "?")) return;

            try {
                db.deleteInstructor(selected.getId());
                refresh.run();
            } catch (RuntimeException ex) {
                UIHelper.showError("Delete Failed", rootCauseMessage(ex));
            }
        });

        VBox panel = panel();
        panel.getChildren().addAll(
                headerRow("Manage Instructors", "Add teaching staff and assign them later in course offerings.", all.size() + " Staff", UIHelper.COLOR_ACCENT2),
                new HBox(10, search, addBtn, delBtn),
                table
        );

        return panel;
    }

    private ObservableList<Instructor> filterInstructors(ObservableList<Instructor> all, String query) {
        String q = query == null ? "" : query.trim().toLowerCase();

        if (q.isBlank()) return all;

        return all.filtered(i ->
                safe(i.getId()).toLowerCase().contains(q)
                        || safe(i.getFullName()).toLowerCase().contains(q)
                        || safe(i.getEmail()).toLowerCase().contains(q)
                        || safe(i.getDepartment()).toLowerCase().contains(q)
                        || safe(i.getTitle()).toLowerCase().contains(q)
        );
    }

    private void showAddInstructorDialog(Runnable refresh) {
        if (!checkPermission(Permission.MANAGE_INSTRUCTORS)) return;
        TextField firstName = UIHelper.makeTextField("First Name");
        TextField lastName = UIHelper.makeTextField("Last Name");
        TextField email = UIHelper.makeTextField("Email");
        TextField phone = UIHelper.makeTextField("Phone");
        PasswordField password = UIHelper.makePasswordField("Password");

        ComboBox<String> department = stringCombo(loadOptions("SELECT department_name FROM departments ORDER BY department_name"), "Department");
        ComboBox<String> title = stringCombo(List.of(
                "Professor",
                "Associate Professor",
                "Assistant Professor",
                "Lecturer",
                "Teaching Assistant"
        ), "Title");

        GridPane grid = formGrid(
                "First Name", firstName,
                "Last Name", lastName,
                "Email", email,
                "Phone", phone,
                "Department", department,
                "Title", title,
                "Password", password
        );

        showDialog("Add New Instructor", grid, () -> {
            try {
                require(firstName, "First name");
                require(lastName, "Last name");
                require(email, "Email");
                require(password, "Password");

                String id = db.generateInstructorId();
                db.insertInstructor(new Instructor(
                        id,
                        firstName.getText().trim(),
                        lastName.getText().trim(),
                        email.getText().trim(),
                        password.getText().trim(),
                        phone.getText().trim(),
                        valueOrDefault(department.getValue(), "Computer Science & Informatics"),
                        valueOrDefault(title.getValue(), "Lecturer")
                ));

                refresh.run();
            } catch (Exception ex) {
                UIHelper.showError("Instructor Save Failed", rootCauseMessage(ex));
            }
        });
    }

    // ── Courses Catalog ────────────────────────────────────────────────────

    private VBox buildCourseCatalogPanel() {
        ObservableList<Course> catalog = FXCollections.observableArrayList(db.getCourseCatalog().values());

        Runnable refresh = () -> catalog.setAll(db.getCourseCatalog().values());

        TableView<Course> table = GlassTable.<Course>create()
                .prop("Course", "courseId")
                .prop("Name", "courseName")
                .prop("Department", "department")
                .col("Credits", c -> String.valueOf(c.getCredits()))
                .col("Plan Uses", c -> String.valueOf(db.getPlanCountForCourse(c.getCourseId())))
                .col("Offerings", c -> String.valueOf(countQuery("SELECT COUNT(*) FROM course_offerings WHERE course_id = '" + c.getCourseId().replace("'", "''") + "'")))
                .build();

        table.setItems(catalog);
        VBox.setVgrow(table, Priority.ALWAYS);

        TextField search = UIHelper.makeTextField("🔍 Search course ID, name, department, or description...");
        HBox.setHgrow(search, Priority.ALWAYS);

        search.textProperty().addListener((o, oldValue, q) -> {
            String query = q == null ? "" : q.trim().toLowerCase();

            if (query.isBlank()) {
                table.setItems(catalog);
                return;
            }

            table.setItems(catalog.filtered(c ->
                    safe(c.getCourseId()).toLowerCase().contains(query)
                            || safe(c.getCourseName()).toLowerCase().contains(query)
                            || safe(c.getDepartment()).toLowerCase().contains(query)
                            || safe(c.getDescription()).toLowerCase().contains(query)
            ));
        });

        Button addBtn = UIHelper.makePrimaryButton("➕ Add Course");
        Button editBtn = UIHelper.makeSecondaryButton("✏ Edit Course");
        Button delBtn = UIHelper.makeDangerButton("🗑 Delete Course");

        configurePermissionButton(addBtn, Permission.MANAGE_COURSE_OFFERINGS);
        configurePermissionButton(editBtn, Permission.MANAGE_COURSE_OFFERINGS);
        configurePermissionButton(delBtn, Permission.DELETE_RECORDS);

        addBtn.setOnAction(e -> {
            if (!checkPermission(Permission.MANAGE_COURSE_OFFERINGS)) return;
            showCatalogCourseDialog(null, refresh);
        });

        editBtn.setOnAction(e -> {
            if (!checkPermission(Permission.MANAGE_COURSE_OFFERINGS)) return;

            Course selected = table.getSelectionModel().getSelectedItem();

            if (selected == null) {
                UIHelper.showError("No Selection", "Select a catalog course first.");
                return;
            }

            showCatalogCourseDialog(selected, refresh);
        });

        delBtn.setOnAction(e -> {
            if (!checkPermission(Permission.DELETE_RECORDS)) return;

            Course selected = table.getSelectionModel().getSelectedItem();

            if (selected == null) {
                UIHelper.showError("No Selection", "Select a catalog course first.");
                return;
            }

            int offeringCount = (int) countQuery("SELECT COUNT(*) FROM course_offerings WHERE course_id = '" + selected.getCourseId().replace("'", "''") + "'");

            String warning = offeringCount > 0
                    ? "This course already has " + offeringCount + " offering(s). Deleting it will also delete related offerings, schedules, enrollments, and scores."
                    : "Delete " + selected.getCourseName() + "?";

            if (!UIHelper.showConfirmation("Delete Course", warning)) return;

            try {
                db.deleteCatalogCourse(selected.getCourseId());
                refresh.run();
                coursesCache = db.getAllCourses();
            } catch (RuntimeException ex) {
                UIHelper.showError("Delete Failed", rootCauseMessage(ex));
            }
        });

        VBox detail = buildCatalogCourseDetailPanel(table);

        SplitPane split = new SplitPane(table, detail);
        UIHelper.styleGlassSplitPane(split);
        split.setDividerPositions(0.62);
        VBox.setVgrow(split, Priority.ALWAYS);

        VBox panel = panel();
        panel.getChildren().addAll(
                headerRow("Courses Catalog", "Base course list only. No rooms, instructors, sections, or schedules here.", catalog.size() + " Courses", UIHelper.COLOR_ACCENT),
                new HBox(10, search, addBtn, editBtn, delBtn),
                split
        );

        return panel;
    }

    private VBox buildCatalogCourseDetailPanel(TableView<Course> table) {
        VBox box = cardShell("Course Details", "Select a catalog course.");

        table.getSelectionModel().selectedItemProperty().addListener((obs, old, c) -> {
            box.getChildren().clear();

            if (c == null) {
                box.getChildren().addAll(
                        styledLabel("Course Details", 13, UIHelper.COLOR_TEXT),
                        UIHelper.makeSubtitle("Select a catalog course.")
                );
                return;
            }

            long planUses = db.getPlanCountForCourse(c.getCourseId());
            long offeringCount = countQuery("SELECT COUNT(*) FROM course_offerings WHERE course_id = '" + c.getCourseId().replace("'", "''") + "'");

            box.getChildren().addAll(
                    styledLabel(c.getCourseId() + " • " + c.getCourseName(), 18, UIHelper.COLOR_TEXT),
                    UIHelper.makeStatusBadge(c.getCredits() + " Credits", UIHelper.COLOR_ACCENT),
                    UIHelper.makeSeparator(),
                    UIHelper.makeInsightLine("Department", safe(c.getDepartment()), UIHelper.COLOR_ACCENT),
                    UIHelper.makeInsightLine("Used in academic plans", String.valueOf(planUses), UIHelper.COLOR_ACCENT2),
                    UIHelper.makeInsightLine("Created offerings", String.valueOf(offeringCount), UIHelper.COLOR_SUCCESS),
                    UIHelper.makeSeparator(),
                    UIHelper.makeSubtitle(safe(c.getDescription()))
            );
        });

        return box;
    }

    private void showCatalogCourseDialog(Course existing, Runnable refresh) {
        TextField courseId = UIHelper.makeTextField("e.g. CS101");
        TextField name = UIHelper.makeTextField("Course name");
        ComboBox<String> department = stringCombo(loadOptions("SELECT department_name FROM departments ORDER BY department_name"), "Department");
        TextField credits = UIHelper.makeTextField("Credits");
        TextField description = UIHelper.makeTextField("Description");

        if (existing != null) {
            courseId.setText(existing.getCourseId());
            courseId.setDisable(true);
            name.setText(existing.getCourseName());
            department.setValue(existing.getDepartment());
            credits.setText(String.valueOf(existing.getCredits()));
            description.setText(existing.getDescription());
        } else {
            credits.setText("3");
        }

        GridPane grid = formGrid(
                "Course ID", courseId,
                "Name", name,
                "Department", department,
                "Credits", credits,
                "Description", description
        );

        showDialog(existing == null ? "Add Catalog Course" : "Edit Catalog Course", grid, () -> {
            try {
                require(courseId, "Course ID");
                require(name, "Course name");

                Course c = existing == null ? new Course() : existing;
                c.setCourseId(courseId.getText().trim().toUpperCase());
                c.setCourseName(name.getText().trim());
                c.setDepartment(valueOrDefault(department.getValue(), "Computer Science & Informatics"));
                c.setCredits(parseInt(credits.getText(), 3));
                c.setDescription(description.getText() == null ? "" : description.getText().trim());

                db.insertCatalogCourse(c);
                refresh.run();
            } catch (Exception ex) {
                UIHelper.showError("Course Save Failed", rootCauseMessage(ex));
            }
        });
    }

    // ── Courses / Offerings ───────────────────────────────────────────────

    // ── Academic Settings / Registration Periods ──────────────────────────

    private VBox buildAcademicSettingsPanel() {
        ObservableList<RegistrationPeriod> all = FXCollections.observableArrayList(db.getAllRegistrationPeriods());

        Runnable refresh = () -> all.setAll(db.getAllRegistrationPeriods());

        TableView<RegistrationPeriod> table = GlassTable.<RegistrationPeriod>create()
                .col("ID", p -> String.valueOf(p.getPeriodId()))
                .prop("Term", "term")
                .col("Year", p -> String.valueOf(p.getAcademicYear()))
                .prop("Add Start", "addStartDate")
                .prop("Add End", "addEndDate")
                .prop("Drop End", "dropEndDate")
                .statusCol("Status", RegistrationPeriod::getStatus)
                .build();

        table.setItems(all);
        VBox.setVgrow(table, Priority.ALWAYS);

        TextField search = UIHelper.makeTextField("🔍 Search by term, year, or status...");
        HBox.setHgrow(search, Priority.ALWAYS);

        search.textProperty().addListener((obs, oldValue, q) -> {
            String query = q == null ? "" : q.trim().toLowerCase();

            if (query.isBlank()) {
                table.setItems(all);
                return;
            }

            table.setItems(all.filtered(p ->
                    safe(p.getTerm()).toLowerCase().contains(query)
                            || String.valueOf(p.getAcademicYear()).contains(query)
                            || safe(p.getStatus()).toLowerCase().contains(query)
            ));
        });

        Button addBtn = UIHelper.makePrimaryButton("➕ Add Period");
        Button editBtn = UIHelper.makeSecondaryButton("✏ Edit Selected");
        Button toggleBtn = UIHelper.makeSecondaryButton("🔄 Toggle Open/Closed");
        Button delBtn = UIHelper.makeDangerButton("🗑 Delete Selected");

        configurePermissionButton(addBtn, Permission.MANAGE_REGISTRATION_PERIODS);
        configurePermissionButton(editBtn, Permission.MANAGE_REGISTRATION_PERIODS);
        configurePermissionButton(toggleBtn, Permission.MANAGE_REGISTRATION_PERIODS);
        configurePermissionButton(delBtn, Permission.DELETE_RECORDS);

        addBtn.setOnAction(e -> {
            if (!checkPermission(Permission.MANAGE_REGISTRATION_PERIODS)) return;
            showRegistrationPeriodDialog(null, refresh);
        });

        editBtn.setOnAction(e -> {
            if (!checkPermission(Permission.MANAGE_REGISTRATION_PERIODS)) return;

            RegistrationPeriod selected = table.getSelectionModel().getSelectedItem();

            if (selected == null) {
                UIHelper.showError("No Selection", "Select a registration period first.");
                return;
            }

            showRegistrationPeriodDialog(selected, refresh);
        });

        toggleBtn.setOnAction(e -> {
            if (!checkPermission(Permission.MANAGE_REGISTRATION_PERIODS)) return;

            RegistrationPeriod selected = table.getSelectionModel().getSelectedItem();

            if (selected == null) {
                UIHelper.showError("No Selection", "Select a registration period first.");
                return;
            }

            selected.setStatus("OPEN".equalsIgnoreCase(selected.getStatus()) ? "CLOSED" : "OPEN");

            try {
                db.saveRegistrationPeriod(selected);
                refresh.run();
            } catch (RuntimeException ex) {
                UIHelper.showError("Save Failed", rootCauseMessage(ex));
            }
        });

        delBtn.setOnAction(e -> {
            if (!checkPermission(Permission.DELETE_RECORDS)) return;

            RegistrationPeriod selected = table.getSelectionModel().getSelectedItem();

            if (selected == null) {
                UIHelper.showError("No Selection", "Select a registration period first.");
                return;
            }

            if (!UIHelper.showConfirmation("Delete Period", "Delete " + selected.getTerm() + " " + selected.getAcademicYear() + "?")) return;

            try {
                db.deleteRegistrationPeriod(selected.getPeriodId());
                refresh.run();
            } catch (RuntimeException ex) {
                UIHelper.showError("Delete Failed", rootCauseMessage(ex));
            }
        });

        VBox panel = panel();
        panel.getChildren().addAll(
                headerRow("Academic Settings", "Control when students can add or drop courses for each term.", all.size() + " Periods", UIHelper.COLOR_ACCENT2),
                new HBox(10, search, addBtn, editBtn, toggleBtn, delBtn),
                table
        );

        return panel;
    }

    private void showRegistrationPeriodDialog(RegistrationPeriod existing, Runnable refresh) {
        ComboBox<String> term = stringCombo(List.of("TERM1", "TERM2", "SUMMER"), "Term");
        TextField year = UIHelper.makeTextField("Academic Year");
        DatePicker addStart = new DatePicker();
        DatePicker addEnd = new DatePicker();
        DatePicker dropEnd = new DatePicker();
        ComboBox<String> status = stringCombo(List.of("OPEN", "CLOSED"), "Status");

        if (existing == null) {
            term.setValue("TERM1");
            year.setText("2026");
            addStart.setValue(LocalDate.now());
            addEnd.setValue(LocalDate.now().plusDays(14));
            dropEnd.setValue(LocalDate.now().plusDays(21));
            status.setValue("OPEN");
        } else {
            term.setValue(existing.getTerm());
            year.setText(String.valueOf(existing.getAcademicYear()));
            addStart.setValue(existing.getAddStartDate());
            addEnd.setValue(existing.getAddEndDate());
            dropEnd.setValue(existing.getDropEndDate());
            status.setValue(existing.getStatus());
        }

        GridPane grid = formGrid(
                "Term", term,
                "Academic Year", year,
                "Add Start", addStart,
                "Add End", addEnd,
                "Drop End", dropEnd,
                "Status", status
        );

        showDialog(existing == null ? "Add Registration Period" : "Edit Registration Period", grid, () -> {
            try {
                if (addStart.getValue() == null || addEnd.getValue() == null || dropEnd.getValue() == null) {
                    throw new IllegalArgumentException("All dates are required.");
                }

                if (addStart.getValue().isAfter(addEnd.getValue()) || addEnd.getValue().isAfter(dropEnd.getValue())) {
                    throw new IllegalArgumentException("Date order must be: Add Start <= Add End <= Drop End.");
                }

                RegistrationPeriod p = existing == null ? new RegistrationPeriod() : existing;
                p.setTerm(valueOrDefault(term.getValue(), "TERM1"));
                p.setAcademicYear(parseInt(year.getText(), 2026));
                p.setAddStartDate(addStart.getValue());
                p.setAddEndDate(addEnd.getValue());
                p.setDropEndDate(dropEnd.getValue());
                p.setStatus(valueOrDefault(status.getValue(), "OPEN"));

                db.saveRegistrationPeriod(p);
                refresh.run();
            } catch (Exception ex) {
                UIHelper.showError("Period Save Failed", rootCauseMessage(ex));
            }
        });
    }

    // ── Admins ─────────────────────────────────────────────────────────────

    private VBox buildAdminsPanel() {
        ObservableList<Admin> all = FXCollections.observableArrayList(db.getAllAdmins().values());

        Runnable refresh = () -> all.setAll(db.getAllAdmins().values());

        TableView<Admin> table = GlassTable.<Admin>create()
                .prop("ID", "id")
                .col("Name", Admin::getFullName)
                .prop("Email", "email")
                .statusCol("Level", Admin::getAdminLevel)
                .build();

        table.setItems(all);
        VBox.setVgrow(table, Priority.ALWAYS);

        TextField search = UIHelper.makeTextField("🔍 Search admin name, email, or level...");
        HBox.setHgrow(search, Priority.ALWAYS);

        search.textProperty().addListener((obs, oldValue, q) -> {
            String query = q == null ? "" : q.trim().toLowerCase();

            if (query.isBlank()) {
                table.setItems(all);
                return;
            }

            table.setItems(all.filtered(a ->
                    safe(a.getId()).toLowerCase().contains(query)
                            || safe(a.getFullName()).toLowerCase().contains(query)
                            || safe(a.getEmail()).toLowerCase().contains(query)
                            || safe(a.getAdminLevel()).toLowerCase().contains(query)
            ));
        });

        VBox detail = cardShell("Admin Details", "Select an admin to see effective permissions.");
        table.getSelectionModel().selectedItemProperty().addListener((obs, old, admin) -> updateAdminDetail(detail, admin));
        if (!all.isEmpty()) table.getSelectionModel().selectFirst();

        Button addBtn = UIHelper.makePrimaryButton("➕ Add Admin");
        Button editBtn = UIHelper.makeSecondaryButton("✏ Edit Selected");
        Button delBtn = UIHelper.makeDangerButton("🗑 Delete Selected");

        configurePermissionButton(addBtn, Permission.MANAGE_ADMINS);
        configurePermissionButton(editBtn, Permission.MANAGE_ADMINS);
        configurePermissionButton(delBtn, Permission.DELETE_RECORDS);

        addBtn.setOnAction(e -> {
            if (!checkPermission(Permission.MANAGE_ADMINS)) return;
            showAdminDialog(null, refresh);
        });

        editBtn.setOnAction(e -> {
            if (!checkPermission(Permission.MANAGE_ADMINS)) return;

            Admin selected = table.getSelectionModel().getSelectedItem();

            if (selected == null) {
                UIHelper.showError("No Selection", "Select an admin first.");
                return;
            }

            showAdminDialog(selected, refresh);
        });

        delBtn.setOnAction(e -> {
            if (!checkPermission(Permission.DELETE_RECORDS)) return;

            Admin selected = table.getSelectionModel().getSelectedItem();

            if (selected == null) {
                UIHelper.showError("No Selection", "Select an admin first.");
                return;
            }

            if (selected.getId().equals(currentAdmin().getId())) {
                UIHelper.showError("Not Allowed", "You cannot delete the admin account you are currently using.");
                return;
            }

            if (!UIHelper.showConfirmation("Delete Admin", "Delete admin " + selected.getFullName() + "?")) return;

            try {
                db.deleteAdmin(selected.getId());
                refresh.run();
            } catch (RuntimeException ex) {
                UIHelper.showError("Delete Failed", rootCauseMessage(ex));
            }
        });

        SplitPane split = new SplitPane(table, detail);
        UIHelper.styleGlassSplitPane(split);
        split.setDividerPositions(0.65);
        VBox.setVgrow(split, Priority.ALWAYS);

        VBox panel = panel();
        panel.getChildren().addAll(
                headerRow("Manage Admins", "SUPER-only control for admin accounts and permission levels.", "SUPER ONLY", UIHelper.COLOR_ACCENT2),
                new HBox(10, search, addBtn, editBtn, delBtn),
                split
        );

        return panel;
    }

    private void updateAdminDetail(VBox shell, Admin admin) {
        shell.getChildren().clear();

        if (admin == null) {
            shell.getChildren().addAll(
                    styledLabel("Admin Details", 13, UIHelper.COLOR_TEXT),
                    UIHelper.makeSubtitle("Select an admin to inspect account and permissions.")
            );
            return;
        }

        shell.getChildren().addAll(
                styledLabel(admin.getFullName(), 18, UIHelper.COLOR_TEXT),
                UIHelper.makeStatusBadge(admin.getId(), UIHelper.COLOR_ACCENT),
                UIHelper.makeStatusBadge(admin.getAdminLevel(), "SUPER".equalsIgnoreCase(admin.getAdminLevel()) ? UIHelper.COLOR_DANGER : UIHelper.COLOR_ACCENT2),
                UIHelper.makeSeparator(),
                UIHelper.makeInsightLine("Email", admin.getEmail(), UIHelper.COLOR_ACCENT),
                UIHelper.makeInsightLine("Level", admin.getAdminLevel(), UIHelper.COLOR_ACCENT2),
                UIHelper.makeInsightLine("Role", admin.getRole(), UIHelper.COLOR_SUCCESS),
                UIHelper.makeSeparator(),
                UIHelper.makeSubtitle(AdminPermissionService.describeLevel(admin))
        );
    }

    private void showAdminDialog(Admin existing, Runnable refresh) {
        TextField firstName = UIHelper.makeTextField("First Name");
        TextField lastName = UIHelper.makeTextField("Last Name");
        TextField email = UIHelper.makeTextField("Email");
        PasswordField password = UIHelper.makePasswordField("Password");
        ComboBox<String> level = stringCombo(List.of("SUPER", "MODERATOR", "STANDARD"), "Admin Level");

        if (existing != null) {
            firstName.setText(existing.getFirstName());
            lastName.setText(existing.getLastName());
            email.setText(existing.getEmail());
            password.setText(existing.getPassword());
            level.setValue(existing.getAdminLevel());
        } else {
            level.setValue("STANDARD");
        }

        GridPane grid = formGrid(
                "First Name", firstName,
                "Last Name", lastName,
                "Email", email,
                "Password", password,
                "Level", level
        );

        showDialog(existing == null ? "Add Admin" : "Edit Admin", grid, () -> {
            try {
                require(firstName, "First name");
                require(lastName, "Last name");
                require(email, "Email");
                require(password, "Password");

                Admin admin = existing == null
                        ? new Admin(db.generateAdminId(), "", "", "", "", "", "")
                        : existing;

                admin.setFirstName(firstName.getText().trim());
                admin.setLastName(lastName.getText().trim());
                admin.setEmail(email.getText().trim());
                admin.setPassword(password.getText().trim());
                admin.setAdminLevel(valueOrDefault(level.getValue(), "STANDARD"));

                db.insertAdmin(admin);
                refresh.run();
            } catch (Exception ex) {
                UIHelper.showError("Admin Save Failed", rootCauseMessage(ex));
            }
        });
    }

    // ── Schedule Monitor ──────────────────────────────────────────────────

    // ── Small reusable helpers ────────────────────────────────────────────

    private VBox cardShell(String title, String subtitle) {
        VBox card = new VBox(10);
        card.setPadding(new Insets(14));
        card.setStyle(
                "-fx-background-color:rgba(10,15,31,0.78);" +
                        "-fx-background-radius:16;" +
                        "-fx-border-color:rgba(124,92,252,0.26);" +
                        "-fx-border-radius:16;" +
                        "-fx-border-width:1;" +
                        "-fx-effect:dropshadow(gaussian,rgba(0,0,0,0.25),12,0,0,3);"
        );

        card.getChildren().addAll(
                styledLabel(title, 13, UIHelper.COLOR_TEXT),
                UIHelper.makeSubtitle(subtitle)
        );

        return card;
    }

    private ComboBox<String> stringCombo(Collection<String> values, String prompt) {
        ComboBox<String> combo = new ComboBox<>(FXCollections.observableArrayList(values));
        combo.setPromptText(prompt);
        combo.setPrefHeight(42);
        combo.setMaxWidth(Double.MAX_VALUE);
        return combo;
    }

    private List<String> loadOptions(String sql) {
        List<String> values = new ArrayList<>();

        try (Connection conn = db.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                values.add(rs.getString(1));
            }
        } catch (SQLException ex) {
            System.err.println("[ADMIN] Could not load options: " + ex.getMessage());
        }

        return values;
    }

    private long countQuery(String sql) {
        try (Connection conn = db.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            return rs.next() ? rs.getLong(1) : 0L;
        } catch (SQLException ex) {
            return 0L;
        }
    }

    private void require(TextField field, String name) {
        if (field.getText() == null || field.getText().trim().isBlank()) {
            throw new IllegalArgumentException(name + " is required.");
        }
    }

    private int parseInt(String value, int fallback) {
        try {
            return Integer.parseInt(value.trim());
        } catch (Exception ex) {
            return fallback;
        }
    }

    private String valueOrDefault(String value, String fallback) {
        return value == null || value.trim().isBlank() ? fallback : value.trim();
    }

    private String shortText(String value, int maxLength) {
        String clean = safe(value);

        if (clean.length() <= maxLength) {
            return clean;
        }

        return clean.substring(0, Math.max(0, maxLength - 3)) + "...";
    }

    private String safe(String value) {
        return value == null || value.isBlank() ? "N/A" : value;
    }

    private String rootCauseMessage(Throwable throwable) {
        Throwable t = throwable;

        while (t.getCause() != null) {
            t = t.getCause();
        }

        String message = t.getMessage();
        return message == null || message.isBlank() ? t.getClass().getSimpleName() : message;
    }
}
