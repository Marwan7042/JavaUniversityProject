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
            tabs.addTab(new ChromeTab("📚 Courses & Offerings", this::buildCoursesPanel));
        }

        if (can(Permission.VIEW_ACADEMIC_SETTINGS) || can(Permission.MANAGE_REGISTRATION_PERIODS)) {
            tabs.addTab(new ChromeTab("⚙ Academic Settings", this::buildAcademicSettingsPanel));
        }

        if (can(Permission.MANAGE_ADMINS)) {
            tabs.addTab(new ChromeTab("🛡 Admins", this::buildAdminsPanel));
        }

        tabs.addTab(new ChromeTab("🗓 Schedule Monitor", this::buildScheduleMonitorPanel));
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

    // ── Courses / Offerings ───────────────────────────────────────────────

    private VBox buildCoursesPanel() {
        ObservableList<Course> all = FXCollections.observableArrayList(courses().values());

        Runnable refresh = () -> {
            coursesCache = db.getAllCourses();
            all.setAll(coursesCache.values());
        };

        TableView<Course> table = GlassTable.<Course>create()
                .prop("Offering", "offeringId")
                .col("Course", c -> c.getCourseId() + " • " + shortText(c.getCourseName(), 28))
                .col("Term", c -> c.getTerm() + " " + c.getAcademicYear())
                .col("Seats", c -> c.getEnrolled() + "/" + c.getCapacity())
                .statusCol("Status", c -> c.getStatus().name())
                .build();

        table.setItems(all);
        VBox.setVgrow(table, Priority.ALWAYS);

        TextField search = UIHelper.makeTextField("🔍 Search offering, course, instructor, room, department, or status...");
        HBox.setHgrow(search, Priority.ALWAYS);

        search.textProperty().addListener((o, oldValue, q) -> table.setItems(filterCourses(all, q)));

        Button addBtn = UIHelper.makePrimaryButton("➕ Add Offering");
        Button editBtn = UIHelper.makeSecondaryButton("✏ Edit Selected");
        Button delBtn = UIHelper.makeDangerButton("🗑 Delete Offering");
        Button toggleBtn = UIHelper.makeSecondaryButton("🔄 Toggle Status");

        configurePermissionButton(addBtn, Permission.MANAGE_COURSE_OFFERINGS);
        configurePermissionButton(editBtn, Permission.MANAGE_COURSE_OFFERINGS);
        configurePermissionButton(toggleBtn, Permission.MANAGE_COURSE_OFFERINGS);
        configurePermissionButton(delBtn, Permission.DELETE_RECORDS);

        addBtn.setOnAction(e -> {
            if (!checkPermission(Permission.MANAGE_COURSE_OFFERINGS)) return;
            showCourseOfferingDialog(null, refresh);
        });

        editBtn.setOnAction(e -> {
            Course selected = table.getSelectionModel().getSelectedItem();

            if (selected == null) {
                UIHelper.showError("No Selection", "Select an offering first.");
                return;
            }

            if (!checkPermission(Permission.MANAGE_COURSE_OFFERINGS)) return;
            showCourseOfferingDialog(selected, refresh);
        });

        delBtn.setOnAction(e -> {
            Course selected = table.getSelectionModel().getSelectedItem();

            if (selected == null) {
                UIHelper.showError("No Selection", "Select an offering first.");
                return;
            }

            if (!checkPermission(Permission.DELETE_RECORDS)) return;
            if (!UIHelper.showConfirmation("Delete Offering", "Delete offering " + selected.getOfferingId() + " for " + selected.getCourseName() + "?")) return;

            try {
                db.deleteCourse(selected.getOfferingId());
                refresh.run();
            } catch (RuntimeException ex) {
                UIHelper.showError("Delete Failed", rootCauseMessage(ex));
            }
        });

        toggleBtn.setOnAction(e -> {
            Course selected = table.getSelectionModel().getSelectedItem();

            if (selected == null) {
                UIHelper.showError("No Selection", "Select an offering first.");
                return;
            }

            if (!checkPermission(Permission.MANAGE_COURSE_OFFERINGS)) return;

            try {
                selected.setStatus(selected.getStatus() == Course.Status.OPEN ? Course.Status.CLOSED : Course.Status.OPEN);
                db.insertCourse(selected);
                refresh.run();
            } catch (RuntimeException ex) {
                UIHelper.showError("Update Failed", rootCauseMessage(ex));
            }
        });

        VBox detail = buildCourseDetailPanel(table);

        SplitPane split = new SplitPane(table, detail);
        UIHelper.styleGlassSplitPane(split);
        split.setDividerPositions(0.58);
        VBox.setVgrow(split, Priority.ALWAYS);

        VBox panel = panel();
        panel.getChildren().addAll(
                headerRow("Courses & Offerings", "Manage catalog data, offering data, teaching role, and schedule row.", all.size() + " Offerings", UIHelper.COLOR_SUCCESS),
                new HBox(10, search, addBtn, editBtn, toggleBtn, delBtn),
                split
        );

        return panel;
    }

    private ObservableList<Course> filterCourses(ObservableList<Course> all, String query) {
        String q = query == null ? "" : query.trim().toLowerCase();

        if (q.isBlank()) return all;

        return all.filtered(c ->
                safe(c.getOfferingId()).toLowerCase().contains(q)
                        || safe(c.getCourseId()).toLowerCase().contains(q)
                        || safe(c.getCourseName()).toLowerCase().contains(q)
                        || safe(c.getDepartment()).toLowerCase().contains(q)
                        || safe(c.getInstructorName()).toLowerCase().contains(q)
                        || safe(c.getRoom()).toLowerCase().contains(q)
        );
    }

    private VBox buildCourseDetailPanel(TableView<Course> table) {
        VBox box = cardShell("Selected Offering Details", "Select an offering from the table.");

        table.getSelectionModel().selectedItemProperty().addListener((obs, old, c) -> {
            box.getChildren().clear();

            if (c == null) {
                box.getChildren().addAll(
                        styledLabel("Selected Offering Details", 13, UIHelper.COLOR_TEXT),
                        UIHelper.makeSubtitle("Select an offering from the table.")
                );
                return;
            }

            box.getChildren().addAll(
                    styledLabel(c.getCourseId() + " • " + c.getCourseName(), 18, UIHelper.COLOR_TEXT),
                    UIHelper.makeStatusBadge(c.getOfferingId(), UIHelper.COLOR_ACCENT),
                    UIHelper.makeSeparator(),
                    UIHelper.makeInsightLine("Department", safe(c.getDepartment()), UIHelper.COLOR_ACCENT),
                    UIHelper.makeInsightLine("Term", safe(c.getTerm()) + " " + c.getAcademicYear(), UIHelper.COLOR_ACCENT2),
                    UIHelper.makeInsightLine("Section", safe(c.getSectionCode()), UIHelper.COLOR_SUCCESS),
                    UIHelper.makeInsightLine("Seats", c.getEnrolled() + "/" + c.getCapacity(), UIHelper.COLOR_WARNING),
                    UIHelper.makeInsightLine("Room", safe(c.getRoom()), UIHelper.COLOR_ACCENT),
                    UIHelper.makeInsightLine("Instructor", safe(c.getInstructorName()), UIHelper.COLOR_ACCENT2),
                    UIHelper.makeInsightLine("Schedule", safe(c.getSchedule()), UIHelper.COLOR_SUCCESS),
                    UIHelper.makeSeparator(),
                    UIHelper.makeSubtitle(safe(c.getDescription()))
            );
        });

        return box;
    }

    private void showCourseOfferingDialog(Course existing, Runnable refresh) {
        if (!checkPermission(Permission.MANAGE_COURSE_OFFERINGS)) return;
        boolean editMode = existing != null;

        TextField courseId = UIHelper.makeTextField("e.g. CS401");
        TextField courseName = UIHelper.makeTextField("Course Name");
        ComboBox<String> department = stringCombo(loadOptions("SELECT department_name FROM departments ORDER BY department_name"), "Department");
        TextField credits = UIHelper.makeTextField("Credits");
        TextField description = UIHelper.makeTextField("Description");

        ComboBox<String> term = stringCombo(List.of("TERM1", "TERM2", "SUMMER"), "Term");
        TextField academicYear = UIHelper.makeTextField("Academic Year");
        TextField sectionCode = UIHelper.makeTextField("e.g. L01");
        TextField capacity = UIHelper.makeTextField("Capacity");
        ComboBox<String> status = stringCombo(List.of("OPEN", "CLOSED", "CANCELLED", "COMPLETED"), "Status");

        ComboBox<String> meetingType = stringCombo(List.of("LECTURE", "SECTION", "LAB"), "Meeting Type");
        ComboBox<String> day = stringCombo(List.of("Saturday", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday"), "Day");
        ComboBox<String> slot = stringCombo(loadSlotLabels(), "Time Slot");
        ComboBox<String> room = stringCombo(new ArrayList<>(), "Room");
        ComboBox<String> instructor = stringCombo(loadInstructorLabels(), "Instructor");
        ComboBox<String> role = stringCombo(List.of("LECTURE", "ASSISTANT", "LAB"), "Teaching Role");

        meetingType.setOnAction(e -> {
            String mt = valueOrDefault(meetingType.getValue(), "LECTURE");
            room.getItems().setAll(loadRoomsForMeetingType(mt));

            if ("LAB".equals(mt)) {
                role.setValue("LAB");
            } else if ("SECTION".equals(mt)) {
                role.setValue("ASSISTANT");
            } else {
                role.setValue("LECTURE");
            }
        });

        if (editMode) {
            courseId.setText(existing.getCourseId());
            courseName.setText(existing.getCourseName());
            department.setValue(existing.getDepartment());
            credits.setText(String.valueOf(existing.getCredits()));
            description.setText(existing.getDescription());

            term.setValue(existing.getTerm());
            academicYear.setText(String.valueOf(existing.getAcademicYear()));
            sectionCode.setText(existing.getSectionCode());
            capacity.setText(String.valueOf(existing.getCapacity()));
            status.setValue(existing.getStatus().name());

            meetingType.setValue(valueOrDefault(existing.getMeetingType(), "LECTURE"));
            day.setValue(existing.getDayOfWeek());
            slot.setValue(existing.getSlotId() == null ? null : findSlotLabel(existing.getSlotId()));
            room.getItems().setAll(loadRoomsForMeetingType(valueOrDefault(meetingType.getValue(), "LECTURE")));
            room.setValue(existing.getRoom());
            role.setValue(valueOrDefault(existing.getInstructorRole(), roleFromMeetingType(existing.getMeetingType())));
            instructor.setValue(findInstructorLabel(existing.getInstructorId()));
        } else {
            term.setValue("TERM1");
            academicYear.setText("2026");
            sectionCode.setText("L01");
            capacity.setText("30");
            status.setValue("OPEN");
            meetingType.setValue("LECTURE");
            role.setValue("LECTURE");
            room.getItems().setAll(loadRoomsForMeetingType("LECTURE"));
        }

        GridPane catalogGrid = formGrid(
                "Course ID", courseId,
                "Name", courseName,
                "Department", department,
                "Credits", credits,
                "Description", description
        );

        GridPane offeringGrid = formGrid(
                "Term", term,
                "Academic Year", academicYear,
                "Section", sectionCode,
                "Capacity", capacity,
                "Status", status
        );

        GridPane scheduleGrid = formGrid(
                "Meeting Type", meetingType,
                "Day", day,
                "Time Slot", slot,
                "Room", room,
                "Instructor", instructor,
                "Teaching Role", role
        );

        Label rule = UIHelper.makeSubtitle("Rule: LECTURE and SECTION use LECTURE rooms. LAB uses LAB rooms. Save one meeting row at a time for the selected offering.");

        VBox content = new VBox(14,
                styledLabel("Catalog Data", 14, UIHelper.COLOR_TEXT),
                catalogGrid,
                UIHelper.makeSeparator(),
                styledLabel("Offering Data", 14, UIHelper.COLOR_TEXT),
                offeringGrid,
                UIHelper.makeSeparator(),
                styledLabel("Schedule / Teaching Assignment", 14, UIHelper.COLOR_TEXT),
                scheduleGrid,
                rule
        );

        showDialog(editMode ? "Edit Course Offering" : "Add Course Offering", content, () -> {
            try {
                require(courseId, "Course ID");
                require(courseName, "Course name");
                require(credits, "Credits");
                require(capacity, "Capacity");
                require(academicYear, "Academic year");

                Course c = editMode ? existing : new Course();

                if (!editMode || c.getOfferingId() == null || c.getOfferingId().isBlank()) {
                    c.setOfferingId(db.generateOfferingId());
                }

                c.setCourseId(courseId.getText().trim().toUpperCase());
                c.setCourseName(courseName.getText().trim());
                c.setDepartment(valueOrDefault(department.getValue(), "Computer Science & Informatics"));
                c.setCredits(parseInt(credits.getText(), 3));
                c.setDescription(description.getText() == null ? "" : description.getText().trim());

                c.setTerm(valueOrDefault(term.getValue(), "TERM1"));
                c.setAcademicYear(parseInt(academicYear.getText(), 2026));
                c.setSectionCode(valueOrDefault(sectionCode.getText(), "L01").trim().toUpperCase());
                c.setCapacity(parseInt(capacity.getText(), 30));
                c.setStatus(Course.Status.valueOf(valueOrDefault(status.getValue(), "OPEN")));

                c.setMeetingType(valueOrDefault(meetingType.getValue(), "LECTURE"));
                c.setDayOfWeek(valueOrDefault(day.getValue(), "Saturday"));
                c.setSlotId(parseSlotId(slot.getValue()));
                c.setRoom(valueOrDefault(room.getValue(), ""));

                String instructorId = parseIdFromLabel(instructor.getValue());
                c.setInstructorId(instructorId);
                c.setInstructorRole(valueOrDefault(role.getValue(), roleFromMeetingType(c.getMeetingType())));

                db.insertCourse(c);
                refresh.run();
            } catch (Exception ex) {
                UIHelper.showError("Course Save Failed", rootCauseMessage(ex));
            }
        });
    }


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

    private VBox buildScheduleMonitorPanel() {
        ObservableList<ScheduleAdminRow> rows = FXCollections.observableArrayList(loadScheduleRows());

        TableView<ScheduleAdminRow> table = GlassTable.<ScheduleAdminRow>create()
                .col("Offering", ScheduleAdminRow::offeringId)
                .col("Course", ScheduleAdminRow::courseCode)
                .col("Type", ScheduleAdminRow::meetingType)
                .col("Day", ScheduleAdminRow::day)
                .col("Slot", r -> String.valueOf(r.slot()))
                .col("Room", ScheduleAdminRow::room)
                .col("Room Type", ScheduleAdminRow::roomType)
                .col("Instructor", ScheduleAdminRow::instructor)
                .build();

        table.setItems(rows);
        VBox.setVgrow(table, Priority.ALWAYS);

        Button refresh = UIHelper.makeSecondaryButton("🔄 Refresh");
        refresh.setOnAction(e -> rows.setAll(loadScheduleRows()));

        VBox conflictCard = buildConflictSummaryCard();

        VBox panel = panel();
        panel.getChildren().addAll(
                headerRow("Schedule Monitor", "Room usage, instructor assignments, and conflict checks.", rows.size() + " Schedule Rows", UIHelper.COLOR_ACCENT),
                new HBox(10, refresh),
                conflictCard,
                table
        );

        return panel;
    }

    private VBox buildConflictSummaryCard() {
        long invalidRoomType = countQuery("""
            SELECT COUNT(*)
            FROM room_schedule rs
            JOIN rooms r ON rs.room_id = r.room_id
            WHERE (rs.meeting_type IN ('LECTURE', 'SECTION') AND r.room_type <> 'LECTURE')
               OR (rs.meeting_type = 'LAB' AND r.room_type <> 'LAB')
        """);

        long roomConflicts = countQuery("""
            SELECT COUNT(*)
            FROM (
                SELECT room_id, day_of_week, slot_id
                FROM room_schedule
                GROUP BY room_id, day_of_week, slot_id
                HAVING COUNT(*) > 1
            ) x
        """);

        long instructorConflicts = countQuery("""
            SELECT COUNT(*)
            FROM (
                SELECT instructor_id, day_of_week, slot_id
                FROM room_schedule
                WHERE instructor_id IS NOT NULL
                GROUP BY instructor_id, day_of_week, slot_id
                HAVING COUNT(*) > 1
            ) x
        """);

        VBox lines = new VBox(7,
                UIHelper.makeInsightLine("Invalid room type rows", String.valueOf(invalidRoomType), invalidRoomType == 0 ? UIHelper.COLOR_SUCCESS : UIHelper.COLOR_DANGER),
                UIHelper.makeInsightLine("Room conflicts", String.valueOf(roomConflicts), roomConflicts == 0 ? UIHelper.COLOR_SUCCESS : UIHelper.COLOR_DANGER),
                UIHelper.makeInsightLine("Instructor conflicts", String.valueOf(instructorConflicts), instructorConflicts == 0 ? UIHelper.COLOR_SUCCESS : UIHelper.COLOR_DANGER)
        );

        VBox card = cardShell("Conflict Check", "All values should be zero.");
        card.getChildren().add(lines);
        return card;
    }

    private List<ScheduleAdminRow> loadScheduleRows() {
        List<ScheduleAdminRow> rows = new ArrayList<>();

        String sql = """
            SELECT TOP 300
                rs.offering_id,
                co.course_id,
                c.course_name,
                rs.meeting_type,
                rs.day_of_week,
                rs.slot_id,
                rs.room_id,
                r.room_type,
                COALESCE(i.title + ' ' + i.first_name + ' ' + i.last_name, 'N/A') AS instructor_name
            FROM room_schedule rs
            JOIN course_offerings co ON rs.offering_id = co.offering_id
            JOIN courses c ON co.course_id = c.course_id
            JOIN rooms r ON rs.room_id = r.room_id
            LEFT JOIN instructors i ON rs.instructor_id = i.id
            ORDER BY
                CASE rs.day_of_week
                    WHEN 'Saturday' THEN 1
                    WHEN 'Sunday' THEN 2
                    WHEN 'Monday' THEN 3
                    WHEN 'Tuesday' THEN 4
                    WHEN 'Wednesday' THEN 5
                    WHEN 'Thursday' THEN 6
                    ELSE 7
                END,
                rs.slot_id,
                co.course_id
        """;

        try (Connection conn = db.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                rows.add(new ScheduleAdminRow(
                        rs.getString("offering_id"),
                        rs.getString("course_id") + " — " + rs.getString("course_name"),
                        rs.getString("meeting_type"),
                        rs.getString("day_of_week"),
                        rs.getInt("slot_id"),
                        rs.getString("room_id"),
                        rs.getString("room_type"),
                        rs.getString("instructor_name")
                ));
            }
        } catch (SQLException ex) {
            UIHelper.showError("Schedule Load Failed", rootCauseMessage(ex));
        }

        return rows;
    }

    private record ScheduleAdminRow(
            String offeringId,
            String courseCode,
            String meetingType,
            String day,
            int slot,
            String room,
            String roomType,
            String instructor
    ) {}

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

    private List<String> loadSlotLabels() {
        List<String> values = loadOptions("""
            SELECT CAST(slot_id AS VARCHAR(10)) + ' - ' +
                   CONVERT(VARCHAR(5), start_time, 108) + ' - ' +
                   CONVERT(VARCHAR(5), end_time, 108)
            FROM time_slots
            ORDER BY slot_id
        """);

        if (values.isEmpty()) {
            values = List.of(
                    "1 - 08:30 - 10:00",
                    "2 - 10:15 - 11:45",
                    "3 - 12:00 - 13:30",
                    "4 - 13:45 - 15:15",
                    "5 - 15:30 - 17:00",
                    "6 - 17:15 - 18:45"
            );
        }

        return values;
    }

    private List<String> loadRoomsForMeetingType(String meetingType) {
        String roomType = "LAB".equalsIgnoreCase(meetingType) ? "LAB" : "LECTURE";

        List<String> values = loadOptions(
                "SELECT room_id FROM rooms WHERE room_type = '" + roomType + "' ORDER BY room_id"
        );

        if (values.isEmpty()) {
            values = "LAB".equals(roomType) ? List.of("LAB001") : List.of("L001");
        }

        return values;
    }

    private List<String> loadInstructorLabels() {
        List<String> values = loadOptions("""
            SELECT title + ' ' + first_name + ' ' + last_name + ' (' + id + ')'
            FROM instructors
            WHERE status = 'ACTIVE'
            ORDER BY id
        """);

        if (values.isEmpty()) {
            values = List.of("Instructor (INS001)");
        }

        return values;
    }

    private String findInstructorLabel(String instructorId) {
        if (instructorId == null || instructorId.isBlank()) return null;

        return loadInstructorLabels().stream()
                .filter(label -> label.contains("(" + instructorId + ")"))
                .findFirst()
                .orElse(null);
    }

    private String findSlotLabel(Integer slotId) {
        if (slotId == null) return null;

        return loadSlotLabels().stream()
                .filter(label -> label.startsWith(slotId + " "))
                .findFirst()
                .orElse(null);
    }

    private int parseSlotId(String label) {
        if (label == null || label.isBlank()) return 1;

        try {
            return Integer.parseInt(label.split(" ")[0].trim());
        } catch (Exception ex) {
            return 1;
        }
    }

    private String parseIdFromLabel(String label) {
        if (label == null || label.isBlank()) return null;

        int start = label.lastIndexOf('(');
        int end = label.lastIndexOf(')');

        if (start >= 0 && end > start) {
            return label.substring(start + 1, end).trim();
        }

        return label.trim();
    }

    private String roleFromMeetingType(String meetingType) {
        if ("LAB".equalsIgnoreCase(meetingType)) return "LAB";
        if ("SECTION".equalsIgnoreCase(meetingType)) return "ASSISTANT";
        return "LECTURE";
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
