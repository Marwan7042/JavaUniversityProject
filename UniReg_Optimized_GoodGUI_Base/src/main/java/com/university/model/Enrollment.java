package com.university.model;

import java.io.Serializable;
import java.time.LocalDate;

public class Enrollment implements Serializable {
    private static final long serialVersionUID = 1L;

    public enum Status { ENROLLED, DROPPED, WITHDRAWN, COMPLETED, WAITLISTED, INCOMPLETE }

    public enum Grade {
        A_PLUS, A, A_MINUS, B_PLUS, B, B_MINUS, C_PLUS, C, C_MINUS,
        D_PLUS, D, D_MINUS, F, INCOMPLETE, NOT_GRADED
    }

    private String enrollmentId;
    private String studentId;
    private String offeringId;
    private String courseId;
    private String courseName;
    private int credits;
    private String term = "TERM1";
    private int academicYear = 2026;
    private LocalDate enrollmentDate = LocalDate.now();
    private Status status = Status.ENROLLED;
    private Grade grade = Grade.NOT_GRADED;
    private double gradePoints;

    private double week7Lecture;
    private double week7Section;
    private double week12Lecture;
    private double week12Section;
    private double coursework;
    private double finalExam;
    private double totalGrade;
    private double maxGrade = 100.0;
    private double percentage;
    private int gradedComponents;
    private int totalComponents;

    public Enrollment() {}

    public Enrollment(String enrollmentId, String studentId, String courseId, String courseName, int credits) {
        this.enrollmentId = enrollmentId;
        this.studentId = studentId;
        this.courseId = courseId;
        this.courseName = courseName;
        this.credits = credits;
    }

    public Enrollment(String enrollmentId, String studentId, String offeringId,
                      String courseId, String courseName, int credits,
                      String term, int academicYear) {
        this(enrollmentId, studentId, courseId, courseName, credits);
        this.offeringId = offeringId;
        this.term = term;
        this.academicYear = academicYear;
    }

    public String getGradeDisplay() {
        if (grade == null || grade == Grade.NOT_GRADED) return "N/A";
        return switch (grade) {
            case A_PLUS -> "A+"; case A -> "A"; case A_MINUS -> "A-";
            case B_PLUS -> "B+"; case B -> "B"; case B_MINUS -> "B-";
            case C_PLUS -> "C+"; case C -> "C"; case C_MINUS -> "C-";
            case D_PLUS -> "D+"; case D -> "D"; case D_MINUS -> "D-";
            case F -> "F"; case INCOMPLETE -> "I"; default -> "N/A";
        };
    }

    public double getGradePoints() {
        if (gradePoints > 0 || grade == Grade.F) return gradePoints;
        return switch (grade == null ? Grade.NOT_GRADED : grade) {
            case A_PLUS, A -> 4.0; case A_MINUS -> 3.7;
            case B_PLUS -> 3.3; case B -> 3.0; case B_MINUS -> 2.7;
            case C_PLUS -> 2.3; case C -> 2.0; case C_MINUS -> 1.7;
            case D_PLUS -> 1.3; case D -> 1.0; case D_MINUS -> 0.7;
            case F -> 0.0; default -> 0.0;
        };
    }

    public boolean isActive() { return status == Status.ENROLLED || status == Status.WAITLISTED; }

    public boolean matchesCourseOrOffering(String id) {
        if (id == null) return false;
        return id.equalsIgnoreCase(offeringId == null ? "" : offeringId)
                || id.equalsIgnoreCase(courseId == null ? "" : courseId);
    }

    public String getDbStatus() {
        if (status == Status.DROPPED) return "WITHDRAWN";
        return status == null ? "ENROLLED" : status.name();
    }

    public static Status statusFromDb(String value) {
        if (value == null || value.isBlank()) return Status.ENROLLED;
        try { return Status.valueOf(value.toUpperCase()); }
        catch (IllegalArgumentException ex) { return Status.ENROLLED; }
    }

    public static Grade gradeFromLetter(String value) {
        if (value == null || value.isBlank()) return Grade.NOT_GRADED;
        return switch (value.trim().toUpperCase()) {
            case "A+" -> Grade.A_PLUS; case "A" -> Grade.A; case "A-" -> Grade.A_MINUS;
            case "B+" -> Grade.B_PLUS; case "B" -> Grade.B; case "B-" -> Grade.B_MINUS;
            case "C+" -> Grade.C_PLUS; case "C" -> Grade.C; case "C-" -> Grade.C_MINUS;
            case "D+" -> Grade.D_PLUS; case "D" -> Grade.D; case "D-" -> Grade.D_MINUS;
            case "F" -> Grade.F; case "I" -> Grade.INCOMPLETE; default -> Grade.NOT_GRADED;
        };
    }

    public static double targetTotalForGrade(Grade grade) {
        if (grade == null) return 0.0;
        return switch (grade) {
            case A_PLUS -> 98; case A -> 94; case A_MINUS -> 91;
            case B_PLUS -> 88; case B -> 84; case B_MINUS -> 81;
            case C_PLUS -> 78; case C -> 74; case C_MINUS -> 71;
            case D_PLUS -> 68; case D -> 64; case D_MINUS -> 61;
            case F -> 50; default -> 0;
        };
    }

    public void setGradeFromLetter(String letterGrade) { this.grade = gradeFromLetter(letterGrade); }

    public String getEnrollmentId() { return enrollmentId; }
    public void setEnrollmentId(String enrollmentId) { this.enrollmentId = enrollmentId; }
    public String getStudentId() { return studentId; }
    public void setStudentId(String studentId) { this.studentId = studentId; }
    public String getOfferingId() { return offeringId; }
    public void setOfferingId(String offeringId) { this.offeringId = offeringId; }
    public String getCourseId() { return courseId; }
    public void setCourseId(String courseId) { this.courseId = courseId; }
    public String getCourseName() { return courseName; }
    public void setCourseName(String courseName) { this.courseName = courseName; }
    public int getCredits() { return credits; }
    public void setCredits(int credits) { this.credits = credits; }
    public String getTerm() { return term; }
    public void setTerm(String term) { this.term = term; }
    public int getAcademicYear() { return academicYear; }
    public void setAcademicYear(int academicYear) { this.academicYear = academicYear; }
    public LocalDate getEnrollmentDate() { return enrollmentDate; }
    public void setEnrollmentDate(LocalDate enrollmentDate) { this.enrollmentDate = enrollmentDate; }
    public Status getStatus() { return status; }
    public void setStatus(Status status) { this.status = status; }
    public Grade getGrade() { return grade; }
    public void setGrade(Grade grade) { this.grade = grade; }
    public void setGradePoints(double gradePoints) { this.gradePoints = gradePoints; }
    public double getWeek7Lecture() { return week7Lecture; }
    public void setWeek7Lecture(double week7Lecture) { this.week7Lecture = week7Lecture; }
    public double getWeek7Section() { return week7Section; }
    public void setWeek7Section(double week7Section) { this.week7Section = week7Section; }
    public double getWeek12Lecture() { return week12Lecture; }
    public void setWeek12Lecture(double week12Lecture) { this.week12Lecture = week12Lecture; }
    public double getWeek12Section() { return week12Section; }
    public void setWeek12Section(double week12Section) { this.week12Section = week12Section; }
    public double getCoursework() { return coursework; }
    public void setCoursework(double coursework) { this.coursework = coursework; }
    public double getFinalExam() { return finalExam; }
    public void setFinalExam(double finalExam) { this.finalExam = finalExam; }
    public double getTotalGrade() { return totalGrade; }
    public void setTotalGrade(double totalGrade) { this.totalGrade = totalGrade; }
    public double getMaxGrade() { return maxGrade; }
    public void setMaxGrade(double maxGrade) { this.maxGrade = maxGrade; }
    public double getPercentage() { return percentage; }
    public void setPercentage(double percentage) { this.percentage = percentage; }
    public int getGradedComponents() { return gradedComponents; }
    public void setGradedComponents(int gradedComponents) { this.gradedComponents = gradedComponents; }
    public int getTotalComponents() { return totalComponents; }
    public void setTotalComponents(int totalComponents) { this.totalComponents = totalComponents; }
}
