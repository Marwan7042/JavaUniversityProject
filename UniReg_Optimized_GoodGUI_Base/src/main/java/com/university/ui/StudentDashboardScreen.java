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
import java.util.stream.Collectors;

public class StudentDashboardScreen extends BaseDashboardScreen {

    private final DatabaseManager db = DatabaseManager.getInstance();
    private final RegistrationService regService = RegistrationService.getInstance();
    private final NotificationService notif = NotificationService.getInstance();

    private Student student;
    private Map<String, Course> courseCache;

    @Override
    protected Node[] topBarInfoNodes() {
        Label name = UIHelper.makeLabel("👤  " + student.getFullName());
        name.setStyle(name.getStyle() + "-fx-text-fill:" + UIHelper.COLOR_MUTED + ";");
        return new Node[]{
                name,
                UIHelper.makeStatusBadge(student.getYearLabel(), UIHelper.COLOR_ACCENT),
                UIHelper.makeStatusBadge(student.getMajor(), UIHelper.COLOR_ACCENT2)
        };
    }

    @Override
    protected VBox buildSidebarContent() {
        long active = enrollments(Enrollment.Status.ENROLLED).count();
        long completed = enrollments(Enrollment.Status.COMPLETED).count();

        double gpa = student.getGpa();
        String gpaColor = gpa >= 3.7 ? UIHelper.COLOR_SUCCESS : gpa >= 2.5 ? UIHelper.COLOR_ACCENT : UIHelper.COLOR_WARNING;

        Label gpaNum = new Label(String.format("%.2f", gpa));
        gpaNum.setStyle("-fx-font-size:48px;-fx-font-weight:bold;-fx-text-fill:" + gpaColor + ";");
        VBox gpaCard = new VBox(6, gpaNum, UIHelper.makeSubtitle("Cumulative GPA"));
        gpaCard.setAlignment(Pos.CENTER);
        gpaCard.setPadding(new Insets(18));
        gpaCard.getStyleClass().add("profile-card");

        VBox sidebar = new VBox(14);
        Label lbl = UIHelper.makeSubtitle("MY OVERVIEW");
        lbl.setStyle(lbl.getStyle() + "-fx-font-size:10px;-fx-font-weight:bold;-fx-text-fill:#7D88AA;");
        sidebar.getChildren().addAll(
                lbl,
                gpaCard,
                UIHelper.makeStatCard("📚", "Active Courses", (int) active, UIHelper.COLOR_ACCENT),
                UIHelper.makeStatCard("✅", "Completed", (int) completed, UIHelper.COLOR_SUCCESS),
                UIHelper.makeStatCard("🏅", "Credits Earned", student.getTotalCredits(), UIHelper.COLOR_ACCENT2),
                UIHelper.makeSeparator(),
                buildProfileCard("👨‍🎓", student.getId(), student.getEmail())
        );
        return sidebar;
    }

    @Override
    protected Node buildContent() {
        ChromeTabPane tabs = new ChromeTabPane();
        tabs.setStyle("-fx-background-color: transparent;");
        tabs.addTab(new ChromeTab("📋 My Courses", this::buildMyCoursesPanel));
        tabs.addTab(new ChromeTab("➕ Register", this::buildRegisterPanel));
        tabs.addTab(new ChromeTab("🗓 Weekly Schedule", this::buildWeeklySchedulePanel));
        tabs.addTab(new ChromeTab("📄 Transcript", this::buildTranscriptPanel));
        tabs.addTab(new ChromeTab("🧮 GPA Calculator", this::buildGpaCalculatorPanel));
        tabs.addTab(new ChromeTab("📊 My Progress", this::buildProgressPanel));
        return tabs;
    }

    public javafx.scene.Scene build() {
        student = (Student) auth.getCurrentUser();
        courseCache = db.getAllCourses();
        return super.build();
    }

    private VBox buildMyCoursesPanel() {
        List<Enrollment> active = student.getEnrollments().stream()
                .filter(e -> e.getStatus() == Enrollment.Status.ENROLLED).toList();

        VBox panel = panel();
        panel.getChildren().add(headerRow("My Enrolled Courses", "Active registrations with grades and drop actions", active.size() + " Active", UIHelper.COLOR_ACCENT));

        if (active.isEmpty()) {
            panel.getChildren().add(emptyBox("📭", "Not enrolled in any courses yet.", "Go to Register tab to enroll."));
            return panel;
        }

        VBox cards = new VBox(12);
        active.forEach(e -> cards.getChildren().add(buildEnrollmentCard(e)));
        ScrollPane scroll = new ScrollPane(cards);
        scroll.setFitToWidth(true);
        scroll.setStyle("-fx-background-color:transparent;-fx-background:transparent;");
        VBox.setVgrow(scroll, Priority.ALWAYS);
        panel.getChildren().add(scroll);
        return panel;
    }

    private VBox buildEnrollmentCard(Enrollment enrollment) {
        HBox header = new HBox(12);
        header.setAlignment(Pos.CENTER_LEFT);
        Label name = new Label(enrollment.getCourseName());
        name.setStyle("-fx-font-size:16px;-fx-font-weight:bold;-fx-text-fill:" + UIHelper.COLOR_TEXT + ";");
        Region sp = new Region(); HBox.setHgrow(sp, Priority.ALWAYS);
        header.getChildren().addAll(
                UIHelper.makeStatusBadge(enrollment.getCourseId(), UIHelper.COLOR_ACCENT),
                name,
                sp,
                UIHelper.makeStatusBadge(enrollment.getCredits() + " credits", UIHelper.COLOR_ACCENT2)
        );

        HBox meta = new HBox(20,
                muted("Offering: " + safe(enrollment.getOfferingId())),
                muted("Term: " + safe(enrollment.getTerm()) + " " + enrollment.getAcademicYear()),
                muted("Grade: " + enrollment.getGradeDisplay())
        );

        Button dropBtn = UIHelper.makeDangerButton("Drop Course");
        dropBtn.setOnAction(e -> {
            if (!UIHelper.showConfirmation("Confirm Drop", "Drop " + enrollment.getCourseName() + "?")) return;
            try {
                regService.dropCourse(student.getId(), enrollment.getOfferingId());
                notif.sendDropConfirmation(student.getFullName(), enrollment.getCourseName());
                refreshStudentAndReload("Student Dashboard");
            } catch (UniversityException ex) { UIHelper.showError("Error", ex.getMessage()); }
        });

        VBox card = glassCard(12, header, meta, dropBtn);
        return card;
    }

    private VBox buildRegisterPanel() {
        Map<String, Course> courses = courseCache != null ? courseCache : db.getAllCourses();
        ObservableList<Course> all = FXCollections.observableArrayList(
                courses.values().stream().filter(Course::hasAvailableSeats).toList()
        );

        TableView<Course> table = GlassTable.<Course>create()
                .prop("Course", "courseId")
                .prop("Name", "courseName")
                .prop("Cr", "credits")
                .prop("Section", "sectionCode")
                .prop("Schedule", "schedule")
                .col("Seats", c -> c.getEnrolled() + "/" + c.getCapacity())
                .build();
        table.setItems(all);

        TextField search = UIHelper.makeTextField("🔍  Search by name, ID, or department...");
        ComboBox<String> deptFilter = new ComboBox<>();
        deptFilter.getItems().add("All");
        courses.values().stream().map(Course::getDepartment).filter(Objects::nonNull).distinct().sorted().forEach(deptFilter.getItems()::add);
        deptFilter.setValue("All");
        deptFilter.setStyle("-fx-background-color:rgba(10,15,31,0.86);-fx-text-fill:" + UIHelper.COLOR_TEXT + ";-fx-border-color:rgba(0,212,255,0.26);-fx-border-radius:8;-fx-background-radius:8;-fx-padding:8;");

        Runnable filter = () -> {
            String dept = deptFilter.getValue();
            String q = search.getText() == null ? "" : search.getText().toLowerCase();
            table.setItems(all.filtered(c ->
                    ("All".equals(dept) || safe(c.getDepartment()).equals(dept)) &&
                            (q.isEmpty()
                                    || safe(c.getCourseId()).toLowerCase().contains(q)
                                    || safe(c.getCourseName()).toLowerCase().contains(q)
                                    || safe(c.getDepartment()).toLowerCase().contains(q))));
        };
        search.textProperty().addListener((o, ov, nv) -> filter.run());
        deptFilter.setOnAction(e -> filter.run());

        SplitPane split = new SplitPane(table, buildCourseDetailPanel(table));
        UIHelper.styleGlassSplitPane(split);
        split.setDividerPositions(0.52);
        VBox.setVgrow(split, Priority.ALWAYS);

        Button enrollBtn = UIHelper.makePrimaryButton("✅  Enroll in Selected Offering");
        enrollBtn.setMaxWidth(Double.MAX_VALUE);
        enrollBtn.setOnAction(e -> {
            Course sel = table.getSelectionModel().getSelectedItem();
            if (sel == null) { UIHelper.showError("No Selection", "Please select a course offering."); return; }
            try {
                regService.enrollStudent(student.getId(), sel.getOfferingId());
                notif.sendEnrollmentConfirmation(student.getFullName(), sel.getCourseName());
                UIHelper.showSuccess("Enrolled", "You are now enrolled in " + sel.getCourseName() + ".");
                refreshStudentAndReload("Student Dashboard");
            } catch (UniversityException ex) { UIHelper.showError("Enrollment Failed", ex.getMessage()); }
        });

        VBox panel = panel();
        panel.getChildren().addAll(headerRow("Available Course Offerings", "Choose a specific section/offering to avoid schedule ambiguity", all.size() + " Open", UIHelper.COLOR_SUCCESS), new HBox(10, search, deptFilter), split, enrollBtn);
        return panel;
    }

    private VBox buildCourseDetailPanel(TableView<Course> courseTable) {
        VBox panel = new VBox(14);
        panel.setPadding(new Insets(16));
        panel.getStyleClass().add("card-glass-strong");
        Label placeholder = UIHelper.makeSubtitle("← Select a course offering to see details");
        panel.getChildren().add(placeholder);

        courseTable.getSelectionModel().selectedItemProperty().addListener((obs, old, course) -> {
            panel.getChildren().clear();
            if (course == null) { panel.getChildren().add(placeholder); return; }
            String sc = course.getStatus() == Course.Status.OPEN ? UIHelper.COLOR_SUCCESS : UIHelper.COLOR_DANGER;
            HBox badges = new HBox(10,
                    UIHelper.makeStatusBadge(course.getCourseId(), UIHelper.COLOR_ACCENT),
                    UIHelper.makeStatusBadge(course.getOfferingId(), UIHelper.COLOR_ACCENT2),
                    UIHelper.makeStatusBadge(course.getStatus().name(), sc));
            badges.setAlignment(Pos.CENTER_LEFT);

            Label name = UIHelper.makeTitle(course.getCourseName());
            name.setWrapText(true); name.setStyle(name.getStyle() + "-fx-font-size:18px;");

            GridPane meta = metaGrid(
                    "Department", course.getDepartment(),
                    "Credits", course.getCredits() + " credit hours",
                    "Section", course.getSectionCode(),
                    "Instructor", course.getInstructorName(),
                    "Schedule", course.getSchedule(),
                    "Room", course.getRoom(),
                    "Prerequisites", course.getPrerequisiteIds().isEmpty() ? "None" : String.join(", ", course.getPrerequisiteIds())
            );

            double pct = course.getCapacity() == 0 ? 0 : (double) course.getEnrolled() / course.getCapacity();
            ProgressBar seatBar = new ProgressBar(pct);
            seatBar.setPrefWidth(Double.MAX_VALUE);
            seatBar.setStyle("-fx-accent:" + (pct > 0.8 ? UIHelper.COLOR_DANGER : UIHelper.COLOR_SUCCESS) + ";");

            Label desc = new Label(safe(course.getDescription()));
            desc.setWrapText(true);
            desc.setStyle("-fx-text-fill:" + UIHelper.COLOR_MUTED + ";-fx-font-size:13px;");
            panel.getChildren().addAll(badges, name, UIHelper.makeSeparator(), meta, seatBar, UIHelper.makeSubtitle(course.getAvailableSeats() + " seats available"), UIHelper.makeSeparator(), UIHelper.makeLabel("About:"), desc);
        });
        return panel;
    }

    private VBox buildWeeklySchedulePanel() {
        List<ScheduleEntry> schedule = db.getStudentSchedule(student.getId());
        VBox panel = panel();
        panel.getChildren().add(headerRow("Weekly Schedule", "Your active course meetings arranged by day", schedule.size() + " Meetings", UIHelper.COLOR_ACCENT));

        HBox days = new HBox(10);
        days.setAlignment(Pos.TOP_LEFT);
        for (String day : weekDays()) {
            VBox dayCard = dayColumn(day, schedule.stream().filter(e -> day.equalsIgnoreCase(e.getDayOfWeek())).toList(), false);
            HBox.setHgrow(dayCard, Priority.ALWAYS);
            days.getChildren().add(dayCard);
        }
        panel.getChildren().add(days);
        VBox.setVgrow(days, Priority.ALWAYS);
        return panel;
    }

    private VBox buildTranscriptPanel() {
        double gpa = student.getGpa();
        String gpaColor = gpa >= 3.7 ? UIHelper.COLOR_SUCCESS : gpa >= 2.5 ? UIHelper.COLOR_ACCENT : UIHelper.COLOR_WARNING;

        HBox banner = new HBox(26,
                metricBox(String.format("%.2f", gpa), "Cumulative GPA", gpaColor),
                metricBox(String.valueOf(student.getTotalCredits()), "Credits Earned", UIHelper.COLOR_SUCCESS),
                metricBox(String.valueOf(student.getActiveCredits()), "Active Credits", UIHelper.COLOR_ACCENT)
        );
        banner.setAlignment(Pos.CENTER_LEFT);

        TableView<Enrollment> table = GlassTable.<Enrollment>create()
                .prop("Course", "courseId")
                .prop("Name", "courseName")
                .prop("Credits", "credits")
                .col("Status", e -> e.getStatus().name())
                .col("Total", e -> String.format("%.1f", e.getTotalGrade()))
                .col("Grade", Enrollment::getGradeDisplay)
                .build();
        table.setItems(FXCollections.observableArrayList(student.getEnrollments()));
        VBox.setVgrow(table, Priority.ALWAYS);

        VBox panel = panel();
        panel.getChildren().addAll(headerRow("Academic Transcript", "All active, completed, and withdrawn enrollment records", student.getEnrollments().size() + " Records", UIHelper.COLOR_ACCENT2), banner, table);
        return panel;
    }

    private VBox buildGpaCalculatorPanel() {
        VBox rows = new VBox(10);
        List<Enrollment> active = student.getEnrollments().stream().filter(e -> e.getStatus() == Enrollment.Status.ENROLLED).toList();
        List<TextField> credits = new ArrayList<>();
        List<ComboBox<Enrollment.Grade>> grades = new ArrayList<>();

        if (active.isEmpty()) rows.getChildren().add(UIHelper.makeSubtitle("No active courses. You can still use the manual rows below."));
        for (Enrollment e : active) addCalcRow(rows, credits, grades, e.getCourseId() + " — " + e.getCourseName(), e.getCredits());
        for (int i = 1; i <= 3; i++) addCalcRow(rows, credits, grades, "Manual Course " + i, 3);

        Label result = UIHelper.makeTitle("Expected GPA: —");
        result.setStyle(result.getStyle() + "-fx-font-size:22px;");
        Button calc = UIHelper.makePrimaryButton("Calculate Expected GPA");
        calc.setOnAction(e -> {
            double points = 0; int cr = 0;
            for (int i = 0; i < credits.size(); i++) {
                Enrollment.Grade g = grades.get(i).getValue();
                if (g == null || g == Enrollment.Grade.NOT_GRADED || g == Enrollment.Grade.INCOMPLETE) continue;
                int c = parseInt(credits.get(i).getText(), 0);
                if (c <= 0) continue;
                points += gradePoints(g) * c; cr += c;
            }
            result.setText(cr == 0 ? "Expected GPA: —" : "Expected GPA: " + String.format("%.2f", points / cr));
        });

        VBox panel = panel();
        panel.getChildren().addAll(headerRow("GPA Calculator", "Try expected grades before final results are posted", "Local Tool", UIHelper.COLOR_WARNING), rows, new HBox(12, calc, result));
        return panel;
    }

    private void addCalcRow(VBox rows, List<TextField> credits, List<ComboBox<Enrollment.Grade>> grades, String label, int defaultCredits) {
        HBox row = new HBox(10);
        row.setAlignment(Pos.CENTER_LEFT);
        Label name = UIHelper.makeLabel(label);
        name.setPrefWidth(320);
        TextField cr = UIHelper.makeTextField("Credits");
        cr.setText(String.valueOf(defaultCredits)); cr.setPrefWidth(90);
        ComboBox<Enrollment.Grade> grade = new ComboBox<>(FXCollections.observableArrayList(Enrollment.Grade.values()));
        grade.setValue(Enrollment.Grade.NOT_GRADED); grade.setPrefWidth(180);
        credits.add(cr); grades.add(grade);
        row.getChildren().addAll(name, cr, grade);
        rows.getChildren().add(glassCard(8, row));
    }

    private VBox buildProgressPanel() {
        long enrolled = enrollments(Enrollment.Status.ENROLLED).count();
        long completed = enrollments(Enrollment.Status.COMPLETED).count();
        long withdrawn = student.getEnrollments().stream().filter(e -> e.getStatus() == Enrollment.Status.WITHDRAWN || e.getStatus() == Enrollment.Status.DROPPED).count();
        int activeCredits = student.getActiveCredits();
        int completedCredits = student.getTotalCredits();

        HBox kpis = new HBox(12,
                UIHelper.makeKpiCard("GPA", String.format("%.2f", student.getGpa()), "out of 4.00", UIHelper.COLOR_SUCCESS),
                UIHelper.makeKpiCard("Active Credits", String.valueOf(activeCredits), "current load", UIHelper.COLOR_ACCENT),
                UIHelper.makeKpiCard("Completed Credits", String.valueOf(completedCredits), "earned", UIHelper.COLOR_SUCCESS),
                UIHelper.makeKpiCard("Weekly Meetings", String.valueOf(db.getStudentSchedule(student.getId()).size()), "schedule rows", UIHelper.COLOR_ACCENT2)
        );

        VBox insight = glassCard(12,
                UIHelper.makeTitle("Useful Academic Summary"),
                UIHelper.makeInsightLine("Active courses", String.valueOf(enrolled), UIHelper.COLOR_ACCENT),
                UIHelper.makeInsightLine("Completed courses", String.valueOf(completed), UIHelper.COLOR_SUCCESS),
                UIHelper.makeInsightLine("Withdrawn records", String.valueOf(withdrawn), UIHelper.COLOR_DANGER),
                UIHelper.makeInsightLine("Standing", standing(student.getGpa()), UIHelper.COLOR_WARNING)
        );

        VBox panel = panel();
        panel.getChildren().addAll(headerRow("My Progress", "Compact progress view without oversized charts", standing(student.getGpa()), UIHelper.COLOR_ACCENT), kpis, insight);
        return panel;
    }

    private VBox dayColumn(String day, List<ScheduleEntry> entries, boolean instructorView) {
        VBox card = new VBox(8);
        card.setPadding(new Insets(12));
        card.getStyleClass().add("card-glass");
        card.setMinHeight(420);
        HBox head = new HBox(8);
        head.setAlignment(Pos.CENTER_LEFT);
        Region sp = new Region(); HBox.setHgrow(sp, Priority.ALWAYS);
        head.getChildren().addAll(styledLabel(day, 14, UIHelper.COLOR_TEXT), sp, UIHelper.makeStatusBadge(entries.size() + "", entries.isEmpty() ? UIHelper.COLOR_MUTED : UIHelper.COLOR_ACCENT));
        VBox list = new VBox(8);
        if (entries.isEmpty()) list.getChildren().add(emptyMini("—", "Free"));
        else entries.forEach(e -> list.getChildren().add(scheduleMiniCard(e, instructorView)));
        ScrollPane scroll = new ScrollPane(list);
        scroll.setFitToWidth(true); scroll.setStyle("-fx-background-color:transparent;-fx-background:transparent;");
        VBox.setVgrow(scroll, Priority.ALWAYS);
        card.getChildren().addAll(head, scroll);
        return card;
    }

    private VBox scheduleMiniCard(ScheduleEntry e, boolean instructorView) {
        String color = meetingColor(e.getMeetingType());
        VBox card = new VBox(5);
        card.setPadding(new Insets(9));
        card.setStyle("-fx-background-color:" + color + "18;-fx-background-radius:10;-fx-border-color:" + color + "66;-fx-border-radius:10;-fx-border-width:1;");
        HBox top = new HBox(6);
        Region sp = new Region(); HBox.setHgrow(sp, Priority.ALWAYS);
        top.getChildren().addAll(UIHelper.makeStatusBadge(e.getCourseId(), color), sp, UIHelper.makeStatusBadge(e.getMeetingType(), color));
        Label name = UIHelper.makeLabel(e.getCourseName()); name.setWrapText(true); name.setStyle(name.getStyle() + "-fx-font-weight:bold;");
        card.getChildren().addAll(top, name, muted("⏱ " + e.getTimeRange()), muted("📍 " + e.getRoomId()), muted("👨‍🏫 " + safe(e.getInstructorNames())));
        return card;
    }

    private VBox emptyMini(String icon, String text) {
        VBox box = new VBox(6, new Label(icon), UIHelper.makeSubtitle(text));
        box.setAlignment(Pos.CENTER); box.setPadding(new Insets(22));
        box.getStyleClass().add("card-glass-soft");
        return box;
    }

    private VBox metricBox(String value, String label, String color) {
        return glassCard(10, styledLabel(value, 26, color), UIHelper.makeSubtitle(label));
    }

    private GridPane metaGrid(String... pairs) {
        GridPane meta = new GridPane();
        meta.setHgap(16); meta.setVgap(8); meta.setPadding(new Insets(14));
        meta.getStyleClass().add("card-glass-soft");
        for (int i = 0; i < pairs.length; i += 2) meta.addRow(i / 2, muted(pairs[i] + ":"), UIHelper.makeLabel(safe(pairs[i + 1])));
        return meta;
    }

    private VBox glassCard(double padding, Node... nodes) {
        VBox box = new VBox(10, nodes);
        box.setPadding(new Insets(padding));
        box.getStyleClass().add("card-glass");
        return box;
    }

    private String[] weekDays() { return new String[]{"Saturday", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday"}; }
    private String meetingColor(String type) { return "LAB".equalsIgnoreCase(type) ? UIHelper.COLOR_SUCCESS : "SECTION".equalsIgnoreCase(type) ? UIHelper.COLOR_ACCENT2 : UIHelper.COLOR_ACCENT; }
    private String safe(String value) { return value == null || value.isBlank() ? "N/A" : value; }
    private int parseInt(String value, int fallback) { try { return Integer.parseInt(value.trim()); } catch (Exception e) { return fallback; } }
    private String standing(double gpa) { return gpa >= 3.7 ? "Excellent" : gpa >= 3.0 ? "Good" : gpa >= 2.0 ? "Satisfactory" : "Needs Improvement"; }

    private double gradePoints(Enrollment.Grade grade) {
        return switch (grade == null ? Enrollment.Grade.NOT_GRADED : grade) {
            case A_PLUS, A -> 4.0; case A_MINUS -> 3.7; case B_PLUS -> 3.3; case B -> 3.0; case B_MINUS -> 2.7;
            case C_PLUS -> 2.3; case C -> 2.0; case C_MINUS -> 1.7; case D_PLUS -> 1.3; case D -> 1.0; case D_MINUS -> 0.7;
            case F -> 0.0; default -> 0.0;
        };
    }

    private void refreshStudentAndReload(String title) {
        student = db.getStudent(student.getId());
        auth.refreshCurrentUser(student);
        nav.navigateTo(new StudentDashboardScreen().build(), title);
    }

    private java.util.stream.Stream<Enrollment> enrollments(Enrollment.Status status) {
        return student.getEnrollments().stream().filter(e -> e.getStatus() == status);
    }
}
