package com.university.ui;

import com.university.dao.DatabaseManager;
import com.university.exception.UniversityException;
import com.university.model.*;
import com.university.service.*;
import com.university.util.*;
import javafx.collections.*;
import javafx.geometry.*;
import javafx.scene.Node;
import javafx.scene.control.*;
import javafx.scene.layout.*;

import java.util.*;

public class InstructorScreen extends BaseDashboardScreen {

    private final DatabaseManager db = DatabaseManager.getInstance();
    private final RegistrationService regService = RegistrationService.getInstance();
    private final GradingPermissionService permission = new GradingPermissionService();

    private Instructor instructor;
    private Map<String, Course> coursesCache;
    private final Map<String, List<Student>> studentsByOffering = new HashMap<>();

    @Override
    protected Node[] topBarInfoNodes() {
        Label title = UIHelper.makeStatusBadge(instructor.getTitle(), UIHelper.COLOR_ACCENT2);
        Label name = UIHelper.makeLabel("👨‍🏫  " + instructor.getFullName());
        name.setStyle(name.getStyle() + "-fx-text-fill:" + UIHelper.COLOR_MUTED + ";");
        return new Node[]{ title, name, UIHelper.makeStatusBadge(instructor.getDepartment(), UIHelper.COLOR_SUCCESS) };
    }

    @Override
    protected VBox buildSidebarContent() {
        List<Course> mine = myCourses();
        long students = mine.stream().mapToLong(c -> getStudentsFor(c).size()).sum();
        long open = mine.stream().filter(c -> c.getStatus() == Course.Status.OPEN).count();

        VBox sidebar = new VBox(14);
        Label lbl = UIHelper.makeSubtitle("MY STATS");
        lbl.setStyle(lbl.getStyle() + "-fx-font-size:10px;-fx-font-weight:bold;-fx-text-fill:#7D88AA;");
        sidebar.getChildren().addAll(
                lbl,
                UIHelper.makeStatCard("📚", "My Courses", mine.size(), UIHelper.COLOR_ACCENT),
                UIHelper.makeStatCard("👥", "My Students", (int) students, UIHelper.COLOR_ACCENT2),
                UIHelper.makeStatCard("🟢", "Open", (int) open, UIHelper.COLOR_SUCCESS),
                UIHelper.makeSeparator(),
                buildProfileCard("👨‍🏫", instructor.getId(), instructor.getEmail())
        );
        return sidebar;
    }

    @Override
    protected Node buildContent() {
        ChromeTabPane tabs = new ChromeTabPane();
        tabs.setStyle("-fx-background-color: transparent;");
        tabs.addTab(new ChromeTab("📚 My Courses", this::buildMyCoursesPanel));
        tabs.addTab(new ChromeTab("🗓 Weekly Schedule", this::buildWeeklySchedulePanel));
        tabs.addTab(new ChromeTab("✏️ Grade Students", this::buildGradePanel));
        tabs.addTab(new ChromeTab("📊 Grade Analytics", this::buildAnalyticsPanel));
        return tabs;
    }

    public javafx.scene.Scene build() {
        instructor = (Instructor) auth.getCurrentUser();
        coursesCache = db.getAllCourses();
        studentsByOffering.clear();
        return super.build();
    }

    private VBox buildMyCoursesPanel() {
        List<Course> mine = myCourses();
        VBox panel = panel();
        panel.getChildren().add(headerRow("My Assigned Courses", "Offerings where you are assigned as lecture, section, or lab instructor", mine.size() + " Courses", UIHelper.COLOR_ACCENT));
        if (mine.isEmpty()) { panel.getChildren().add(emptyBox("📭", "No courses assigned yet.", "Ask the admin to assign you to an offering.")); return panel; }

        VBox cards = new VBox(14);
        mine.forEach(c -> cards.getChildren().add(buildCourseCard(c)));
        ScrollPane scroll = new ScrollPane(cards);
        scroll.setFitToWidth(true); scroll.setStyle("-fx-background-color:transparent;-fx-background:transparent;");
        VBox.setVgrow(scroll, Priority.ALWAYS);
        panel.getChildren().add(scroll);
        return panel;
    }

    private VBox buildCourseCard(Course course) {
        HBox header = new HBox(12);
        header.setAlignment(Pos.CENTER_LEFT);
        Label name = new Label(course.getCourseName());
        name.setStyle("-fx-font-size:18px;-fx-font-weight:bold;-fx-text-fill:" + UIHelper.COLOR_TEXT + ";");
        Region sp = new Region(); HBox.setHgrow(sp, Priority.ALWAYS);
        String sc = course.getStatus() == Course.Status.OPEN ? UIHelper.COLOR_SUCCESS : UIHelper.COLOR_DANGER;
        header.getChildren().addAll(UIHelper.makeStatusBadge(course.getCourseId(), UIHelper.COLOR_ACCENT), UIHelper.makeStatusBadge(course.getOfferingId(), UIHelper.COLOR_ACCENT2), name, sp, UIHelper.makeStatusBadge(course.getStatus().name(), sc));

        HBox meta = new HBox(20,
                muted("📅 " + safe(course.getSchedule())),
                muted("📍 " + safe(course.getRoom())),
                muted("🎓 " + course.getCredits() + " credits"),
                muted("🔑 " + safe(permission.getTeachingRole(instructor.getId(), course.getOfferingId())))
        );

        double pct = course.getCapacity() == 0 ? 0 : (double) course.getEnrolled() / course.getCapacity();
        ProgressBar seatBar = new ProgressBar(pct);
        seatBar.setPrefWidth(Double.MAX_VALUE);
        seatBar.setStyle("-fx-accent:" + (pct > 0.8 ? UIHelper.COLOR_DANGER : UIHelper.COLOR_SUCCESS) + ";");

        VBox card = glassCard(14, header, meta, seatBar, UIHelper.makeSubtitle(course.getEnrolled() + "/" + course.getCapacity() + " students enrolled"));
        return card;
    }

    private VBox buildWeeklySchedulePanel() {
        List<ScheduleEntry> schedule = db.getInstructorSchedule(instructor.getId());
        VBox panel = panel();
        long daysCount = schedule.stream().map(ScheduleEntry::getDayOfWeek).filter(Objects::nonNull).distinct().count();
        panel.getChildren().add(headerRow("Weekly Teaching Schedule", "Readable day-by-day list of your teaching meetings", daysCount + " Active Days", UIHelper.COLOR_ACCENT));

        HBox days = new HBox(10);
        days.setAlignment(Pos.TOP_LEFT);
        for (String day : weekDays()) {
            VBox dayCard = dayColumn(day, schedule.stream().filter(e -> day.equalsIgnoreCase(e.getDayOfWeek())).toList());
            HBox.setHgrow(dayCard, Priority.ALWAYS);
            days.getChildren().add(dayCard);
        }
        panel.getChildren().add(days);
        VBox.setVgrow(days, Priority.ALWAYS);
        return panel;
    }

    private VBox buildGradePanel() {
        ComboBox<Course> courseCombo = new ComboBox<>(FXCollections.observableArrayList(myCourses()));
        courseCombo.setPromptText("📚  Select an Offering...");
        courseCombo.setPrefWidth(520);
        courseCombo.setConverter(new javafx.util.StringConverter<>() {
            public String toString(Course c) { return c == null ? "" : c.getCourseId() + " " + c.getSectionCode() + " — " + c.getCourseName(); }
            public Course fromString(String s) { return null; }
        });

        ObservableList<Student> studentItems = FXCollections.observableArrayList();
        TableView<Student> studentTable = GlassTable.<Student>create()
                .prop("ID", "id")
                .col("Student", Student::getFullName)
                .prop("Major", "major")
                .col("GPA", s -> String.format("%.2f", s.getGpa()))
                .col("Total", s -> {
                    Course c = courseCombo.getValue(); Enrollment e = findEnrollment(s, c);
                    return e == null ? "—" : String.format("%.1f / 100", e.getTotalGrade());
                })
                .col("Grade", s -> {
                    Course c = courseCombo.getValue(); Enrollment e = findEnrollment(s, c);
                    return e == null ? "—" : e.getGradeDisplay();
                })
                .build();
        studentTable.setItems(studentItems);
        VBox.setVgrow(studentTable, Priority.ALWAYS);

        VBox editor = glassCard(16, UIHelper.makeSubtitle("Select a course and student to edit component scores."));
        courseCombo.setOnAction(e -> {
            Course c = courseCombo.getValue();
            studentItems.setAll(c == null ? List.of() : getStudentsFor(c));
            editor.getChildren().setAll(UIHelper.makeSubtitle("Select a student to edit grades."));
        });
        studentTable.getSelectionModel().selectedItemProperty().addListener((obs, old, selected) -> {
            Course c = courseCombo.getValue();
            if (selected == null || c == null) return;
            buildGradeEditor(editor, c, selected, studentTable);
        });

        SplitPane split = new SplitPane(studentTable, editor);
        UIHelper.styleGlassSplitPane(split);
        split.setDividerPositions(0.55);
        VBox.setVgrow(split, Priority.ALWAYS);

        VBox panel = panel();
        panel.getChildren().addAll(headerRow("Component Grading", "Role-based permissions: lecture vs section/lab components", "Role Based", UIHelper.COLOR_SUCCESS), courseCombo, split);
        return panel;
    }

    private void buildGradeEditor(VBox editor, Course course, Student student, TableView<Student> table) {
        Enrollment enrollment = findEnrollment(student, course);
        editor.getChildren().clear();
        if (enrollment == null) { editor.getChildren().add(UIHelper.makeSubtitle("Enrollment not found.")); return; }

        Label title = UIHelper.makeTitle(student.getFullName());
        title.setStyle(title.getStyle() + "-fx-font-size:22px;");
        Label perm = UIHelper.makeSubtitle(permission.permissionText(instructor.getId(), course.getOfferingId()));

        GridPane grid = new GridPane();
        grid.setHgap(8); grid.setVgap(8);
        List<ScoreField> fields = new ArrayList<>();
        fields.add(scoreField(grid, 0, "W7_LEC", "Week 7 Lecture", enrollment.getWeek7Lecture(), 20, course));
        fields.add(scoreField(grid, 1, "W7_SEC", "Week 7 Section", enrollment.getWeek7Section(), 10, course));
        fields.add(scoreField(grid, 2, "W12_LEC", "Week 12 Lecture", enrollment.getWeek12Lecture(), 15, course));
        fields.add(scoreField(grid, 3, "W12_SEC", "Week 12 Section", enrollment.getWeek12Section(), 5, course));
        fields.add(scoreField(grid, 4, "CW", "Coursework", enrollment.getCoursework(), 10, course));
        fields.add(scoreField(grid, 5, "FINAL", "Final Exam", enrollment.getFinalExam(), 40, course));

        Label total = UIHelper.makeStatusBadge("Current Total: " + String.format("%.1f / 100 • %s", enrollment.getTotalGrade(), enrollment.getGradeDisplay()), UIHelper.COLOR_ACCENT);
        Button save = UIHelper.makeSuccessButton("💾 Save Allowed Components");
        save.setOnAction(e -> {
            try {
                for (ScoreField f : fields) {
                    if (!f.field().isDisabled()) regService.setAssessmentScore(enrollment.getEnrollmentId(), f.code(), parseDouble(f.field().getText(), 0));
                }
                studentsByOffering.remove(course.getOfferingId());
                coursesCache = db.getAllCourses();
                UIHelper.showSuccess("Saved", "Scores updated.");
                table.refresh();
            } catch (UniversityException ex) { UIHelper.showError("Save Failed", ex.getMessage()); }
        });

        editor.getChildren().addAll(UIHelper.makeStatusBadge(student.getId(), UIHelper.COLOR_ACCENT2), title, perm, metaGrid(
                "Course", course.getCourseId() + " / " + course.getOfferingId(),
                "Student GPA", String.format("%.2f", student.getGpa()),
                "Grade", enrollment.getGradeDisplay()
        ), total, grid, save);
    }

    private ScoreField scoreField(GridPane grid, int row, String code, String label, double value, double max, Course course) {
        boolean can = permission.canEdit(instructor.getId(), course.getOfferingId(), code);
        Label l = UIHelper.makeLabel(label + " / " + max);
        TextField field = UIHelper.makeTextField("0-" + max);
        field.setText(String.format("%.1f", value));
        field.setDisable(!can);
        grid.add(l, 0, row); grid.add(field, 1, row); grid.add(UIHelper.makeStatusBadge(can ? "CAN EDIT" : "LOCKED", can ? UIHelper.COLOR_SUCCESS : UIHelper.COLOR_MUTED), 2, row);
        return new ScoreField(code, field);
    }

    private VBox buildAnalyticsPanel() {
        List<Course> mine = myCourses();
        List<Student> unique = mine.stream().flatMap(c -> getStudentsFor(c).stream()).distinct().toList();
        long totalEnrollments = mine.stream().mapToLong(c -> getStudentsFor(c).size()).sum();
        double avgGpa = unique.stream().mapToDouble(Student::getGpa).average().orElse(0);
        long atRisk = unique.stream().filter(s -> s.getGpa() > 0 && s.getGpa() < 2.0).count();

        HBox kpis = new HBox(12,
                UIHelper.makeKpiCard("My Courses", String.valueOf(mine.size()), "assigned offerings", UIHelper.COLOR_ACCENT),
                UIHelper.makeKpiCard("Unique Students", String.valueOf(unique.size()), "students reached", UIHelper.COLOR_ACCENT2),
                UIHelper.makeKpiCard("Enrollments", String.valueOf(totalEnrollments), "course seats used", UIHelper.COLOR_SUCCESS),
                UIHelper.makeKpiCard("At Risk", String.valueOf(atRisk), "GPA below 2.0", atRisk == 0 ? UIHelper.COLOR_SUCCESS : UIHelper.COLOR_DANGER)
        );

        VBox courseList = new VBox(10);
        for (Course c : mine) {
            List<Student> st = getStudentsFor(c);
            courseList.getChildren().add(glassCard(10,
                    new HBox(10, UIHelper.makeStatusBadge(c.getCourseId(), UIHelper.COLOR_ACCENT), UIHelper.makeStatusBadge(c.getOfferingId(), UIHelper.COLOR_ACCENT2), UIHelper.makeLabel(c.getCourseName())),
                    UIHelper.makeInsightLine("Students", String.valueOf(st.size()), UIHelper.COLOR_ACCENT),
                    UIHelper.makeInsightLine("Capacity", c.getEnrolled() + "/" + c.getCapacity(), UIHelper.COLOR_SUCCESS),
                    UIHelper.makeInsightLine("Role", permission.getTeachingRole(instructor.getId(), c.getOfferingId()), UIHelper.COLOR_ACCENT2)
            ));
        }
        ScrollPane scroll = new ScrollPane(courseList); scroll.setFitToWidth(true); scroll.setStyle("-fx-background-color:transparent;-fx-background:transparent;");
        VBox.setVgrow(scroll, Priority.ALWAYS);

        VBox panel = panel();
        panel.getChildren().addAll(headerRow("Teaching Analytics", "Useful course load and student risk summary", String.format("%.2f Avg GPA", avgGpa), UIHelper.COLOR_WARNING), kpis, scroll);
        return panel;
    }

    private VBox dayColumn(String day, List<ScheduleEntry> entries) {
        VBox card = new VBox(8);
        card.setPadding(new Insets(12)); card.getStyleClass().add("card-glass"); card.setMinHeight(420);
        HBox head = new HBox(8); head.setAlignment(Pos.CENTER_LEFT); Region sp = new Region(); HBox.setHgrow(sp, Priority.ALWAYS);
        head.getChildren().addAll(styledLabel(day, 14, UIHelper.COLOR_TEXT), sp, UIHelper.makeStatusBadge(entries.size() + "", entries.isEmpty() ? UIHelper.COLOR_MUTED : UIHelper.COLOR_ACCENT));
        VBox list = new VBox(8);
        if (entries.isEmpty()) list.getChildren().add(emptyMini("—", "Free")); else entries.forEach(e -> list.getChildren().add(scheduleMiniCard(e)));
        ScrollPane scroll = new ScrollPane(list); scroll.setFitToWidth(true); scroll.setStyle("-fx-background-color:transparent;-fx-background:transparent;");
        VBox.setVgrow(scroll, Priority.ALWAYS); card.getChildren().addAll(head, scroll); return card;
    }

    private VBox scheduleMiniCard(ScheduleEntry e) {
        String color = meetingColor(e.getMeetingType());
        VBox card = new VBox(5); card.setPadding(new Insets(9));
        card.setStyle("-fx-background-color:" + color + "18;-fx-background-radius:10;-fx-border-color:" + color + "66;-fx-border-radius:10;-fx-border-width:1;");
        HBox top = new HBox(6); Region sp = new Region(); HBox.setHgrow(sp, Priority.ALWAYS);
        top.getChildren().addAll(UIHelper.makeStatusBadge(e.getCourseId(), color), sp, UIHelper.makeStatusBadge(e.getMeetingType(), color));
        Label name = UIHelper.makeLabel(e.getCourseName()); name.setWrapText(true); name.setStyle(name.getStyle() + "-fx-font-weight:bold;");
        card.getChildren().addAll(top, name, muted("⏱ " + e.getTimeRange()), muted("📍 " + e.getRoomId()), muted("👥 " + getStudentsForOfferingId(e.getOfferingId()).size() + " students"));
        return card;
    }

    private VBox emptyMini(String icon, String text) { VBox box = new VBox(6, new Label(icon), UIHelper.makeSubtitle(text)); box.setAlignment(Pos.CENTER); box.setPadding(new Insets(22)); box.getStyleClass().add("card-glass-soft"); return box; }
    private GridPane metaGrid(String... pairs) { GridPane meta = new GridPane(); meta.setHgap(16); meta.setVgap(8); meta.setPadding(new Insets(14)); meta.getStyleClass().add("card-glass-soft"); for (int i = 0; i < pairs.length; i += 2) meta.addRow(i / 2, muted(pairs[i] + ":"), UIHelper.makeLabel(safe(pairs[i + 1]))); return meta; }
    private VBox glassCard(double padding, Node... nodes) { VBox box = new VBox(10, nodes); box.setPadding(new Insets(padding)); box.getStyleClass().add("card-glass"); return box; }
    private String[] weekDays() { return new String[]{"Saturday", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday"}; }
    private String meetingColor(String type) { return "LAB".equalsIgnoreCase(type) ? UIHelper.COLOR_SUCCESS : "SECTION".equalsIgnoreCase(type) ? UIHelper.COLOR_ACCENT2 : UIHelper.COLOR_ACCENT; }
    private String safe(String value) { return value == null || value.isBlank() ? "N/A" : value; }
    private double parseDouble(String value, double fallback) { try { return Double.parseDouble(value.trim()); } catch (Exception e) { return fallback; } }

    private List<Course> myCourses() {
        Set<String> myOfferings = db.getInstructorSchedule(instructor.getId()).stream().map(ScheduleEntry::getOfferingId).collect(java.util.stream.Collectors.toSet());
        return courses().values().stream().filter(c -> myOfferings.contains(c.getOfferingId()) || instructor.getId().equals(c.getInstructorId())).toList();
    }

    private Map<String, Course> courses() { return coursesCache != null ? coursesCache : db.getAllCourses(); }
    private List<Student> getStudentsFor(Course course) { return getStudentsForOfferingId(course.getOfferingId()); }
    private List<Student> getStudentsForOfferingId(String offeringId) { return studentsByOffering.computeIfAbsent(offeringId, regService::getStudentsInCourse); }

    private Enrollment findEnrollment(Student student, Course course) {
        if (student == null || course == null) return null;
        return student.getEnrollments().stream().filter(e -> e.matchesCourseOrOffering(course.getOfferingId())).findFirst().orElse(null);
    }

    private record ScoreField(String code, TextField field) {}
}
