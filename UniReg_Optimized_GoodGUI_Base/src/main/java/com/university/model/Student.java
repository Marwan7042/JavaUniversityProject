package com.university.model;

import java.util.ArrayList;
import java.util.List;

public class Student extends Person {
    private static final long serialVersionUID = 1L;

    private String major;
    private int year;
    private double gpa;
    private List<Enrollment> enrollments = new ArrayList<>();

    public Student() {}

    public Student(String id, String firstName, String lastName, String email,
                   String password, String phone, String major, int year) {
        super(id, firstName, lastName, email, password, phone);
        this.major = major;
        this.year = year;
    }

    @Override public String getRole() { return "Student"; }

    @Override public String getSummary() {
        return String.format("Student %s | Major: %s | Year: %s | GPA: %.2f", getFullName(), major, getYearLabel(), gpa);
    }

    public String getYearLabel() {
        return switch (year) {
            case 1 -> "Freshman"; case 2 -> "Sophomore"; case 3 -> "Junior"; case 4 -> "Senior";
            case 5 -> "Fifth Year"; case 6 -> "Sixth Year"; case 7 -> "Seventh Year";
            default -> "Unknown";
        };
    }

    public boolean isEnrolledIn(String courseOrOfferingId) {
        return enrollments.stream().anyMatch(e -> e.matchesCourseOrOffering(courseOrOfferingId) && e.isActive());
    }

    public int getTotalCredits() {
        return enrollments.stream().filter(e -> e.getStatus() == Enrollment.Status.COMPLETED).mapToInt(Enrollment::getCredits).sum();
    }

    public int getActiveCredits() {
        return enrollments.stream().filter(e -> e.getStatus() == Enrollment.Status.ENROLLED).mapToInt(Enrollment::getCredits).sum();
    }

    public String getMajor() { return major; }
    public void setMajor(String major) { this.major = major; }
    public int getYear() { return year; }
    public void setYear(int year) { this.year = year; }
    public double getGpa() { return gpa; }
    public void setGpa(double gpa) { this.gpa = gpa; }
    public List<Enrollment> getEnrollments() { return enrollments; }
    public void setEnrollments(List<Enrollment> enrollments) { this.enrollments = enrollments == null ? new ArrayList<>() : enrollments; }
    public void addEnrollment(Enrollment enrollment) { this.enrollments.add(enrollment); }
}
