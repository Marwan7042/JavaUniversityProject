package com.university.ui;

import com.university.dao.DatabaseManager;
import com.university.model.Course;
import com.university.service.AdminPermissionService.Permission;
import com.university.util.GlassTable;
import com.university.util.UIHelper;
import javafx.collections.FXCollections;
import javafx.collections.ObservableList;
import javafx.geometry.Insets;
import javafx.geometry.Pos;
import javafx.scene.Node;
import javafx.scene.control.*;
import javafx.scene.layout.*;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.*;
import java.util.function.Predicate;
import java.util.stream.Collectors;

/**
 * Admin Course Offerings panel.
 *
 * Extracted from AdminDashboardScreen to keep the admin file smaller.
 *
 * Rules:
 * - Status shown to admin is only OPEN / CLOSED.
 * - Filtering is based on academic plan: Major + Year + Term + Academic Year.
 * - "Show all offerings" bypasses academic-plan filtering.
 * - Add/Edit Offering uses planned-course picker, with optional Show All Courses.
 */
public class AdminCourseOfferingsPanel {

    private final DatabaseManager db = DatabaseManager.getInstance();
    private final Predicate<Permission> can;
    private final Predicate<Permission> checkPermission;

    private ObservableList<Course> allOfferings;
    private TableView<Course> table;

    private ComboBox<String> majorFilter;
    private ComboBox<Integer> yearFilter;
    private ComboBox<String> termFilter;
    private TextField academicYearFilter;
    private CheckBox showAllOfferings;
    private TextField search;

    public AdminCourseOfferingsPanel(Predicate<Permission> can, Predicate<Permission> checkPermission) {
        this.can = can;
        this.checkPermission = checkPermission;
    }

    public Node build() {
        allOfferings = FXCollections.observableArrayList(db.getAllCourses().values());

        VBox root = new VBox(14);
        root.setPadding(new Insets(20, 24, 20, 24));
        root.setStyle("-fx-background-color: transparent;");

        root.getChildren().addAll(
                buildHeader(),
                buildFilterCard(),
                buildActionRow(),
                buildMainSplit()
        );

        VBox.setVgrow(root.getChildren().get(root.getChildren().size() - 1), Priority.ALWAYS);
        refreshTable();

        return root;
    }

    private HBox buildHeader() {
        VBox titleBox = new VBox(4);

        Label title = UIHelper.makeTitle("Course Offerings");
        Label sub = UIHelper.makeSubtitle("Open real sections for students. Filter by academic plan or show the full list.");

        titleBox.getChildren().addAll(title, sub);

        Region spacer = new Region();
        HBox.setHgrow(spacer, Priority.ALWAYS);

        Label count = UIHelper.makeStatusBadge(allOfferings.size() + " Offerings", UIHelper.COLOR_SUCCESS);

        HBox row = new HBox(12, titleBox, spacer, count);
        row.setAlignment(Pos.CENTER_LEFT);

        return row;
    }

    private VBox buildFilterCard() {
        majorFilter = darkCombo(loadMajorLabels(), "Major / Program");
        yearFilter = new ComboBox<>(FXCollections.observableArrayList(1, 2, 3, 4, 5, 6, 7));
        yearFilter.setPromptText("Year");
        styleControl(yearFilter);

        termFilter = darkCombo(List.of("TERM1", "TERM2", "SUMMER"), "Term");
        academicYearFilter = UIHelper.makeTextField("Academic Year");
        styleControl(academicYearFilter);

        showAllOfferings = new CheckBox("Show all offerings");
        showAllOfferings.setStyle("-fx-text-fill: " + UIHelper.COLOR_TEXT + "; -fx-font-size: 12px; -fx-font-weight: bold;");

        if (!majorFilter.getItems().isEmpty()) {
            majorFilter.setValue(majorFilter.getItems().get(0));
        }

        yearFilter.setValue(1);
        termFilter.setValue("TERM1");
        academicYearFilter.setText("2026");

        Label title = new Label("Academic Plan Filter");
        title.setStyle("-fx-text-fill: " + UIHelper.COLOR_ACCENT + "; -fx-font-size: 13px; -fx-font-weight: bold;");

        Label hint = UIHelper.makeSubtitle("Default view shows only offerings matching Major + Year + Term. Enable Show all offerings for the full list.");

        GridPane grid = new GridPane();
        grid.setHgap(10);
        grid.setVgap(8);
        grid.add(labeled("Major / Program", majorFilter), 0, 0);
        grid.add(labeled("Student Year", yearFilter), 1, 0);
        grid.add(labeled("Term", termFilter), 2, 0);
        grid.add(labeled("Academic Year", academicYearFilter), 3, 0);
        grid.add(showAllOfferings, 4, 0);

        ColumnConstraints c0 = new ColumnConstraints();
        c0.setPercentWidth(42);
        ColumnConstraints c1 = new ColumnConstraints();
        c1.setPercentWidth(12);
        ColumnConstraints c2 = new ColumnConstraints();
        c2.setPercentWidth(15);
        ColumnConstraints c3 = new ColumnConstraints();
        c3.setPercentWidth(15);
        ColumnConstraints c4 = new ColumnConstraints();
        c4.setPercentWidth(16);
        grid.getColumnConstraints().addAll(c0, c1, c2, c3, c4);

        VBox card = new VBox(10, title, hint, grid);
        card.setPadding(new Insets(14));
        card.setStyle(
                "-fx-background-color: rgba(10,15,31,0.86);" +
                        "-fx-background-radius: 16;" +
                        "-fx-border-color: rgba(0,212,255,0.26);" +
                        "-fx-border-radius: 16;" +
                        "-fx-border-width: 1.1;" +
                        "-fx-effect: dropshadow(gaussian,rgba(0,212,255,0.10),16,0,0,2);"
        );

        majorFilter.setOnAction(e -> refreshTable());
        yearFilter.setOnAction(e -> refreshTable());
        termFilter.setOnAction(e -> refreshTable());
        academicYearFilter.textProperty().addListener((o, oldValue, newValue) -> refreshTable());
        showAllOfferings.setOnAction(e -> refreshTable());

        return card;
    }

    private HBox buildActionRow() {
        search = UIHelper.makeTextField("🔍 Search filtered offerings...");
        HBox.setHgrow(search, Priority.ALWAYS);
        search.textProperty().addListener((o, oldValue, q) -> refreshTable());

        Button addBtn = UIHelper.makePrimaryButton("➕ Add Offering");
        Button editBtn = UIHelper.makeSecondaryButton("✏ Edit");
        Button toggleBtn = UIHelper.makeSecondaryButton("🔄 Toggle Open/Closed");
        Button applyTermStatusBtn = UIHelper.makeSecondaryButton("✅ Apply Term Status");
        Button deleteBtn = UIHelper.makeDangerButton("🗑 Delete");

        configurePermissionButton(addBtn, Permission.MANAGE_COURSE_OFFERINGS);
        configurePermissionButton(editBtn, Permission.MANAGE_COURSE_OFFERINGS);
        configurePermissionButton(toggleBtn, Permission.MANAGE_COURSE_OFFERINGS);
        configurePermissionButton(applyTermStatusBtn, Permission.MANAGE_COURSE_OFFERINGS);
        configurePermissionButton(deleteBtn, Permission.DELETE_RECORDS);

        addBtn.setOnAction(e -> {
            if (!check(Permission.MANAGE_COURSE_OFFERINGS)) return;
            showOfferingDialog(null);
        });

        editBtn.setOnAction(e -> {
            Course selected = selectedOffering();

            if (selected == null) return;
            if (!check(Permission.MANAGE_COURSE_OFFERINGS)) return;

            showOfferingDialog(selected);
        });

        toggleBtn.setOnAction(e -> {
            Course selected = selectedOffering();

            if (selected == null) return;
            if (!check(Permission.MANAGE_COURSE_OFFERINGS)) return;

            selected.setStatus(selected.getStatus() == Course.Status.OPEN ? Course.Status.CLOSED : Course.Status.OPEN);

            try {
                db.insertCourse(selected);
                reloadData();
            } catch (RuntimeException ex) {
                UIHelper.showError("Update Failed", rootCauseMessage(ex));
            }
        });

        applyTermStatusBtn.setOnAction(e -> applyTermStatus());

        deleteBtn.setOnAction(e -> {
            Course selected = selectedOffering();

            if (selected == null) return;
            if (!check(Permission.DELETE_RECORDS)) return;

            if (!UIHelper.showConfirmation(
                    "Delete Offering",
                    "Delete offering " + selected.getOfferingId() + " for " + selected.getCourseName() + "?"
            )) {
                return;
            }

            try {
                db.deleteCourse(selected.getOfferingId());
                reloadData();
            } catch (RuntimeException ex) {
                UIHelper.showError("Delete Failed", rootCauseMessage(ex));
            }
        });

        HBox row = new HBox(10, search, addBtn, editBtn, toggleBtn, applyTermStatusBtn, deleteBtn);
        row.setAlignment(Pos.CENTER_LEFT);

        return row;
    }

    private SplitPane buildMainSplit() {
        table = GlassTable.<Course>create()
                .prop("Offering", "offeringId")
                .col("Course", c -> c.getCourseId() + " • " + shortText(c.getCourseName(), 28))
                .col("Term", c -> c.getTerm() + " " + c.getAcademicYear())
                .col("Seats", c -> c.getEnrolled() + "/" + c.getCapacity())
                .statusCol("Status", this::displayStatus)
                .build();

        table.setItems(allOfferings);
        VBox.setVgrow(table, Priority.ALWAYS);

        VBox details = buildDetailPanel();

        table.getSelectionModel().selectedItemProperty().addListener((obs, old, selected) -> updateDetails(details, selected));
        if (!allOfferings.isEmpty()) {
            table.getSelectionModel().selectFirst();
        }

        SplitPane split = new SplitPane(table, details);
        UIHelper.styleGlassSplitPane(split);
        split.setDividerPositions(0.58);
        VBox.setVgrow(split, Priority.ALWAYS);

        return split;
    }

    private VBox buildDetailPanel() {
        VBox box = new VBox(10);
        box.setPadding(new Insets(14));
        box.setStyle(
                "-fx-background-color: rgba(10,15,31,0.78);" +
                        "-fx-background-radius: 16;" +
                        "-fx-border-color: rgba(124,92,252,0.26);" +
                        "-fx-border-radius: 16;" +
                        "-fx-border-width: 1;"
        );

        updateDetails(box, null);
        return box;
    }

    private void updateDetails(VBox box, Course c) {
        box.getChildren().clear();

        if (c == null) {
            Label title = smallTitle("Selected Offering Details");
            Label sub = UIHelper.makeSubtitle("Select an offering from the table.");
            box.getChildren().addAll(title, sub);
            return;
        }

        box.getChildren().addAll(
                bigTitle(c.getCourseId() + " • " + c.getCourseName()),
                UIHelper.makeStatusBadge(c.getOfferingId(), UIHelper.COLOR_ACCENT),
                UIHelper.makeStatusBadge(displayStatus(c), c.getStatus() == Course.Status.OPEN ? UIHelper.COLOR_SUCCESS : UIHelper.COLOR_WARNING),
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
    }

    private void refreshTable() {
        if (table == null || allOfferings == null) return;

        ObservableList<Course> filtered = filterOfferings();
        table.setItems(filtered);

        if (!filtered.isEmpty()) {
            table.getSelectionModel().selectFirst();
        }
    }

    private ObservableList<Course> filterOfferings() {
        String q = search == null || search.getText() == null ? "" : search.getText().trim().toLowerCase();
        String selectedTerm = valueOrDefault(termFilter == null ? null : termFilter.getValue(), "TERM1");
        int selectedAcademicYear = parseInt(academicYearFilter == null ? null : academicYearFilter.getText(), 2026);

        boolean showAll = showAllOfferings != null && showAllOfferings.isSelected();

        Set<String> allowedCourseIds = new LinkedHashSet<>();

        if (!showAll) {
            String majorId = parseIdFromLabel(majorFilter == null ? null : majorFilter.getValue());
            int year = yearFilter == null || yearFilter.getValue() == null ? 1 : yearFilter.getValue();

            db.getCoursesForOfferingPicker(majorId, year, selectedTerm, false)
                    .forEach(c -> allowedCourseIds.add(c.getCourseId()));
        }

        return allOfferings.filtered(c -> {
            if (!showAll) {
                if (!selectedTerm.equalsIgnoreCase(safe(c.getTerm()))) return false;
                if (c.getAcademicYear() != selectedAcademicYear) return false;
                if (!allowedCourseIds.contains(c.getCourseId())) return false;
            }

            if (q.isBlank()) return true;

            return safe(c.getOfferingId()).toLowerCase().contains(q)
                    || safe(c.getCourseId()).toLowerCase().contains(q)
                    || safe(c.getCourseName()).toLowerCase().contains(q)
                    || safe(c.getDepartment()).toLowerCase().contains(q)
                    || safe(c.getInstructorName()).toLowerCase().contains(q)
                    || safe(c.getRoom()).toLowerCase().contains(q)
                    || displayStatus(c).toLowerCase().contains(q);
        });
    }

    private void showOfferingDialog(Course existing) {
        boolean editMode = existing != null;

        ComboBox<String> planMajor = darkCombo(loadMajorLabels(), "Major / Program");
        ComboBox<Integer> planYear = new ComboBox<>(FXCollections.observableArrayList(1, 2, 3, 4, 5, 6, 7));
        planYear.setPromptText("Student Year");
        styleControl(planYear);

        ComboBox<String> planTerm = darkCombo(List.of("TERM1", "TERM2", "SUMMER"), "Recommended Term");
        CheckBox showAllCourses = new CheckBox("Show all catalog courses");
        showAllCourses.setStyle("-fx-text-fill: " + UIHelper.COLOR_TEXT + "; -fx-font-size: 12px;");

        ComboBox<String> courseChoice = darkCombo(new ArrayList<>(), "Select Course");

        if (!planMajor.getItems().isEmpty()) {
            planMajor.setValue(planMajor.getItems().get(0));
        }

        planYear.setValue(1);
        planTerm.setValue(editMode ? existing.getTerm() : "TERM1");

        Runnable reloadCourseChoices = () -> {
            String majorId = parseIdFromLabel(planMajor.getValue());
            int year = planYear.getValue() == null ? 1 : planYear.getValue();
            String termValue = valueOrDefault(planTerm.getValue(), "TERM1");

            List<String> labels = loadCourseChoiceLabels(majorId, year, termValue, showAllCourses.isSelected());
            courseChoice.getItems().setAll(labels);

            if (editMode) {
                String currentLabel = findCourseChoiceLabel(existing.getCourseId(), labels);
                if (currentLabel != null) {
                    courseChoice.setValue(currentLabel);
                    return;
                }
            }

            if (!labels.isEmpty()) {
                courseChoice.setValue(labels.get(0));
            } else {
                courseChoice.setValue(null);
            }
        };

        planMajor.setOnAction(e -> reloadCourseChoices.run());
        planYear.setOnAction(e -> reloadCourseChoices.run());
        planTerm.setOnAction(e -> reloadCourseChoices.run());
        showAllCourses.setOnAction(e -> reloadCourseChoices.run());
        reloadCourseChoices.run();

        ComboBox<String> term = darkCombo(List.of("TERM1", "TERM2", "SUMMER"), "Offering Term");
        TextField academicYear = darkTextField("Academic Year");
        TextField sectionCode = darkTextField("e.g. L01");
        TextField capacity = darkTextField("Capacity");
        ComboBox<String> status = darkCombo(List.of("OPEN", "CLOSED"), "Status");

        ComboBox<String> meetingType = darkCombo(List.of("LECTURE", "SECTION", "LAB"), "Meeting Type");
        ComboBox<String> day = darkCombo(List.of("Saturday", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday"), "Day");
        ComboBox<String> slot = darkCombo(loadSlotLabels(), "Time Slot");
        ComboBox<String> room = darkCombo(new ArrayList<>(), "Room");
        ComboBox<String> instructor = darkCombo(loadInstructorLabels(), "Instructor");
        ComboBox<String> role = darkCombo(List.of("LECTURE", "ASSISTANT", "LAB"), "Teaching Role");

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
            term.setValue(existing.getTerm());
            academicYear.setText(String.valueOf(existing.getAcademicYear()));
            sectionCode.setText(existing.getSectionCode());
            capacity.setText(String.valueOf(existing.getCapacity()));
            status.setValue(displayStatus(existing));

            meetingType.setValue(valueOrDefault(existing.getMeetingType(), "LECTURE"));
            day.setValue(existing.getDayOfWeek());
            slot.setValue(existing.getSlotId() == null ? null : findSlotLabel(existing.getSlotId()));
            room.getItems().setAll(loadRoomsForMeetingType(valueOrDefault(meetingType.getValue(), "LECTURE")));
            room.setValue(existing.getRoom());
            role.setValue(valueOrDefault(existing.getInstructorRole(), roleFromMeetingType(existing.getMeetingType())));
            instructor.setValue(findInstructorLabel(existing.getInstructorId()));
        } else {
            term.setValue(valueOrDefault(termFilter.getValue(), "TERM1"));
            academicYear.setText(valueOrDefault(academicYearFilter.getText(), "2026"));
            sectionCode.setText("L01");
            capacity.setText("30");
            status.setValue("OPEN");
            meetingType.setValue("LECTURE");
            role.setValue("LECTURE");
            room.getItems().setAll(loadRoomsForMeetingType("LECTURE"));
        }

        GridPane pickerGrid = formGrid(
                "Major / Program", planMajor,
                "Student Year", planYear,
                "Recommended Term", planTerm,
                "Show All Courses", showAllCourses,
                "Course", courseChoice
        );

        GridPane offeringGrid = formGrid(
                "Offering Term", term,
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

        Label rule = UIHelper.makeSubtitle("Course picker uses Major + Year + Term. Use Show all courses for extra/special offerings.");

        VBox content = new VBox(14,
                smallTitle("Course Picker"),
                pickerGrid,
                UIHelper.makeSeparator(),
                smallTitle("Offering Data"),
                offeringGrid,
                UIHelper.makeSeparator(),
                smallTitle("Schedule / Teaching Assignment"),
                scheduleGrid,
                rule
        );
        content.setPadding(new Insets(8));

        showDialog(editMode ? "Edit Course Offering" : "Add Course Offering", content, () -> {
            try {
                String selectedCourseId = parseCourseIdFromLabel(courseChoice.getValue());

                if (selectedCourseId == null || selectedCourseId.isBlank()) {
                    throw new IllegalArgumentException("Please select a course.");
                }

                Course catalogCourse = db.getCourseCatalog().get(selectedCourseId);

                if (catalogCourse == null) {
                    throw new IllegalArgumentException("Selected course was not found in the course catalog.");
                }

                Course c = editMode ? existing : new Course();

                if (!editMode || c.getOfferingId() == null || c.getOfferingId().isBlank()) {
                    c.setOfferingId(db.generateOfferingId());
                }

                c.setCourseId(catalogCourse.getCourseId());
                c.setCourseName(catalogCourse.getCourseName());
                c.setDepartment(catalogCourse.getDepartment());
                c.setCredits(catalogCourse.getCredits());
                c.setDescription(catalogCourse.getDescription());

                c.setTerm(valueOrDefault(term.getValue(), "TERM1"));
                c.setAcademicYear(parseInt(academicYear.getText(), 2026));
                c.setSectionCode(valueOrDefault(sectionCode.getText(), "L01").trim().toUpperCase());
                c.setCapacity(parseInt(capacity.getText(), 30));
                c.setStatus("OPEN".equalsIgnoreCase(status.getValue()) ? Course.Status.OPEN : Course.Status.CLOSED);

                c.setMeetingType(valueOrDefault(meetingType.getValue(), "LECTURE"));
                c.setDayOfWeek(valueOrDefault(day.getValue(), "Saturday"));
                c.setSlotId(parseSlotId(slot.getValue()));
                c.setRoom(valueOrDefault(room.getValue(), ""));

                String instructorId = parseIdFromLabel(instructor.getValue());
                c.setInstructorId(instructorId);
                c.setInstructorRole(valueOrDefault(role.getValue(), roleFromMeetingType(c.getMeetingType())));

                db.insertCourse(c);
                reloadData();
            } catch (Exception ex) {
                UIHelper.showError("Course Offering Save Failed", rootCauseMessage(ex));
            }
        });
    }

    private void applyTermStatus() {
        if (!check(Permission.MANAGE_COURSE_OFFERINGS)) return;

        String selectedTerm = valueOrDefault(termFilter.getValue(), "TERM1");
        int selectedYear = parseInt(academicYearFilter.getText(), 2026);

        if (!UIHelper.showConfirmation(
                "Apply Term Status",
                "This will OPEN offerings in " + selectedTerm + " " + selectedYear +
                        " and CLOSE all other offerings in " + selectedYear + ". Continue?"
        )) {
            return;
        }

        try {
            db.applyOfferingStatusForTerm(selectedTerm, selectedYear);
            reloadData();
            UIHelper.showSuccess("Status Updated", selectedTerm + " " + selectedYear + " offerings are now OPEN. Other offerings in the same year are CLOSED.");
        } catch (RuntimeException ex) {
            UIHelper.showError("Status Update Failed", rootCauseMessage(ex));
        }
    }

    private void reloadData() {
        allOfferings.setAll(db.getAllCourses().values());
        refreshTable();
    }

    private Course selectedOffering() {
        Course selected = table.getSelectionModel().getSelectedItem();

        if (selected == null) {
            UIHelper.showError("No Selection", "Select an offering first.");
            return null;
        }

        return selected;
    }

    private boolean check(Permission permission) {
        return checkPermission.test(permission);
    }

    private void configurePermissionButton(Button button, Permission permission) {
        if (!can.test(permission)) {
            button.setDisable(true);
            button.setTooltip(new Tooltip("Not allowed for your admin level."));
            button.setStyle(button.getStyle() + "-fx-opacity: 0.45;");
        }
    }

    private String displayStatus(Course c) {
        return c != null && c.getStatus() == Course.Status.OPEN ? "OPEN" : "CLOSED";
    }

    private VBox labeled(String label, Node control) {
        Label l = new Label(label);
        l.setStyle("-fx-text-fill: " + UIHelper.COLOR_MUTED + "; -fx-font-size: 11px;");
        VBox box = new VBox(5, l, control);
        VBox.setVgrow(control, Priority.NEVER);
        if (control instanceof Region r) {
            r.setMaxWidth(Double.MAX_VALUE);
        }
        return box;
    }

    private GridPane formGrid(Object... pairs) {
        GridPane grid = new GridPane();
        grid.setHgap(16);
        grid.setVgap(12);

        for (int i = 0; i < pairs.length; i += 2) {
            Label label = new Label(String.valueOf(pairs[i]));
            label.setStyle("-fx-text-fill: " + UIHelper.COLOR_MUTED + "; -fx-font-size: 12px;");

            Node control = (Node) pairs[i + 1];
            if (control instanceof Region r) {
                r.setPrefWidth(420);
                r.setMaxWidth(Double.MAX_VALUE);
            }

            grid.add(label, 0, i / 2);
            grid.add(control, 1, i / 2);
        }

        ColumnConstraints labelCol = new ColumnConstraints();
        labelCol.setMinWidth(140);
        labelCol.setPrefWidth(150);

        ColumnConstraints inputCol = new ColumnConstraints();
        inputCol.setHgrow(Priority.ALWAYS);

        grid.getColumnConstraints().addAll(labelCol, inputCol);

        return grid;
    }

    private void showDialog(String title, Node content, Runnable onSave) {
        Dialog<Void> dialog = new Dialog<>();
        dialog.setTitle(title);
        dialog.setResizable(true);

        DialogPane pane = dialog.getDialogPane();
        pane.getStylesheets().add(UIHelper.getStylesheet());
        pane.setPrefWidth(820);
        pane.setPrefHeight(650);
        pane.setStyle(
                "-fx-background-color: rgba(8,11,20,0.96);" +
                        "-fx-background-radius: 18;" +
                        "-fx-border-color: rgba(0,212,255,0.30);" +
                        "-fx-border-radius: 18;" +
                        "-fx-border-width: 1.2;"
        );

        StackPane shell = new StackPane(content);
        shell.setPadding(new Insets(16));
        shell.setStyle(
                "-fx-background-color: rgba(10,15,31,0.90);" +
                        "-fx-background-radius: 16;" +
                        "-fx-border-color: rgba(124,92,252,0.22);" +
                        "-fx-border-radius: 16;" +
                        "-fx-border-width: 1;"
        );

        ScrollPane scroll = new ScrollPane(shell);
        scroll.setFitToWidth(true);
        scroll.setHbarPolicy(ScrollPane.ScrollBarPolicy.NEVER);
        scroll.setVbarPolicy(ScrollPane.ScrollBarPolicy.AS_NEEDED);
        scroll.setPrefViewportHeight(510);
        scroll.setStyle("-fx-background: transparent; -fx-background-color: transparent; -fx-border-color: transparent;");

        pane.setContent(scroll);

        ButtonType saveType = new ButtonType("Save / Apply", ButtonBar.ButtonData.OK_DONE);
        pane.getButtonTypes().addAll(saveType, ButtonType.CANCEL);

        Node saveButton = pane.lookupButton(saveType);
        if (saveButton instanceof Button b) {
            b.setStyle(
                    "-fx-background-color: linear-gradient(to right,#00D4FF,#2DE2E6);" +
                            "-fx-text-fill: #020617;" +
                            "-fx-font-weight: bold;" +
                            "-fx-background-radius: 10;" +
                            "-fx-padding: 9 18;"
            );
        }

        Node closeButton = pane.lookupButton(ButtonType.CANCEL);
        if (closeButton instanceof Button b) {
            b.setText("Close");
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
            if (bt == saveType) onSave.run();
            return null;
        });

        dialog.showAndWait();
    }

    private ComboBox<String> darkCombo(Collection<String> values, String prompt) {
        ComboBox<String> combo = new ComboBox<>(FXCollections.observableArrayList(values));
        combo.setPromptText(prompt);
        styleControl(combo);
        return combo;
    }

    private TextField darkTextField(String prompt) {
        TextField field = UIHelper.makeTextField(prompt);
        styleControl(field);
        return field;
    }

    private void styleControl(Control control) {
        control.setPrefHeight(40);
        control.setMaxWidth(Double.MAX_VALUE);
        control.setStyle(
                "-fx-background-color: rgba(17,24,39,0.94);" +
                        "-fx-text-fill: #E5F4FF;" +
                        "-fx-prompt-text-fill: #64748B;" +
                        "-fx-border-color: rgba(0,212,255,0.24);" +
                        "-fx-border-radius: 10;" +
                        "-fx-background-radius: 10;" +
                        "-fx-padding: 7 10;"
        );
    }

    private Label smallTitle(String text) {
        Label label = new Label(text);
        label.setStyle("-fx-text-fill: " + UIHelper.COLOR_TEXT + "; -fx-font-size: 13px; -fx-font-weight: bold;");
        return label;
    }

    private Label bigTitle(String text) {
        Label label = new Label(text);
        label.setStyle("-fx-text-fill: " + UIHelper.COLOR_TEXT + "; -fx-font-size: 18px; -fx-font-weight: bold;");
        return label;
    }

    private List<String> loadMajorLabels() {
        List<String> labels = loadOptions("""
            SELECT major_name + ' (' + major_id + ')'
            FROM majors
            ORDER BY major_name
        """);

        return labels.isEmpty() ? List.of("Computer Science (MCS)") : labels;
    }

    private List<String> loadCourseChoiceLabels(String majorId, int year, String term, boolean showAllCourses) {
        return db.getCoursesForOfferingPicker(majorId, year, term, showAllCourses).stream()
                .map(c -> c.getCourseId() + " — " + c.getCourseName() + " [" + c.getDepartment() + "]")
                .collect(Collectors.toList());
    }

    private String findCourseChoiceLabel(String courseId, List<String> labels) {
        if (courseId == null || labels == null) return null;

        return labels.stream()
                .filter(label -> label.startsWith(courseId + " "))
                .findFirst()
                .orElse(null);
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

        return values.isEmpty()
                ? ("LAB".equals(roomType) ? List.of("LAB001") : List.of("L001"))
                : values;
    }

    private List<String> loadInstructorLabels() {
        List<String> values = loadOptions("""
            SELECT title + ' ' + first_name + ' ' + last_name + ' (' + id + ')'
            FROM instructors
            WHERE status = 'ACTIVE'
            ORDER BY id
        """);

        return values.isEmpty() ? List.of("Instructor (INS001)") : values;
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
            System.err.println("[ADMIN OFFERINGS] Could not load options: " + ex.getMessage());
        }

        return values;
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

    private String parseCourseIdFromLabel(String label) {
        if (label == null || label.isBlank()) return null;

        int cut = label.indexOf(' ');
        return cut <= 0 ? label.trim() : label.substring(0, cut).trim();
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

    private String roleFromMeetingType(String meetingType) {
        if ("LAB".equalsIgnoreCase(meetingType)) return "LAB";
        if ("SECTION".equalsIgnoreCase(meetingType)) return "ASSISTANT";
        return "LECTURE";
    }

    private String shortText(String value, int maxLength) {
        String clean = safe(value);
        if (clean.length() <= maxLength) return clean;
        return clean.substring(0, Math.max(0, maxLength - 3)) + "...";
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

    private String safe(String value) {
        return value == null || value.isBlank() ? "N/A" : value;
    }

    private String rootCauseMessage(Throwable throwable) {
        Throwable t = throwable;
        while (t.getCause() != null) t = t.getCause();
        String message = t.getMessage();
        return message == null || message.isBlank() ? t.getClass().getSimpleName() : message;
    }
}
