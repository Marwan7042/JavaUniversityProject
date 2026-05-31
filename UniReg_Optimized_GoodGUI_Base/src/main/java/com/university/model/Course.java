package com.university.model;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.List;

public class Course implements Serializable {
    private static final long serialVersionUID = 1L;

    public enum Status { OPEN, CLOSED, CANCELLED, COMPLETED }

    private String courseId;
    private String courseName;
    private String department;
    private int credits;
    private String description;

    private String offeringId;
    private String term = "TERM1";
    private int academicYear = 2026;
    private String sectionCode = "L01";
    private int capacity = 30;
    private int enrolled;
    private Status status = Status.OPEN;

    private String instructorId;
    private String instructorName;
    private String instructorRole = "LECTURE";
    private String schedule;
    private String room;
    private String dayOfWeek;
    private Integer slotId;
    private String meetingType = "LECTURE";
    private String roomType = "LECTURE";

    private List<String> prerequisiteIds = new ArrayList<>();
    private List<String> enrolledStudentIds = new ArrayList<>();

    public Course() {}

    public Course(String courseId, String courseName, String department, int credits,
                  int capacity, String instructorId, String instructorName,
                  String schedule, String room, String description) {
        this.courseId = courseId; this.courseName = courseName; this.department = department;
        this.credits = credits; this.capacity = capacity; this.instructorId = instructorId;
        this.instructorName = instructorName; this.schedule = schedule; this.room = room; this.description = description;
    }

    public Course(String offeringId, String courseId, String courseName, String department,
                  int credits, String term, int academicYear, String sectionCode,
                  int capacity, int enrolled, String instructorId, String instructorName,
                  String schedule, String room, String description, Status status) {
        this(courseId, courseName, department, credits, capacity, instructorId, instructorName, schedule, room, description);
        this.offeringId = offeringId; this.term = term; this.academicYear = academicYear;
        this.sectionCode = sectionCode; this.enrolled = enrolled; this.status = status == null ? Status.OPEN : status;
    }

    public boolean hasAvailableSeats() { return enrolled < capacity && status == Status.OPEN; }
    public int getAvailableSeats() { return Math.max(capacity - enrolled, 0); }

    public boolean enrollStudent(String studentId) {
        if (!hasAvailableSeats() || enrolledStudentIds.contains(studentId)) return false;
        enrolledStudentIds.add(studentId); enrolled++;
        if (enrolled >= capacity) status = Status.CLOSED;
        return true;
    }

    public boolean dropStudent(String studentId) {
        if (!enrolledStudentIds.contains(studentId)) return false;
        enrolledStudentIds.remove(studentId); enrolled = Math.max(enrolled - 1, 0);
        if (status == Status.CLOSED && enrolled < capacity) status = Status.OPEN;
        return true;
    }

    public String getDisplayCode() { return offeringId == null || offeringId.isBlank() ? courseId : courseId + " / " + offeringId; }

    public String getCourseId() { return courseId; }
    public void setCourseId(String courseId) { this.courseId = courseId; }
    public String getCourseName() { return courseName; }
    public void setCourseName(String courseName) { this.courseName = courseName; }
    public String getDepartment() { return department; }
    public void setDepartment(String department) { this.department = department; }
    public int getCredits() { return credits; }
    public void setCredits(int credits) { this.credits = credits; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public String getOfferingId() { return offeringId; }
    public void setOfferingId(String offeringId) { this.offeringId = offeringId; }
    public String getTerm() { return term; }
    public void setTerm(String term) { this.term = term; }
    public int getAcademicYear() { return academicYear; }
    public void setAcademicYear(int academicYear) { this.academicYear = academicYear; }
    public String getSectionCode() { return sectionCode; }
    public void setSectionCode(String sectionCode) { this.sectionCode = sectionCode; }
    public int getCapacity() { return capacity; }
    public void setCapacity(int capacity) { this.capacity = capacity; }
    public int getEnrolled() { return enrolled; }
    public void setEnrolled(int enrolled) { this.enrolled = enrolled; }
    public Status getStatus() { return status; }
    public void setStatus(Status status) { this.status = status; }
    public String getInstructorId() { return instructorId; }
    public void setInstructorId(String instructorId) { this.instructorId = instructorId; }
    public String getInstructorName() { return instructorName; }
    public void setInstructorName(String instructorName) { this.instructorName = instructorName; }
    public String getInstructorRole() { return instructorRole; }
    public void setInstructorRole(String instructorRole) { this.instructorRole = instructorRole; }
    public String getSchedule() { return schedule; }
    public void setSchedule(String schedule) { this.schedule = schedule; }
    public String getRoom() { return room; }
    public void setRoom(String room) { this.room = room; }
    public String getDayOfWeek() { return dayOfWeek; }
    public void setDayOfWeek(String dayOfWeek) { this.dayOfWeek = dayOfWeek; }
    public Integer getSlotId() { return slotId; }
    public void setSlotId(Integer slotId) { this.slotId = slotId; }
    public String getMeetingType() { return meetingType; }
    public void setMeetingType(String meetingType) { this.meetingType = meetingType; }
    public String getRoomType() { return roomType; }
    public void setRoomType(String roomType) { this.roomType = roomType; }
    public List<String> getPrerequisiteIds() { return prerequisiteIds; }
    public void setPrerequisiteIds(List<String> prerequisiteIds) { this.prerequisiteIds = prerequisiteIds == null ? new ArrayList<>() : prerequisiteIds; }
    public List<String> getEnrolledStudentIds() { return enrolledStudentIds; }
    public void setEnrolledStudentIds(List<String> enrolledStudentIds) { this.enrolledStudentIds = enrolledStudentIds == null ? new ArrayList<>() : enrolledStudentIds; }
}
