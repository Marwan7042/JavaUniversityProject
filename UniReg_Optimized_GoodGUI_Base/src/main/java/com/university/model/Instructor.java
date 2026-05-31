package com.university.model;

import java.util.ArrayList;
import java.util.List;

public class Instructor extends Person {
    private static final long serialVersionUID = 1L;

    private String department;
    private String title;
    private List<String> courseIds = new ArrayList<>();
    private List<String> offeringIds = new ArrayList<>();

    public Instructor() {}

    public Instructor(String id, String firstName, String lastName, String email,
                      String password, String phone, String department, String title) {
        super(id, firstName, lastName, email, password, phone);
        this.department = department;
        this.title = title;
    }

    @Override public String getRole() { return "Instructor"; }

    @Override public String getSummary() {
        return String.format("%s %s | Department: %s | Offerings: %d", title, getFullName(), department, offeringIds.size());
    }

    public void addCourse(String courseId) { if (!courseIds.contains(courseId)) courseIds.add(courseId); }
    public void removeCourse(String courseId) { courseIds.remove(courseId); }
    public void addOffering(String offeringId) { if (!offeringIds.contains(offeringId)) offeringIds.add(offeringId); }
    public void removeOffering(String offeringId) { offeringIds.remove(offeringId); }

    public String getDepartment() { return department; }
    public void setDepartment(String department) { this.department = department; }
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public List<String> getCourseIds() { return courseIds; }
    public void setCourseIds(List<String> courseIds) { this.courseIds = courseIds == null ? new ArrayList<>() : courseIds; }
    public List<String> getOfferingIds() { return offeringIds; }
    public void setOfferingIds(List<String> offeringIds) { this.offeringIds = offeringIds == null ? new ArrayList<>() : offeringIds; }
}
