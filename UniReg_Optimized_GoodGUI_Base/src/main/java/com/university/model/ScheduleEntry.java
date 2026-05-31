package com.university.model;

public class ScheduleEntry {
    private String studentId;
    private String enrollmentId;
    private String offeringId;
    private String courseId;
    private String courseName;
    private int credits;
    private String term;
    private int academicYear;
    private String sectionCode;
    private String dayOfWeek;
    private int slotId;
    private String meetingType;
    private String startTime;
    private String endTime;
    private String roomId;
    private String roomType;
    private String instructorIds;
    private String instructorNames;
    private String enrollmentStatus;

    public String getTimeRange() { return (startTime == null ? "" : startTime) + " - " + (endTime == null ? "" : endTime); }

    public String getStudentId() { return studentId; }
    public void setStudentId(String studentId) { this.studentId = studentId; }
    public String getEnrollmentId() { return enrollmentId; }
    public void setEnrollmentId(String enrollmentId) { this.enrollmentId = enrollmentId; }
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
    public String getSectionCode() { return sectionCode; }
    public void setSectionCode(String sectionCode) { this.sectionCode = sectionCode; }
    public String getDayOfWeek() { return dayOfWeek; }
    public void setDayOfWeek(String dayOfWeek) { this.dayOfWeek = dayOfWeek; }
    public int getSlotId() { return slotId; }
    public void setSlotId(int slotId) { this.slotId = slotId; }
    public String getMeetingType() { return meetingType; }
    public void setMeetingType(String meetingType) { this.meetingType = meetingType; }
    public String getStartTime() { return startTime; }
    public void setStartTime(String startTime) { this.startTime = startTime; }
    public String getEndTime() { return endTime; }
    public void setEndTime(String endTime) { this.endTime = endTime; }
    public String getRoomId() { return roomId; }
    public void setRoomId(String roomId) { this.roomId = roomId; }
    public String getRoomType() { return roomType; }
    public void setRoomType(String roomType) { this.roomType = roomType; }
    public String getInstructorIds() { return instructorIds; }
    public void setInstructorIds(String instructorIds) { this.instructorIds = instructorIds; }
    public String getInstructorNames() { return instructorNames; }
    public void setInstructorNames(String instructorNames) { this.instructorNames = instructorNames; }
    public String getEnrollmentStatus() { return enrollmentStatus; }
    public void setEnrollmentStatus(String enrollmentStatus) { this.enrollmentStatus = enrollmentStatus; }
}
