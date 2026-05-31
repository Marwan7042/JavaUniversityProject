package com.university.service;

import com.university.dao.DatabaseManager;
import com.university.exception.UniversityException;
import com.university.model.*;
import java.util.List;
import java.util.Map;

public class RegistrationService {
    private static final int MAX_ACTIVE_CREDITS = 18;
    private static RegistrationService instance;
    private final DatabaseManager db;

    private RegistrationService() { this.db = DatabaseManager.getInstance(); }

    public static synchronized RegistrationService getInstance() {
        if (instance == null) instance = new RegistrationService();
        return instance;
    }

    public List<Course> getAvailableCourses() {
        return db.getAllCourses().values().stream().filter(Course::hasAvailableSeats).toList();
    }

    public List<Student> getStudentsInCourse(String courseOrOfferingId) { return db.getStudentsInCourse(courseOrOfferingId); }

    public Enrollment enrollStudent(String studentId, String courseOrOfferingId) throws UniversityException {
        Student student = db.getStudent(studentId);
        if (student == null) throw new UniversityException("Student not found: " + studentId);
        Course course = db.getCourse(courseOrOfferingId);
        if (course == null) throw new UniversityException("Course/offering " + courseOrOfferingId + " not found.");
        String offeringId = course.getOfferingId();
        if (student.isEnrolledIn(offeringId) || student.isEnrolledIn(course.getCourseId())) throw new UniversityException("Student is already enrolled in " + course.getCourseId());
        if (!db.isAddPeriodOpen(offeringId)) throw new UniversityException("Registration is closed for " + course.getCourseId() + " (" + course.getTerm() + " " + course.getAcademicYear() + ").");
        if (!course.hasAvailableSeats()) throw new UniversityException("Course " + course.getCourseId() + " is full.");
        for (String prereqId : course.getPrerequisiteIds()) {
            boolean completed = student.getEnrollments().stream().anyMatch(e -> prereqId.equals(e.getCourseId()) && e.getStatus() == Enrollment.Status.COMPLETED);
            if (!completed) throw new UniversityException("Prerequisite not met for " + course.getCourseId() + ": " + prereqId);
        }
        if (db.hasStudentTimeConflict(studentId, offeringId)) throw new UniversityException("Time conflict: " + course.getCourseId() + " conflicts with another course in your schedule.");
        int activeCreditsAfterEnroll = db.getActiveCredits(studentId) + course.getCredits();
        if (activeCreditsAfterEnroll > MAX_ACTIVE_CREDITS) throw new UniversityException("Maximum active credit hours is " + MAX_ACTIVE_CREDITS + ". This registration would make your total " + activeCreditsAfterEnroll + ".");
        Enrollment enrollment = new Enrollment(db.generateEnrollmentId(), studentId, offeringId, course.getCourseId(), course.getCourseName(), course.getCredits(), course.getTerm(), course.getAcademicYear());
        try { db.insertEnrollment(enrollment); return enrollment; }
        catch (Exception ex) { throw new UniversityException("DB Error: " + ex.getMessage(), ex); }
    }

    public void dropCourse(String studentId, String courseOrOfferingId) throws UniversityException {
        Student student = db.getStudent(studentId);
        if (student == null) throw new UniversityException("Student not found: " + studentId);
        Enrollment enrollment = db.getEnrollmentForStudentAndCourse(studentId, courseOrOfferingId);
        if (enrollment == null || enrollment.getStatus() != Enrollment.Status.ENROLLED) throw new UniversityException("Student is not actively enrolled in this course.");
        if (!db.isDropPeriodOpen(enrollment.getOfferingId())) throw new UniversityException("Drop period is closed for " + enrollment.getCourseId() + ".");
        enrollment.setStatus(Enrollment.Status.WITHDRAWN);
        db.updateEnrollment(enrollment);
    }

    public void assignGrade(String studentId, String courseOrOfferingId, Enrollment.Grade grade) throws UniversityException {
        Enrollment enrollment = db.getEnrollmentForStudentAndCourse(studentId, courseOrOfferingId);
        if (enrollment == null) throw new UniversityException("Enrollment not found.");
        double total = Enrollment.targetTotalForGrade(grade);
        db.assignTotalGradeProportionally(enrollment.getEnrollmentId(), total);
    }

    public void setAssessmentScore(String enrollmentId, String componentCode, double score) throws UniversityException {
        Map<String, Double> maxMarks = db.getAssessmentMaxMarks();
        double max = maxMarks.getOrDefault(componentCode, 100.0);
        if (score < 0 || score > max) throw new UniversityException("Invalid score for " + componentCode + ". Allowed range: 0 - " + max);
        db.setAssessmentScore(enrollmentId, componentCode, score);
    }
}
